class_name InternalWindow extends Control


## The window title.  Will be set in _ready().
@export var title: String = "Window"

## If true, keeps the window within the bounds of the viewport.
@export var keep_in_viewport: bool = false

## Sets if the minimize button is available.
@export var can_minimize: bool = true

## Sets if the maximize/reduce buttons are available.
@export var can_maximize: bool = true

## Sets if the close button is available.
@export var can_close: bool = true

## If set, reparent this node into the internal window content area.
## This is a convenience function for building in the editor.
@export var window_content_node: Control

## If the window is maximized
var maximized: bool:
	get: return _maximized

## The size of the window.
var window_size: Vector2:
	get: return %WindowContainer.size

## The title bar text.
var window_title: String:
	get: return %window_title.text
	set(v): set_title(v)

## The Control node assigned as the window content.
var window_content: Control:
	get: return %WindowContent.get_child(0)
	#set(v): set_window_content(v)

var viewport_size: Vector2:
	get: return get_viewport_rect().size

var _edge_margin: int = 8
var _corner_cutoff: int = 16
var _is_dragging_window: bool = false
var _drag_point: Vector2
var _maximized: bool = false
var _windowed_size: Vector2
var _windowed_position: Vector2
var _is_resizing_window: bool = false
var _resizing_flags: int = 0
var _top_bound: float
var _left_bound: float
#var _right_bound: float
#var _bottom_bound: float

enum ResizeFlags {NONE = 0, TOP = 1, BOTTOM = 2, LEFT = 4, RIGHT = 8}

@onready var window_container = %WindowContainer as PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_title(title)
	%button_reduce.visible = false
	if window_content_node:
		window_content_node.reparent(%WindowContent, false)


## Closes the window.  By default, sets it to not visible and calls queue_free().
func close_window() -> void:
	visible = false
	queue_free()

## Maximizes the window.  Sets the window to expand to the entire screen.
func maximize_window() -> void:
	_windowed_position = global_position
	_windowed_size = %WindowContainer.size

	global_position = Vector2.ZERO
	%WindowContainer.set_size(get_viewport_rect().size)
	_maximized = true
	%button_maximize.visible = false
	%button_reduce.visible = true
	%WindowContainer.mouse_default_cursor_shape = Control.CURSOR_ARROW
	_resizing_flags = ResizeFlags.NONE

	# resize the window when the viewport gets resized?

## Reduces (un-maximizes) the window.  Returns it to its previous size and position.
func reduce_window() -> void:
	global_position = _windowed_position
	var pc := %WindowContainer as PanelContainer
	pc.set_size(_windowed_size)
	_maximized = false
	%button_maximize.visible = true
	%button_reduce.visible = false

## Minimizes the window.  Hides the window content and shrinks it as much as possible.
func minimize_window() -> void:
	%WindowContent.visible = not %WindowContent.visible
	%WindowContainer.reset_size()

## Sets the text in the window title bar.
func set_title(text: String) -> void:
	%window_title.text = text

## Sets the contents of the window content area.
func set_window_content(content: Control) -> void:
	%WindowConent.add_child(content, true)

## Removes the internal window node from its parent in the tree and returns it.
func detach() -> InternalWindow:
	get_parent().remove_child(self)
	return self

## Removes the window content control node and returns it, or null if there is none.
func detach_content() -> Control:
	if window_content.get_children().is_empty():
		return null
	var content = window_content.get_child(0)
	window_content.remove_child(content)
	return content


func _on_title_bar_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_titlebar_click(event)
	elif event is InputEventMouseMotion:
		_handle_titlebar_move(event)

func _handle_titlebar_click(event: InputEventMouseButton) -> void:
	if _resizing_flags:
		return

	match event.button_index:
		MOUSE_BUTTON_LEFT when event.double_click:
			if _maximized:
				reduce_window()
			else:
				maximize_window()

		MOUSE_BUTTON_LEFT:
			_is_dragging_window = event.is_pressed()
			_drag_point = get_local_mouse_position()
		_:
			return

	get_viewport().set_input_as_handled()

func _handle_titlebar_move(event: InputEventMouseMotion) -> void:
	if _is_dragging_window:
		if _maximized:
			# Set the drag point relative to the reduced window size
			var max_width = get_viewport_rect().size.x
			reduce_window()
			_drag_point.x *= %WindowContainer.size.x / max_width

		global_position = event.global_position - _drag_point
		if keep_in_viewport:
			global_position = global_position.clamp(Vector2.ZERO, get_viewport_rect().size - %"TitleBarPanel".size)

		get_viewport().set_input_as_handled()

func _on_window_container_gui_input(event: InputEvent) -> void:
	if _maximized:
		return
	if event is InputEventMouseButton:
		_handle_window_container_click(event)
	elif event is InputEventMouseMotion:
		if _is_resizing_window:
			_handle_window_container_resize(event)
		else:
			_handle_window_container_mouseover(event)

