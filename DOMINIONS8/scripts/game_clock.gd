extends Label
var game_timer: float = 0
var seconds_counter: int = 0
var minutes_counter: int = 0

func _ready():
	text = str(minutes_counter, ":", seconds_counter)

func _process(delta):
	game_timer += delta
	if game_timer >= 1:
		seconds_counter += 1
		if seconds_counter >= 60:
			minutes_counter += 1
			seconds_counter -= 60
		if seconds_counter < 10:
			text = str(minutes_counter, ":0", seconds_counter)
		elif seconds_counter >= 10:
			text = str(minutes_counter, ":", seconds_counter)
		game_timer -= 1
	pass
	
