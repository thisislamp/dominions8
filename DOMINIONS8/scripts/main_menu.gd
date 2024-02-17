extends Control
#var battlefield1 = preload("res://scenes/battlefield1.tscn")

var _mp_menu


func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			enter_battle()

func _on_button_pressed():
	enter_battle()

func enter_battle():
	get_tree().change_scene_to_file("res://scenes/battlefield1.tscn")



func _on_multiplayer_button_pressed() -> void:
	if Utils.is_alive(_mp_menu):
		return

	#var mpm = preload("res://ui/multiplayer_menu.tscn").instantiate()
	#add_child(mpm)

	_mp_menu = InternalWindow.from_scene(preload("res://ui/multiplayer_menu.tscn"))
	get_node("/root").add_child(_mp_menu)
