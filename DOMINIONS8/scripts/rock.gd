extends Area2D

@export var team_color: String
var enemy_color: String
@export var projectile_damage = 8
@export var speed = 500
@export var persistence_health: int = 1

func hit(persistance_hit):
	persistence_health -= persistance_hit
	projectile_damage -= 4
	print(projectile_damage)
	if persistence_health <= 0: queue_free()

func _ready():
	if team_color == 'red':
		enemy_color = 'blue'
	elif team_color == 'blue':
		enemy_color = 'red'
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
	#if persistence_counter <= 0: queue_free()

func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()
	#print(team_color, "arrow deleted")



