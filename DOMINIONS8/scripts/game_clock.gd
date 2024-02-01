extends Label

var game_time: float = 0

# To make a timer you only actually have to store one thing, time in seconds.
# There's always 60 seconds in a minute so you can just derive it with simple
# division.  The remainder/modulo operator (%) is something you actually learned
# in fourth grade, along with long division.  For example, 80 seconds is 1 minute
# 20 seconds, and you can get that by removing 60 N times, in this case N=1.
# 80 % 60 = 20, 140 % 60 = 20, etc.  No need to track the same value multiple times.

func format_time() -> String:
	var seconds := int(game_time) % 60
	var minutes := int(game_time / 60.0) % 60
	# The format string works like this:
	#   % = format escape code
	#   0 = character to pad with
	#   2 = how many characters to pad
	#   d = format of the argument (d for decimal, but s for string would work too)
	# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
	return "%02d:%02d" % [minutes, seconds]

func _process(delta: float):
	game_time += delta
	text = format_time()
