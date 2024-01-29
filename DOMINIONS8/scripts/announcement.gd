extends Label


func _on_button_pressed():
	#get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_nexus_death(color: String):
	#declare_winner.call_deferred()
	declare_winner(color)

func declare_winner(color: String):
	text = "%s TEAM WINS" % color.to_upper()
	visible = true
	#get_tree().paused = true
