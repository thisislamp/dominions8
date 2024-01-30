extends Control
#var battlefield1 = preload("res://scenes/battlefield1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			enter_battle()

func _on_button_pressed():
	enter_battle()

func enter_battle():
	get_tree().change_scene_to_file("res://scenes/battlefield1.tscn")

