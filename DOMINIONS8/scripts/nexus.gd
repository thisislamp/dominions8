extends Node2D
var current_mana
var enemy_color
var hurt_timer = 10
var selected_unit: Object
var selected_unit_mana_cost: int
var lane
var slinger_mana_cost: int = 25
var hurler_mana_cost: int = 150
var berserker_mana_cost: int = 170
var heavycav_mana_cost: int = 170
var wizard_mana_cost: int = 160
var game_active: bool = true
var enemy_top_buildings
var enemy_mid_buildings
var enemy_bot_buildings


@onready var unit_slinger = preload("res://scenes/unit_slinger.tscn")
@onready var unit_hurler = preload("res://scenes/unit_hurler.tscn")
@onready var unit_berserker = preload("res://scenes/unit_berserker.tscn")
@onready var unit_heavycav = preload("res://scenes/unit_heavycav.tscn")
@onready var unit_wizard = preload("res://scenes/unit_wizard.tscn")
@onready var healthbar = $health_bar
@onready var manabar = $mana_bar

@export var max_health = 100
@export var max_mana = 1000
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
	add_to_group('building')
	add_to_group('top')
	add_to_group('mid')
	add_to_group('bot')
	set_as_top_level(true)
	apply_team_color()
	get_enemy_color()
	get_enemy_lane_buildings()
	$castleicon.modulate = Color(1,1,1)
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
		$teamcoloricon.color = (Color(1,.5,.5))
	elif team_color == 'blue':
		$teamcoloricon.color = (Color(.5,.5,1))

func take_damage(damage_dealt):
	var damage_taken: int
	healthbar.visible = true
	damage_taken = DRN.roll_vs(damage_dealt, protection)
	if damage_taken > 0: current_health -= damage_taken
	healthbar.value = current_health
	hurt_timer = 10
	$castleicon.modulate = Color(1,0,0)
	if healthbar.visible == false:
		healthbar.visible = true
	if current_health <= 0:
		remove_from_group(team_color)

func spawn_unit(unit_instance, lane):
	var instance = unit_instance.instantiate()
	instance.team_color = team_color
	instance.lane = lane
	if lane == "top" and team_color == "blue":
		instance.position += Vector2(-100, -100)
		instance.waypoints = [get_node("/root/main/redtopt1").global_position, get_node("/root/main/redtopt2").global_position, get_node("/root/main/red_nexus").global_position]
	if lane == "mid" and team_color == "blue":
		instance.position += Vector2(100, -100)
		instance.waypoints = [get_node("/root/main/redmidt1").global_position, get_node("/root/main/redmidt2").global_position, get_node("/root/main/red_nexus").global_position]
	if lane == "bot" and team_color == "blue":
		instance.position += Vector2(100, 100)
		instance.waypoints = [get_node("/root/main/redbott1").global_position, get_node("/root/main/redbott2").global_position, get_node("/root/main/red_nexus").global_position]
	if lane == "top" and team_color == "red":
		instance.position += Vector2(-100, -100)
		instance.waypoints = [get_node("/root/main/bluetopt1").global_position, get_node("/root/main/bluetopt2").global_position, get_node("/root/main/blue_nexus").global_position]
	if lane == "mid" and team_color == "red":
		instance.position += Vector2(-100, 100)
		instance.waypoints = [get_node("/root/main/bluemidt1").global_position, get_node("/root/main/bluemidt2").global_position, get_node("/root/main/blue_nexus").global_position]
	if lane == "bot" and team_color == "red":
		instance.position += Vector2(100, 100)
		instance.waypoints = [get_node("/root/main/bluemidt1").global_position, get_node("/root/main/bluemidt2").global_position, get_node("/root/main/blue_nexus").global_position]
	add_child(instance)

func get_random_unit():
	match randi_range(0, 4):
		0: return unit_slinger
		#1: return unit_hurler
		#2: return unit_berserker
		#3: return unit_heavycav
		#4: return unit_wizard
		_: return unit_slinger

func get_random_lane():
	var random_choice = randi() % 3
	var lane: String
	if random_choice == 0: lane = "top"
	if random_choice == 1: lane = "mid"
	if random_choice == 2: lane = "bot"
	return lane

func get_enemy_lane_buildings():
	var enemy_top_buildings = []
	var enemy_mid_buildings = []
	var enemy_bot_buildings = []
	var buildings = get_tree().get_nodes_in_group("building")
	for building in buildings:
		if building.is_in_group(enemy_color):
			if building.is_in_group("top"):
				enemy_top_buildings.append(building)
			if building.is_in_group("mid"):
				enemy_mid_buildings.append(building)
			if building.is_in_group("bot"):
				enemy_bot_buildings.append(building)
	#return enemy_top_buildings
	#return enemy_mid_buildings
	#return enemy_bot_buildings
	return enemy_top_buildings and enemy_mid_buildings and enemy_bot_buildings

func _physics_process(delta):
	var delay_timer = 10
	delay_timer -= 1
	if delay_timer <= 0:
		get_enemy_lane_buildings()
	if hurt_timer > 0: 
		hurt_timer -= 1
	else: 
		$castleicon.modulate = Color(1,1,1)
	if Input.is_action_just_pressed("s"): 
		selected_unit = unit_slinger
		selected_unit_mana_cost = slinger_mana_cost
	if Input.is_action_just_pressed("h"): 
		selected_unit = unit_hurler
		selected_unit_mana_cost = hurler_mana_cost
	if Input.is_action_just_pressed("b"): 
		selected_unit = unit_berserker
		selected_unit_mana_cost = berserker_mana_cost
	if Input.is_action_just_pressed("c"): 
		selected_unit = unit_heavycav
		selected_unit_mana_cost = heavycav_mana_cost
	if Input.is_action_just_pressed("w"): 
		selected_unit = unit_wizard
		selected_unit_mana_cost = wizard_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("left_mouse") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, get_random_lane())
		current_mana -= selected_unit_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("downarrow") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, "bot")
		current_mana -= selected_unit_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("uparrow") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, "top")
		current_mana -= selected_unit_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("rightarrow") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, "mid")
		current_mana -= selected_unit_mana_cost
	if controlled_by == "human" and Input.is_action_just_pressed("leftarrow") and current_mana >= selected_unit_mana_cost:
		spawn_unit(selected_unit, "mid")
		current_mana -= selected_unit_mana_cost
	if current_mana < max_mana and game_active == true: current_mana += 1
	manabar.value = current_mana
	if controlled_by == "ai" and current_mana >= 50:
		#selected_unit = get_random_unit()
		#spawn_direction = get_random_spawn_direction()
		spawn_unit(get_random_unit(), get_random_lane())
		current_mana -= selected_unit_mana_cost
