extends Node2D
var current_mana
var enemy_color
var hurt_timer = 10
@onready var healthbar = $health_bar
@onready var manabar = $mana_bar
@export var current_health: int
@export var team_color: String
@export var spawn_cooldown: int = 10
@export var armor: int = 2
@export var controlled_by: String
var spawn_timer: int = 1

@export var max_health = 100
@export var max_mana = 500

func get_enemy_color():
	if team_color == 'red':
		enemy_color = 'blue'
	elif team_color == 'blue':
		enemy_color = 'red'
	else:
		print("BUG: SPAWNER COLOR NOT SET")

func _ready():
	add_to_group(team_color)
	set_as_top_level(true)
	apply_team_color()
	get_enemy_color()
	$backgroundcoloricon.modulate = Color(1,1,1)
	current_health = max_health
	healthbar.value = current_health
	healthbar.max_value = max_health
	healthbar.visible = false
	current_mana = 8
	manabar.value = current_mana
	manabar.max_value = max_mana
	


func apply_team_color():
	if team_color == 'red':
		$teamcoloricon.set_self_modulate(Color(1,0,0))
	elif team_color == 'blue':
		$teamcoloricon.set_self_modulate(Color(0,0,1))

func set_team_color(new_color: String):
	if new_color == "red" or new_color == "blue":
		team_color = new_color
	else:
		print("Invalid color option. Allowed options are 'red' or 'blue'")
	if team_color == 'red':
		$teamcoloricon.set_self_modulate(Color(1,0,0))
	elif team_color == 'blue':
		$teamcoloricon.set_self_modulate(Color(0,0,1))

func take_damage(damage_taken):
	current_health -= (damage_taken - armor)
	healthbar.value = current_health
	hurt_timer = 15
	$backgroundcoloricon.modulate = Color(1,0,0)
	if healthbar.visible == false:
		healthbar.visible = true
	if current_health <= 0:
		$backgroundcoloricon.modulate = Color(1,0,0)
		#queue_free()
		pass

func _on_hitbox_area_area_entered(area):
	if "projectile" in area.get_groups() and enemy_color in area.get_groups() and current_health > 0:
		take_damage(area.projectile_damage)
		area.queue_free()

func spawn_slinger(direction):
		var unit_slinger = preload("res://scenes/unit_slinger.tscn").instantiate()
		if direction == null:
			unit_slinger.position += Vector2(0, randf_range(-10, 10)*20)
		if direction == "left":
			unit_slinger.position += Vector2(-100, randf_range(-10, 10))
		if direction == "right":
			unit_slinger.position += Vector2(100, randf_range(-10, 10))
		if direction == "up":
			unit_slinger.position += Vector2(randf_range(-10, 10), -150)
		if direction == "down":
			unit_slinger.position += Vector2(randf_range(-10, 10), 150)
		unit_slinger.team_color = team_color
		add_child(unit_slinger)

func spawn_hurler(direction):
		var unit_hurler = preload("res://scenes/unit_hurler.tscn").instantiate()
		if direction == null:
			unit_hurler.position += Vector2(0, randf_range(-10, 10)*20)
		if direction == "left":
			unit_hurler.position += Vector2(-100, randf_range(-10, 10))
		if direction == "right":
			unit_hurler.position += Vector2(100, randf_range(-10, 10))
		if direction == "up":
			unit_hurler.position += Vector2(randf_range(-10, 10), -150)
		if direction == "down":
			unit_hurler.position += Vector2(randf_range(-10, 10), 150)
		unit_hurler.team_color = team_color
		add_child(unit_hurler)

func _process(delta):
	spawn_timer -= 1
	if hurt_timer > 0: hurt_timer -= 1
	else: $backgroundcoloricon.modulate = Color(1,1,1)
	if spawn_timer <= 0 and current_health >= 0:
		spawn_timer = spawn_cooldown
	if controlled_by == "human" and Input.is_action_just_pressed("left_mouse")and current_mana >= 100:
		spawn_slinger(null)
		current_mana -= 100
	if controlled_by == "human" and Input.is_action_just_pressed("downarrow")and current_mana >= 100:
		spawn_slinger("down")
		current_mana -= 100
	if controlled_by == "human" and Input.is_action_just_pressed("uparrow")and current_mana >= 100:
		spawn_slinger("up")
		current_mana -= 100
	if controlled_by == "human" and Input.is_action_just_pressed("rightarrow")and current_mana >= 100:
		spawn_slinger("right")
		current_mana -= 100
	if controlled_by == "human" and Input.is_action_just_pressed("leftarrow")and current_mana >= 100:
		spawn_slinger("left")
		current_mana -= 100
	
	
	if current_mana < max_mana: current_mana += 1
	manabar.value = current_mana
	if controlled_by == "ai" and current_mana >= 100:
		spawn_slinger(null)
		current_mana -= 100
	
	
#func _on_Timer_timeout():
