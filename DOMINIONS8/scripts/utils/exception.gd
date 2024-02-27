class_name Exception extends RefCounted

var message: String = ""
var errno: int = -1

func _init(_message: String = "", _errno: int = 0) -> void:
	message = _message
	if _errno:
		errno = _errno

func _to_string() -> String:
	if errno:
		return "<Exception %s: %s>" % [errno, message]
	else:
		return "<Exception: %s>" % message


func raise() -> Exception:
	if OS.is_debug_build():
		assert(false, "Error %s: %s" % [errno, message])
	else:
		push_error("Error ", errno, ": ", message)
	return self

func print() -> void:
	print_debug("Error ", errno, ": ", message)
