extends State
class_name EnemyFollow

#@export var enemy: CharacterBody2D
@export var move_speed := 120
@onready var nav: NavigationAgent2D = $"../../NavigationAgent2D"
var player: CharacterBody2D
var direction : Vector2

func Enter():
	player = get_tree().get_first_node_in_group("Player")
	if player:
		print("Player node found:", player)
	else:
		print("No player node found in the 'Player' group.")

func _physics_process(delta):
	if player:
		#direction = player.global_position - enemy.global_position
		nav.target_position = player.global_position
		direction = nav.get_next_path_position() - enemy.global_position
		direction = direction.normalized()
		enemy.velocity = direction.normalized() * move_speed
	else:
		print("Player is null. Cannot calculate direction.")
