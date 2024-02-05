class_name GDsh extends RefCounted

var node: Node

var _expression := Expression.new()

func _init(initial_node=null) -> void:
	if initial_node == null:
		node = Console
	else:
		node = initial_node as Node

func is_command(text: String) -> bool:
	return text.length() >= 2 and text[0] == ":"

## Evaulates a line of code
func eval(text: String) -> Array:
	var err = _expression.parse(text)
	if err != OK:
		return [err, _expression.get_error_text()]

	var result = _expression.execute([], node)
	if _expression.has_execute_failed():
		return [FAILED, _expression.get_error_text()]

	return [OK, result]

## Parses and runs a command or code.  Returns an errorlist of [Error, [result]]
func run(text: String) -> Array:
	print("gdsh: running text '%s'" % text)
	# Run code
	if not is_command(text):
		return eval(text)

	# Run a command
	var parse_result := parse_command(text)
	print("gdsh: handling parse result: %s" % parse_result)
	match parse_result:
		[OK, [var command, var args]]:
			print("gdsh: running command '%s' %s" % [command, args])
			return run_command(command, args)
		[FAILED, _]:
			return parse_result
		_:
			return [FAILED, ["unknown error"]]

func parse_command(text: String) -> Array:
	var command := text.get_slice(" ", 0).substr(1)
	var parse_result := parse_args(text.substr(command.length() + 1))
	var args: Array[String] = []

	match parse_result:
		[OK, var _args]:
			args = _args
		[FAILED, var err]:
			print("gdsh: Error parsing args: ", err)
			return parse_result

	print("gdsh: Parsed command: ", command)
	print("gdsh: Parsed args: ", args)

	return [OK, [command, args]]

func parse_args(argstr: String) -> Array[String]:
	argstr = argstr.strip_edges()

	var args: Array[String] = []
	var view := Utils.StringView.new(argstr)

	while true:
		if view.is_quote():
			args.append(view.get_quoted_word())
		else:
			args.append(view.get_word())

		if view.eof:
			return args

		if view.is_ws():
			if not view.skip_ws() or view.eof:
				return args

	return args

func run_command(command: String, args) -> Array:
	var err = OK
	var result = null

	match command:
		"cd":
			result = "<NYI>"
		"ls":
			result = "<NYI>"
		"mv":
			result = "<NYI>"
		"rm":
			result = "<NYI>"
		"mknode":
			result = "<NYI>"
		"i":
			result = "<NYI>"
		"help":
			result = "<NYI>"
		_:
			err = FAILED
			result = "Unknown command '%s'" % command

	return [err, result]
