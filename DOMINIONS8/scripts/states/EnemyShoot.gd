extends State
class_name EnemyShoot

#@export var enemy: CharacterBody2D
var player: CharacterBody2D
var direction : Vector2
var shoot_cooldown
var arrow = preload("res://scenes/arrow.tscn")

func Enter():
	player = get_tree().get_first_node_in_group("Player")
	if player:
		print("Player node found:", player)
	else:
		print("No player node found in the 'Player' group.")

func _physics_process(delta):
	if player:
		if enemy and $Marker2D:
			direction = player.global_position - enemy.global_position
			direction = direction.normalized()
			$Marker2D.look_at(enemy.global_position)
			
			var arrow_instance = arrow.instantiate()
			
			if arrow_instance:
				arrow_instance.rotation = $Marker2D.rotation
				arrow_instance.global_position = $Marker2D.global_position
				add_child(arrow_instance)
		else:
			print("Enemy or $Marker2D is null.")
	else:
		print("Player is null. Cannot calculate direction.")
