class_name Utils extends Object

static func try_get_node(name: String, from: Node):
	var maybe_node = from.get_node_or_null(name)
	if maybe_node:
		return maybe_node

	match name:
		"/": return from.get_tree().root
		"/root": return from.get_tree().root
		_:
			name = "/root/" + name.lstrip("/")

## current_v: current velocity, aka self.velocity
## target_v: target velocity, ...?
## max_speed:
## accel: acceleration in px/sec
## delta: physics delta
## returns: new velocity
static func smooth_move(current_v: Vector2, target_v: Vector2, max_speed: float, accel: float, delta: float):
	var speed = current_v.length()
	var new_speed = min(speed + accel * delta, max_speed)
	# velocity = velocity.normalized() * speed


static func accelerate(velocity: Vector2, accel: float, delta: float) -> Vector2:
	return velocity.normalized() * (velocity.length() + accel * delta)

static func accelerate_to(velocity: Vector2, accel: float, delta: float, target_speed: float = INF) -> Vector2:
	var speed = velocity.length()
	if target_speed < speed:
		accel = -accel
	return velocity.normalized() * clampf(velocity.length() + accel * delta, 0, target_speed)

static func apply_thrust(velocity: Vector2, direction: Vector2, force: float, delta: float) -> Vector2:
	var thrust = direction.normalized() * force * delta
	return velocity + thrust


class StringHistory extends RefCounted:
	## The list of history items, oldest items first.
	var history: PackedStringArray = []

	## The position of the cursor in the history, 0 being the latest item.
	var cursor: int = 0:
		set(v):
			cursor = clampi(v, 0, history.size())

	func _invert(i: int) -> int:
		return -1 - i

	## Clears the history and cursor.
	func clear() -> void:
		history.clear()
		cursor = 0

	## Returns the history item at the cursor or specified index.  Unsafe.
	func get_entry(index: int = -1) -> String:
		if index == -1:
			index = cursor
		return history[_invert(index)]

	## Returns the history item at the cursor or specified index, or null if
	## the index is out of bounds.
	func get_entry_or_null(index: int = -1):
		if index < -1 or index > history.size():
			return null
		return get_entry(index)

	## Scrolls the history cursor up one and returns the item.
	func scroll_up():
		cursor = min(history.size(), cursor + 1)
		return get_entry()

	## Scrolls the history cursor down one and returns the item.
	func scroll_down():
		cursor = max(0, cursor - 1)
		return get_entry()

	## Scrolls to the last item and returns it.
	func scroll_to_bottom():
		cursor = 0
		return get_entry()

	## Scrolls to the first item and returns it.
	func scroll_to_top():
		cursor = history.size()

	## Adds an entry to the history, optionally allowing for duplicate entries
	## and specifying a specific position.
	func add_entry(text: String, allow_dupe := false, position := 0):
		if not allow_dupe and get_entry_or_null(_invert(position)) == text:
			return
		history.insert(_invert(position), text)

	## Appends an entry to the history.
	func append_entry(text: String, allow_dupe := false, scroll := true):
		add_entry(text, allow_dupe)
		if scroll:
			scroll_to_bottom()


# Ported from Rapptz's StringView
# https://github.com/Rapptz/discord.py/blob/master/discord/ext/commands/view.py
# Licence: MIT
class StringView extends RefCounted:
	#static var _quotes := {
		#"\"": "\""
	#}
	static var _all_quotes := ["\""]

	var index: int = 0
	var buffer: String = ""
	var end: int = 0
	var previous: int = 0

	var current:
		get:
			@warning_ignore("incompatible_ternary")
			return null if eof else buffer[index]

	var eof: bool:
		get:
			return index >= end

	func _init(string: String) -> void:
		buffer = string
		end = string.length()

	func _error(message: String, error: int = FAILED) -> Array:
		push_error(message)
		return [error, message]

	func _ok(result: Array[String]) -> Array:
		return [OK, "".join(PackedStringArray(result))]

	func is_quote() -> bool:
		return current in _all_quotes

	func is_ws() -> bool:
		return current == " "

	func undo() -> void:
		index = previous

	func skip_ws() -> bool:
		var pos := 0
		var idx := index + pos
		var current_char := ""

		while not eof:
			if idx > buffer.length():
				break

			current_char = buffer[idx]
			if current_char != " ":  #
				break

			pos += 1
			idx += 1

		previous = index
		index += pos
		return previous != index

	func skip_string(string: String) -> bool:
		var strlen := string.length()
		if buffer.substr(index, index + strlen) == string:
			previous = index
			index += strlen
			return true
		return false

	func read_rest() -> String:
		var result := buffer.substr(index)
		previous = index
		index = end
		return result

	func read(n: int) -> String:
		var result := buffer.substr(index, index + n)
		previous = index
		index += n
		return result

	func get1():
		var result
		if index + 1 > buffer.length():
			result = null
		else:
			result = buffer[index+1]

		previous = index
		index += 1
		return result

	func get_word() -> String:
		var pos := 0
		var idx := index + pos
		var current_char := ""

		while not eof:
			if idx > buffer.length():
				break

			current_char = buffer[idx]
			if current_char == " ":
				break

			pos += 1
			idx += 1

		previous = index
		var result := buffer.substr(index, idx)
		index += pos
		return result

	## Returns an errorlist of [Error, word:String]
	func get_quoted_word() -> Array:
		if current == null:
			return [FAILED, null]

		var _current := current as String
		var _escaped_quotes: Array[String] = []
		var close_quote := "\""
		var is_quoted := true  # hack, other quotes not implemented
		var result: Array[String] = []

		if is_quoted:
			_escaped_quotes = [_current, close_quote]
		else:
			result = [_current]
			_escaped_quotes = _all_quotes

		while not eof:
			_current = get1()
			if not _current:
				if is_quoted:
					return _error("Unexpected EOF")

				return _ok(result)

			# Handle escaped quotes
			if _current == "\\":
				var next_char = get1()
				if not next_char:
					if is_quoted:
						return _error("Expected closing quote")

					return _ok(result)

				if next_char in _escaped_quotes:
					result.append(next_char)
				else:
					undo()
					result.append(_current)
				continue

			if not is_quoted and _current in _all_quotes:
				return _error("Unexpected quote")

			# Handle closing quote
			if is_quoted  and _current == close_quote:
				var next_char = get1()
				var valid_eof: bool = not next_char or next_char == " "
				if not valid_eof:
					return _error("Invalid end of quoted string")

				return _ok(result)

			if _current == " " and not is_quoted:
				return _ok(result)

			result.append(_current)

		return _error("Error")
