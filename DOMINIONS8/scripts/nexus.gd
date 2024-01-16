extends Node2D
var current_mana
var enemy_color
var hurt_timer = 10
var spawn_timer: int = 1
var selected_unit: Object
var selected_unit_mana_cost: int
var slinger_mana_cost: int = 120
var hurler_mana_cost: int = 180
var berserker_mana_cost: int = 180

@onready var unit_slinger = preload("res://scenes/unit_slinger.tscn")
@onready var unit_hurler = preload("res://scenes/unit_hurler.tscn")
@onready var unit_berserker = preload("res://scenes/unit_berserker.tscn")
@onready var healthbar = $health_bar
@onready var manabar = $mana_bar

@export var max_health = 100
@export var max_mana = 500
@export var current_health: int
@export var team_color: String
@export var protection: int = 15
@export var controlled_by: String

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
	selected_unit = unit_slinger
	selected_unit_mana_cost = 100

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

func take_damage(damage_dealt):
	var damage_taken: int
	healthbar.visible = true
	damage_taken = (damage_dealt + DRN())- (protection + DRN())
	if damage_taken > 0: current_health -= damage_taken
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
		area.hit(10)

func spawn_unit(unit_scene, direction):
	var unit_instance = unit_scene.instantiate()
	if direction == null:
		unit_instance.position += Vector2(0, randf_range(-10, 10)*20)
	if direction == "left":
		unit_instance.position += Vector2(-100, randf_range(-10, 10))
	if direction == "right":
		unit_instance.position += Vector2(100, randf_range(-10, 10))
	if direction == "up":
		unit_instance.position += Vector2(randf_range(-10, 10), -150)
	if direction == "down":
		unit_instance.position += Vector2(randf_range(-10, 10), 150)
	unit_instance.team_color = team_color
	add_child(unit_instance)
	

func _process(delta):
	#spawn_timer -= 1
	if hurt_timer > 0: hurt_timer -= 1
	else: $backgroundcoloricon.modulate = Color(1,1,1)
	if Input.is_action_just_pressed("s"): 
		selected_unit = unit_slinger
		selected_unit_mana_cost = slinger_mana_cost
	if Input.is_action_just_pressed("h"): 
		selected_unit = unit_hurler
		selected_unit_mana_cost = hurler_mana_cost
	if Input.is_action_just_pressed("b"): 
		selected_unit = unit_berserker
		selected_unit_mana_cost = berserker_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("left_mouse") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, null)
		current_mana -= selected_unit_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("downarrow") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, "down")
		current_mana -= selected_unit_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("uparrow") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, "up")
		current_mana -= selected_unit_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("rightarrow") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, "right")
		current_mana -= selected_unit_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("leftarrow") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, "left")
		current_mana -= selected_unit_mana_cost
	if current_mana < max_mana: current_mana += 1
	manabar.value = current_mana
	if controlled_by == "ai" and current_mana >= berserker_mana_cost:
		spawn_unit(selected_unit, null)
		current_mana -= selected_unit_mana_cost
		var random_choice = randi() % 3
		if random_choice == 0: selected_unit = unit_slinger
		if random_choice == 1: selected_unit = unit_hurler
		if random_choice == 2: selected_unit = unit_berserker
		

func DRN():
	var total_result = 0
	while true:
		var die1 = randi() % 6 + 1
		var die2 = randi() % 6 + 1
		total_result += die1 + die2
		if die1 == 6:
			total_result -= 1
			continue  # Re-roll the die
		if die2 == 6:
			total_result -= 1
			continue  # Re-roll the die
		break  # Exit the loop if no more re-rolls are needed
	return total_result