func _handle_window_container_click(event: InputEventMouseButton) -> void:
	if not _resizing_flags:
		return
	_is_resizing_window = event.pressed

	var min_size := window_container.get_combined_minimum_size()
	_left_bound = global_position.x + window_container.size.x - min_size.x
	_top_bound = global_position.y + window_container.size.y - min_size.y
	#_right_bound = global_position.x + min_size.x
	#_bottom_bound = global_position.y + min_size.y

func _handle_window_container_resize(event: InputEventMouseMotion) -> void:
	var min_size := window_container.get_combined_minimum_size()

	match _resizing_flags:
		ResizeFlags.TOP | ResizeFlags.LEFT:
			# top part
			var before = global_position.y
			global_position.y = clamp(event.global_position.y, 0, _top_bound)
			window_container.size.y -= global_position.y - before
			# left part
			before = global_position.x
			global_position.x = clamp(event.global_position.x, 0, _left_bound)
			window_container.size.x -= global_position.x - before

		ResizeFlags.TOP | ResizeFlags.RIGHT:
			# top part
			var before = global_position.y
			global_position.y = clamp(event.global_position.y, 0, _top_bound)
			window_container.size.y -= global_position.y - before
			# right part
			window_container.size.x = clamp(
				event.global_position.x - global_position.x, min_size.x, viewport_size.x - global_position.x
			)

		ResizeFlags.BOTTOM | ResizeFlags.LEFT:
			# bottom part
			window_container.size.y = clamp(
				event.global_position.y - global_position.y, min_size.y, viewport_size.y - global_position.y
			)
			# left part
			var before = global_position.x
			global_position.x = clamp(event.global_position.x, 0, _left_bound)
			window_container.size.x -= global_position.x - before

		ResizeFlags.BOTTOM | ResizeFlags.RIGHT:
			# bottom part
			window_container.size.y = clamp(
				event.global_position.y - global_position.y, min_size.y, viewport_size.y - global_position.y
			)
			# right part
			window_container.size.x = clamp(
				event.global_position.x - global_position.x, min_size.x, viewport_size.x - global_position.x
			)

		ResizeFlags.TOP:
			var before = global_position.y
			global_position.y = clamp(event.global_position.y, 0, _top_bound)
			window_container.size.y -= global_position.y - before

		ResizeFlags.LEFT:
			var before = global_position.x
			global_position.x = clamp(event.global_position.x, 0, _left_bound)
			window_container.size.x -= global_position.x - before

		ResizeFlags.RIGHT:
			window_container.size.x = clamp(
				event.global_position.x - global_position.x, min_size.x, viewport_size.x - global_position.x
			)

		ResizeFlags.BOTTOM:
			window_container.size.y = clamp(
				event.global_position.y - global_position.y, min_size.y, viewport_size.y - global_position.y
			)

		ResizeFlags.NONE:
			_top_bound = 0
			_left_bound = 0
			#_right_bound = 0
			#_bottom_bound = 0

func _handle_window_container_mouseover(event: InputEventMouseMotion) -> void:
	var pos = event.position
	var in_h_range := \
		_in_rangef(pos.x, -_edge_margin, _edge_margin) or \
		_in_rangef(pos.x, -_edge_margin + window_size.x, _edge_margin + window_size.x)
	var in_v_range := \
		_in_rangef(pos.y, -_edge_margin, _edge_margin) or \
		_in_rangef(pos.y, -_edge_margin + window_size.y, _edge_margin + window_size.y)

	# At a corner
	if in_h_range and in_v_range:
		# Top left corner
		if pos.x < _corner_cutoff and pos.y < _corner_cutoff:
			%WindowContainer.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
			_resizing_flags = ResizeFlags.TOP | ResizeFlags.LEFT

		# Bottom left corner
		elif pos.x < _corner_cutoff and pos.y > _corner_cutoff:
			%WindowContainer.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
			_resizing_flags = ResizeFlags.BOTTOM | ResizeFlags.LEFT

		# Top right corner
		elif pos.x > _corner_cutoff and pos.y < _corner_cutoff:
			%WindowContainer.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
			_resizing_flags = ResizeFlags.TOP | ResizeFlags.RIGHT

		# Bottom right corner
		elif pos.x > _corner_cutoff and pos.y > _corner_cutoff:
			%WindowContainer.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
			_resizing_flags = ResizeFlags.BOTTOM | ResizeFlags.RIGHT

	# At an edge
	elif in_h_range:
		%WindowContainer.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		_resizing_flags = ResizeFlags.LEFT if pos.x <= _edge_margin else ResizeFlags.RIGHT
	elif in_v_range:
		%WindowContainer.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		_resizing_flags = ResizeFlags.TOP if pos.y <= _edge_margin else ResizeFlags.BOTTOM
	else:
		%WindowContainer.mouse_default_cursor_shape = Control.CURSOR_ARROW
		_resizing_flags = ResizeFlags.NONE

func _on_window_container_mouse_exited() -> void:
	pass # Replace with function body.

func _in_rangef(value: float, min: float, max: float) -> bool:
	return min <= value and value <= max

func _on_button_close_pressed() -> void:
	close_window()

func _on_button_maximize_pressed() -> void:
	maximize_window()

func _on_button_reduce_pressed() -> void:
	reduce_window()

func _on_button_minimize_pressed() -> void:
	minimize_window()

