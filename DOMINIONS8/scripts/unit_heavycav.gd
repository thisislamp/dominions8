class_name unit_heavycav extends CharacterBody2D

var destination: Vector2
var direction: Vector2
var enemy_color: String
var closest_enemy: Node = null
var attack_range: int = 45
var attack_timer: float = 0
var current_health: int
var hurt_timer: int
var lane: UnitNexus.Lane


@export var team_color: String
@export var max_health = 15
@export var protection: int = 18
@export var attack_cooldown: float = .5
@export var move_speed = 160
@export var attack_damage: int = 22
#@export var mana_cost: int = 100

@onready var healthbar = $health_bar
@onready var nav: NavigationAgent2D = $NavigationAgent2D

func get_enemy_color():
	if team_color == 'red':
		enemy_color = 'blue'
	elif team_color == 'blue':
		enemy_color = 'red'

func find_closest_enemy():
	var closest_distance = float('inf')
	closest_enemy = null
	for node in get_tree().get_nodes_in_group(enemy_color):
		if "projectile" in node.get_groups():
			continue
		var distance = global_position.distance_squared_to(node.global_position)
		if distance and distance < closest_distance:
			closest_distance = distance
			closest_enemy = node
		elif !closest_distance:
			closest_distance = distance
			closest_enemy = node
	if closest_enemy in get_tree().get_nodes_in_group("building"):
		attack_range = 115
	else: attack_range = 45
	if closest_distance > (attack_range * attack_range):
		nav.target_position = closest_enemy.global_position
		direction = nav.get_next_path_position() - global_position
		direction = direction.normalized()
		velocity = direction * move_speed
	else:
		velocity = direction * .01
		$AnimatedSprite2D.play("sprite2")
		closest_enemy.take_damage(attack_damage)
		attack_damage = 16
		attack_timer = attack_cooldown
		#shoot_at_enemy()
	if direction.x > 0:
		$AnimatedSprite2D.scale.x = -1
	elif direction.x < 0:
		$AnimatedSprite2D.scale.x = 1
	return closest_enemy

func take_damage(damage_dealt):
	var damage_taken: int
	healthbar.visible = true
	damage_taken = DRN.roll_vs(damage_dealt, protection)
	if damage_taken > 0: current_health -= damage_taken
	healthbar.value = current_health
	hurt_timer = 15
	if current_health <= 0:
		healthbar.visible = false
		$teamcoloricon.visible = false
		$AnimatedSprite2D.visible = false
		remove_from_group(team_color)
		$unit_collision/unit_collisionshape.disabled = true
		$pathfinding_collision.disabled = true
		$unit_collision/unit_collisionshape.disabled = true

func knockback(knockback_source_global_position, knockback_power):
	var knockback_direction: Vector2
	knockback_direction = global_position - knockback_source_global_position
	velocity = knockback_direction.normalized() * knockback_power
	move_and_slide()

func check_overlapping_bodies():
	var overlapping_bodies = $unit_collision.get_overlapping_bodies()
	for overlapping_body in overlapping_bodies:
		if "unit" in overlapping_body.get_groups() and current_health > 0:
			knockback(overlapping_body.global_position, 30)
	pass

func _ready():
	add_to_group(team_color)
	add_to_group("unit")
	get_enemy_color()
	find_closest_enemy()
	$AnimatedSprite2D.modulate = Color(1,1,1)
	current_health = max_health
	healthbar.value = current_health
	healthbar.max_value = max_health
	healthbar.visible = false
	if team_color == 'red':
		$teamcoloricon.set_self_modulate(Color(1,0,0))
	elif team_color == 'blue':
		$teamcoloricon.set_self_modulate(Color(0,0,1))
	$AnimatedSprite2D.play("sprite1")

func _physics_process(delta):
	if current_health > 0 and attack_timer <= 0:
		find_closest_enemy()
		move_and_slide()
		check_overlapping_bodies()
		if hurt_timer > 0: hurt_timer -= 1
		else: $AnimatedSprite2D.modulate = Color(1,1,1)
	if attack_timer > 0:
		attack_timer -= delta
	if current_health <= 0:
		queue_free()


###DEBUGGING ONLY
func print_group_nodes(group_name: String):
	print("Nodes in group '", group_name, "':")
	for node in get_tree().get_nodes_in_group(group_name):
		print(node)
	print("-----")

func print_all_children():
	print("List of child nodes:")
	for i in range(get_child_count()):
		var child_node = get_child(i)
		print("Child node name:", child_node.name)
	print("-----")
