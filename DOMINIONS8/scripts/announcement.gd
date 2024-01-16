extends Label
@onready var blue_nexus = $"../blue_nexus"
@onready var red_nexus = $"../red_nexus"

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if red_nexus.current_health <= 0:
		text = ("BLUE TEAM WINS!")
		show()
		get_tree().paused = true
	elif blue_nexus.current_health <= 0:
		text = ("RED TEAM WINS!")
		show()
		get_tree().paused = true
	if get_tree().paused == true and Input.is_action_just_pressed("f5"):
		get_tree().paused = false
		get_tree().reload_scene()
