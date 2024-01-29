class_name unit_slinger_old extends CharacterBody2D

var destination: Vector2
var direction: Vector2
var enemy_color: String
#var closest_enemy: Node = null
var shoot_timer: float = 0
var current_health: int 
var hurt_timer: int
var lane: UnitNexus.Lane
var waypoints = []
var current_waypoint_index = 0
var state: String

@export var team_color: String
@export var max_health: int = 10
@export var protection: int = 5
@export var shoot_cooldown: float = .5
@export var projectile_damage = 8
@export var attack_range: int = 200
@export var move_speed = 150

@export var projectile_scene = preload("res://scenes/rock_projectile.tscn")

@onready var healthbar = $health_bar
@onready var nav: NavigationAgent2D = $NavigationAgent2D


func get_enemy_color():
	if team_color == 'red':
		enemy_color = 'blue'
	elif team_color == 'blue':
		enemy_color = 'red'

func navigate_to_waypoints():
	if current_waypoint_index < waypoints.size() and waypoints.size() > 0:
		nav.target_position = waypoints[current_waypoint_index].global_position
		direction = nav.get_next_path_position() - global_position
		direction = direction.normalized()
		velocity = direction * move_speed
		if global_position.distance_to(nav.target_position) < 150:
			current_waypoint_index += 1
	if waypoints.size() == 0:
		print("no waypoints")
	elif current_waypoint_index == waypoints.size():
		print("touchdown")
		#queue_free()

func check_aggro_area():
	var overlapping_bodies = $aggro_area.get_overlapping_bodies()
	if overlapping_bodies.size() == 0:
		navigate_to_waypoints()
		return
	var closest_enemy = null
	var closest_distance = float('inf')

	for overlapping_body in overlapping_bodies:
		if "unit" in overlapping_body.get_groups() or "building" in overlapping_body.get_groups():
			if overlapping_body.current_health > 0 and overlapping_body.team_color == enemy_color: 
				var distance = global_position.distance_squared_to(overlapping_body.global_position)
				#print("distance: ", distance)
				if distance < closest_distance or !closest_distance:
					closest_distance = distance
					closest_enemy = overlapping_body
	if closest_enemy and closest_distance > (attack_range * attack_range):
		nav.target_position = closest_enemy.global_position
		direction = nav.get_next_path_position() - global_position
		velocity = direction.normalized() * move_speed
	elif closest_enemy and closest_distance <= (attack_range * attack_range):
		velocity = direction * 0.01
		#print("shoot")
		shoot_at_enemy(closest_enemy)
		return closest_enemy
	elif !closest_enemy:
		navigate_to_waypoints()
		return

func shoot_at_enemy(closest_enemy):
	if closest_enemy and shoot_timer <= 0:
		$Marker2D.look_at(closest_enemy.global_position)
		var projectile_instance = projectile_scene.instantiate()
		projectile_instance.global_position = $Marker2D.global_position
		projectile_instance.rotation = $Marker2D.rotation * randf_range(.95, 1.05)
		projectile_instance.team_color = team_color
		projectile_instance.scale.x = .3
		projectile_instance.scale.y = .3
		projectile_instance.projectile_damage = projectile_damage
		projectile_instance.speed = 500
		projectile_instance.persistence_health = 1
		projectile_instance.attack_range = attack_range
		add_child(projectile_instance)
		shoot_timer = shoot_cooldown
		$AnimatedSprite2D.play("sprite2")
	#if !closest_enemy:
		#print("no enemy")

func take_damage(damage_dealt):
	var damage_taken: int
	healthbar.visible = true
	damage_taken = DRN.roll_vs(damage_dealt, protection)
	if damage_taken > 0: current_health -= damage_taken
	healthbar.value = current_health
	$AnimatedSprite2D.modulate = Color(1,0,0)
	hurt_timer = 15
	if current_health <= 0:
		healthbar.visible = false
		$teamcoloricon.visible = false
		$AnimatedSprite2D.visible = false
		remove_from_group(team_color)
		$hitbox_area/hitbox_collision.disabled = true
		$pathfinding_collision.disabled = true
		$unit_collision/unit_collisionshape.disabled = true

func has_projectile_children() -> bool:
	for i in range(get_child_count()):
		var child_node = get_child(i)
		if "projectile" in child_node.get_groups():
			return true
	return false

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
	#find_closest_enemy()
	$AnimatedSprite2D.modulate = Color(1,1,1)
	if attack_range >= 250:
		$aggro_area/aggro_shape.shape.radius = attack_range + 25
	else: $aggro_area/aggro_shape.shape.radius = 275
		
	current_health = max_health
	healthbar.value = current_health
	healthbar.max_value = max_health
	healthbar.visible = false
	if team_color == 'red':
		$teamcoloricon.set_self_modulate(Color(1,0,0))
	elif team_color == 'blue':
		$teamcoloricon.set_self_modulate(Color(0,0,1))
	$AnimatedSprite2D.play("sprite1")

	nav.debug_enabled = get_tree().get_first_node_in_group("map").get("nav_debug") or false


func _physics_process(delta):
	if current_health > 0:
		#find_closest_enemy()
		check_aggro_area()
		#if waypoints.size() > 0:
		#	navigate_to_waypoints()
		move_and_slide()
		check_overlapping_bodies()
		if hurt_timer > 0: hurt_timer -= 1
		else: $AnimatedSprite2D.modulate = Color(1,1,1)
	else:
		has_projectile_children()
	if shoot_timer > 0:
		shoot_timer -= delta
	if current_health <= 0 and has_projectile_children() == false:
		queue_free()
	if direction.x > 0:
		$AnimatedSprite2D.scale.x = -1
	elif direction.x < 0:
		$AnimatedSprite2D.scale.x = 1


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
