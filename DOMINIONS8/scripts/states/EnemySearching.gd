extends State
class_name EnemySearching

var enemy: CharacterBody2D
@export var move_speed := 60

var player: CharacterBody2D
var direction : Vector2
var search_time : float

func look_for_player():
	#direction = (Vector2((randf_range(.4, 2) * player.global_position.x), (randf_range(.4, 2) * player.global_position.y))) - enemy.global_position
	direction = player.global_position - enemy.global_position

func Enter():
	enemy = $"../.."
	player = get_tree().get_first_node_in_group("Player")
	look_for_player()
	search_time = 0

func Update(delta: float):
	if search_time > 0:
		search_time -= delta
	else:
		search_time = randf_range(.5,2)
		look_for_player()

func Physics_Update(delta: float):
#	if direction.length() < 600:
#		Transitioned.emit(self, "EnemyFollow")
	if enemy:
		enemy.velocity = direction.normalized() * move_speed
