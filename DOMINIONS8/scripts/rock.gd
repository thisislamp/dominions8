extends Area2D

var team_color: String
var enemy_color: String
var projectile_damage = 8
var speed = 500
var persistence_health: int = 1
var spin: float = 0
var attack_range: int
var origin

func hit(persistance_hit):
	persistence_health -= persistance_hit
	projectile_damage -= 4
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
	#add_to_group("rock")
	origin = get_parent().global_position

func _process(delta):
	position += (Vector2.RIGHT*speed).rotated(rotation) * delta
	spin += 50
	$teamcoloricon.rotation_degrees = spin
	for body in get_overlapping_bodies():
		if "unit" in body.get_groups() and body.is_in_group(enemy_color) and body.current_health > 0:
			body.take_damage(projectile_damage)
			persistence_health -= 1
		if "building" in body.get_groups() and body.team_color == enemy_color and body.current_health > 0:
			body.take_damage(projectile_damage)
			persistence_health -= 100
	if persistence_health <= 0:
		queue_free()
	if global_position.distance_to(origin) > attack_range * 1.1:
		queue_free()

func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()
	#print(team_color, "arrow deleted")



