extends Area2D

var team_color: String
var enemy_color: String
var projectile_damage = 0
var persistence_health: int = 100
var fireballspin: float = 0
var speed = 375
var attack_range: int
var origin

func _ready():
	if team_color == 'red':
		enemy_color = 'blue'
	elif team_color == 'blue':
		enemy_color = 'red'
	set_as_top_level(true)
	add_to_group(team_color)
	add_to_group("projectile")
	origin = get_parent().global_position
	$explosion.visible = false
	var projectile_damage = 0

func hit(persistance_hit):
	persistence_health -= persistance_hit

func detonate():
			speed = 0
			$explosion.visible = true
			$fireballicon.visible = false
			$fireballicon2.visible = false
			$projectile_collision_shape.disabled = true
			$AnimationPlayer.play("explode")
			var explosion_overlapping_bodies = $explosion_area.get_overlapping_bodies()
			for body in explosion_overlapping_bodies:
				if "unit" in body.get_groups() and body.current_health > 0:
					body.take_damage(16)
					body.knockback(global_position, 16)
				if "building" in body.get_groups() and body.current_health > 0:
					body.take_damage(8)


func _process(delta):
	position += (Vector2.RIGHT*speed).rotated(rotation) * delta
	fireballspin += 25
	$fireballicon.rotation_degrees = fireballspin
	$fireballicon2.rotation_degrees = (fireballspin * (-2))
	for body in get_overlapping_bodies():
		if body.is_in_group(enemy_color):
			detonate()
	if global_position.distance_to(origin) > attack_range * 2:
		queue_free()


func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()

func _on_animation_player_animation_finished(explode):
	queue_free()
