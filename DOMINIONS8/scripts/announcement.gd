extends Label
@onready var blue_nexus = $"../blue_nexus"
@onready var red_nexus = $"../red_nexus"
#var main_menu = preload("res://scenes/main_menu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if red_nexus.current_health <= 0:
		text = ("BLUE TEAM WINS!")
		visible = true
		get_tree().paused = true
	elif blue_nexus.current_health <= 0:
		text = ("RED TEAM WINS!")
		visible = true
		#get_tree().paused = true
	#if get_tree().paused == true and Input.is_action_just_pressed("f5"):
	#	get_tree().paused = false
	#	get_tree().change_scene_to_packed(main_menu)


func _on_button_pressed():
	#get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
