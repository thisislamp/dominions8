class_name GameConsole extends PanelContainer

@onready var output_area: RichTextLabel = $margin/vbox/margin/output_area
@onready var input_bar: LineEdit = $margin/vbox/input_bar

var pad_width: int = 10

var tree: SceneTree:
	get: return get_tree()

var history: Array[String] = []
var history_index: int = 0
static var help_text: Dictionary = {}

@onready var gdsh := GDsh.new()

func _ready() -> void:
	visible = false

func toggle_console() -> void:
	visible = not visible

func log(text: String, time: bool = true, prefix: String = "", stdout: bool = true) -> void:
	call_thread_safe("print_console", text, time, prefix, stdout)

func print_console(text: String, time: bool = true, prefix: String = "", stdout: bool = true) -> void:
	if not is_node_ready():
		return

	var output = ""
	if time:
		output += format_time() + " "

	output += prefix

	if "\n" in text:
		var lines := text.split("\n", true)
		print_console(lines[0])
		lines.remove_at(0)

		for line in lines:
			print_console(line, false, ".".repeat(pad_width+2) + " ")
	else:
		output += text
		output_area.append_text("\n" + output)
		if stdout:
			print(output)

func format_time() -> String:
	var ticktime = "%0.3f" % (Time.get_ticks_msec()/1_000.0)
	return "[" + ticktime.lpad(pad_width) + "]"

func _on_input_bar_text_submitted(text: String) -> void:
	if text == "":
		return

	if history.is_empty() or history.front() != text:
		history.append(text)
		history_index = 0

	output_area.scroll_to_line(output_area.get_line_count()-1)
	process_command(text)
	input_bar.clear()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_console", false, true):
		toggle_console()
		get_viewport().set_input_as_handled()

	elif event is InputEventKey:
		if not event.pressed or not visible:
			return
		match event.keycode:
			KEY_UP:
				var hsize := history.size()
				if history_index > hsize or hsize == 0:
					return
				set_history_item(history[-history_index-1])
				history_index = min(hsize - 1, history_index + 1)
				accept_event()

			KEY_DOWN:
				if history_index < 0:
					history_index = 0
					return
				set_history_item(history[-history_index-1])
				history_index = max(0, history_index - 1)
				accept_event()

			KEY_C when event.ctrl_pressed and input_bar.get_selected_text() == "":
				input_bar.clear()
				accept_event()

			KEY_SPACE when event.ctrl_pressed and input_bar.has_focus():
				var menu: PopupMenu = input_bar.get_menu()
				menu.visible = true
				menu.position = input_bar.position + Vector2(10, 52)
				accept_event()

#func _unhandled_key_input(event: InputEvent) -> void:
	#if visible:
		#accept_event()

func _on_visibility_changed() -> void:
	if visible and is_node_ready():
		#print("Grabbing input bar focus")
		input_bar.grab_focus.call_deferred()

func set_history_item(text: String) -> void:
	input_bar.text = text
	input_bar.caret_column = input_bar.text.length()
	#input_bar.set_caret_column.call_deferred(input_bar.text.length())
	#input_bar.select_all()

func process_command(text: String) -> void:
	var command := Command.from_text(text)
	if command.cmd == "":
		# TODO: make this better
		print_console("Bad input")
		return

	var func_name := "handle_%s" % command.cmd

	# TODO: switch to Logger (when I write it)
	print("##### Parsed '%s' %s" % [command.cmd, command.args])

	if func_name in self:
		print_console("$ " + text)
		print("Calling handle_%s(%s)" % [command.cmd, command.args])

		# TODO: parse args properly with get_method_list() data

		var result = callv(func_name, command.args)
		match result:
			true:
				print("Call successful")
			null:
				print("Call failed, returned %s" % result)
			[true, var _result]:
				print("Call returned (%s)%s" % [type_string(typeof(result)), result])
			[false, var err]:
				print_console("Error: " + err)
			_:
				print("Call returned (%s)%s" % [type_string(typeof(result)), result])

		print("----------------------")
	else:
		print_console("No command '%s'" % command.cmd)

func _get_call_handler(name: String):
	if "handle_%s" % name in self:
		pass

func _get_callc_handler(name: String):
	var cbname := "handle_%s" % name
	if cbname in self:
		return Callable(self, name)

func _get_callv_handler(name: String):
	var cbname := "handlev_%s" % name
	if cbname in self:
		return Callable(self, name)



func handle_help(command: String = ""):
	# TODO: parse help dict
	print_console("Nothing but us birds")
	return true

func handle_clear():
	output_area.clear()
	return true

func handle_reset():
	handle_clear()
	history.clear()
	history_index = 0
	return true

func handle_quit():
	tree.quit()
	return true

func handle_gdsh(expr: String):
	print("Console: running gdsh with '%s'" % expr)
	var result := gdsh.run(expr)
	print("Console: got gdsh result: %s" % result)
	match result:
		[OK, var output]:
			print_console(str(output))
		[_, var err]:
			print_console("Error: " + err as String)
	return true

func handle_eval(basenode, expression=null):
	if expression == null:
		expression = basenode
		basenode = ""

	var expr = Expression.new()
	expr.parse(expression)
	var expr_result = expr.execute([], get_node("/root/" + basenode))
	if expr.has_execute_failed():
		return [false, expr.get_error_text()]
	else:
		print_console("= %s" % [expr_result])
		return true

func handle_tree(root=null):
	var node = self
	if root != null:
		node = Utils.try_get_node(root as String, self)
		if node == null:
			return [false, "No node '[/root/]%s'" % root]

	print_console("= " + node.get_tree_string_pretty().strip_edges(false))
	return false

func handle_reload():
	tree.reload_current_scene()
	return true

func handle_changescene(path: String):
	var respath := "res://%s.tscn" % path
	if ResourceLoader.exists(respath):
		tree.change_scene_to_file(respath)
		return true
	else:
		return [false, "File not found"]

# TODO:
# - better callv parser
#   - parse quoted arguments
#   - count and pass args properly and error
# - better eval
#   - better regex (no . form, etc)
#   - parsing node syntax: ::$root
#   - shorthand node syntax: $node/$1/$2/node

class Command extends RefCounted:
	var cmd: String
	var args: PackedStringArray
	static var _eval_simple_regex := RegEx.create_from_string(r"^:(.*)")
	static var _eval_regex := RegEx.create_from_string(r"^::([a-zA-Z0-9_\-/]+)(?:\.(.*))?")

	static func from_text(text: String) -> Command:
		var command := Command.new()
		var parsed := parse(text)
		command.cmd = parsed[0]
		command.args = parsed[1]
		return command

	static func parse(text: String) -> Array:
		if text.begins_with(":"):
			return ["gdsh", [text.substr(1)]]
			#return parse_eval(text)

		var _cmd := text.split(" ", false, 1)[0]
		var _args := text.substr(len(_cmd)).strip_edges().split(" ", false)
		return [_cmd, _args]

	static func parse_eval(text: String) -> Array:
		print("Parsing simple")
		var pex := _eval_simple_regex.search(text)
		print(pex.strings)
		print(pex.get_group_count())
		if not pex:
			print("Parsing comples")
			pex = _eval_regex.search(text)
		if not pex:
			return [false, "No match"]

		print("Parsed %s " % pex.strings)
		return ["eval", PackedStringArray(pex.strings.slice(1))]
