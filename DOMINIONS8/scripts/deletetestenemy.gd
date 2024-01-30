extends CharacterBody2D
class_name enemy
var player: CharacterBody2D

###PROBABLY NEED TO REMOVE THIS WHEN I MAKE MULTIPLE TARGETS
#func Enter():
#	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta):
	move_and_slide()

