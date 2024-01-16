extends Area2D

@export var team_color: String
var projectile_damage = 3
var speed = 500

func _ready():
	set_as_top_level(true)
	if team_color == 'red':
		$teamcoloricon.set_self_modulate(Color(1,0,0))
	elif team_color == 'blue':
		$teamcoloricon.set_self_modulate(Color(0,0,1))
	add_to_group(team_color)
	add_to_group("projectile")
	#print("arrow groups:", get_groups())

func _process(delta):
	position += (Vector2.RIGHT*speed).rotated(rotation) * delta



func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()
	#print(team_color, "arrow deleted")


func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	pass # Replace with function body.
