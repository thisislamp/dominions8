extends StaticBody2D
var enemy_color
var hurt_timer = 0
var closest_enemy = Node
var shoot_timer = 0

@onready var healthbar = $health_bar
@onready var projectile_scene = preload("res://scenes/rock_projectile.tscn")

@export var attack_range: int = 250
@export var projectile_damage: int = 10
@export var projectile_persistence_health: int = 2
@export var lane: String
@export var max_health = 100
@export var max_mana = 1000
@export var current_health: int
@export var team_color: String
@export var protection: int = 5
@export var shoot_cooldown: float = .5

func get_enemy_color():
	if team_color == 'red':
		enemy_color = 'blue'
	elif team_color == 'blue':
		enemy_color = 'red'
	else:
		print("BUG: SPAWNER COLOR NOT SET")

func _ready():
	add_to_group(team_color)
	add_to_group("building")
	add_to_group(lane)
	set_as_top_level(true)
	apply_team_color()
	get_enemy_color()
	$towericon.modulate = Color(1,1,1)
	current_health = max_health
	healthbar.value = current_health
	healthbar.max_value = max_health
	$shoot_range_area/shoot_range_shape.shape.radius = attack_range
func apply_team_color():
	if team_color == 'red':
		$teamcoloricon.set_self_modulate(Color(1,.5,.5))
	elif team_color == 'blue':
		$teamcoloricon.set_self_modulate(Color(.5,.5,1))

func set_team_color(new_color: String):
	if new_color == "red" or new_color == "blue":
		team_color = new_color
	else:
		print("Invalid color option. Allowed options are 'red' or 'blue'")
	if team_color == 'red':
		$teamcoloricon.set_self_modulate(Color(1,0,0))
	elif team_color == 'blue':
		$teamcoloricon.set_self_modulate(Color(0,0,1))

func take_damage(damage_dealt):
	var damage_taken: int
	healthbar.visible = true
	damage_taken = DRN.roll_vs(damage_dealt, protection)
	if damage_taken > 0:
		current_health -= damage_taken
	healthbar.value = current_health
	hurt_timer = 15
	$towericon.modulate = Color(1,0,0)
	if healthbar.visible == false:
		healthbar.visible = true
	if current_health <= 0:
		$health_bar.visible = false
		$shoot_range_area/shoot_range_shape.disabled = true
		$hitbox_area/hitbox_shape.disabled = true
		$pathfinding_collision.disabled = true
		$towericon.visible = false
		$teamcoloricon.visible = false
		remove_from_group(team_color)
		remove_from_group(lane)
		remove_from_group("building")
	#	queue_free()
	#if current_health <= 0:
	#	queue_free()

func find_closest_enemy():
	var closest_distance = float('inf')
	var overlapping_bodies = $shoot_range_area.get_overlapping_bodies()
	closest_enemy = null
	for node in overlapping_bodies:
		if "unit" in node.get_groups() and enemy_color in node.get_groups() and node.current_health > 0:
			var distance = global_position.distance_squared_to(node.global_position)
			if distance and distance < closest_distance:
				closest_distance = distance
				closest_enemy = node
			elif !closest_distance:
				closest_distance = distance
				closest_enemy = node
	shoot_at_enemy()
	return closest_enemy

func shoot_at_enemy():
	if closest_enemy and shoot_timer <= 0:
		$projectile_spawn_point.look_at(closest_enemy.global_position)
		var projectile_instance = projectile_scene.instantiate()
		projectile_instance.global_position = $projectile_spawn_point.global_position
		projectile_instance.rotation = $projectile_spawn_point.rotation * randf_range(.95, 1.05)
		projectile_instance.team_color = team_color
		projectile_instance.projectile_damage = projectile_damage
		projectile_instance.speed = 500
		projectile_instance.scale.x = .6
		projectile_instance.scale.y = .6
		projectile_instance.persistence_health = 2
		projectile_instance.attack_range = attack_range
		add_child(projectile_instance)
		shoot_timer = shoot_cooldown
		#$AnimatedSprite2D.play("sprite2")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	find_closest_enemy()
	if shoot_timer > 0:
		shoot_timer -= delta
	if hurt_timer > 0:
		hurt_timer -= 1
	else:
		$towericon.modulate = Color(1,1,1)
