class_name UnitNexus extends Node2D

var current_mana: float
var enemy_color
var hurt_timer: int = 10
var selected_unit: Object
var selected_unit_mana_cost: int
var lane: Lane
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

@export var max_health: int = 100
@export var current_health: int
@export var max_mana: int = 1000
@export var mana_per_second: int = 1
@export var team_color: String
@export var protection: int = 15
@export var controlled_by: String

# Using named constants like an enum is better than using arbitrary strings.
# So called "stringly typed code" and is prone to various issues,
# namely typos and does not benefit from type checking and introspection.
enum Lane {Top, Mid, Bot}

const color_red = Color(1,.5,.5)
const color_blue = Color(.5,.5,1)

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
	$castleicon.modulate = Color.WHITE
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
		$teamcoloricon.color = color_red
	elif team_color == 'blue':
		$teamcoloricon.color = color_blue

func take_damage(damage_dealt):
	healthbar.visible = true
	
	var damage_taken: int = DRN.roll_vs(damage_dealt, protection)
	if damage_taken > 0:
		current_health -= damage_taken
	
	healthbar.value = current_health
	hurt_timer = 10
	$castleicon.modulate = Color.RED
	
	if healthbar.visible == false:
		healthbar.visible = true
	
	if current_health <= 0:
		remove_from_group(team_color)

## Tries to spawn a unit, mana allowing, then consumes the mana.
func try_spawn_unit(unit, lane: Lane):
	if current_mana >= selected_unit_mana_cost:
		spawn_unit(unit, lane)
		current_mana -= selected_unit_mana_cost

func spawn_unit(unit_instance, lane: Lane):
	var instance = unit_instance.instantiate()
	instance.team_color = team_color
	instance.lane = lane
	
	if team_color == "blue":
		# These could be converted to match, but there's probably a better way
		# to handle whatever is going on here anyway.
		if lane == Lane.Top:
			instance.position += Vector2(-100, -100)
			instance.waypoints = [get_node("/root/main/redtopt1").global_position, get_node("/root/main/redtopt2").global_position, get_node("/root/main/red_nexus").global_position]
		elif lane == Lane.Mid:
			instance.position += Vector2(100, -100)
			instance.waypoints = [get_node("/root/main/redmidt1").global_position, get_node("/root/main/redmidt2").global_position, get_node("/root/main/red_nexus").global_position]
		elif lane == Lane.Bot:
			instance.position += Vector2(100, 100)
			instance.waypoints = [get_node("/root/main/redbott1").global_position, get_node("/root/main/redbott2").global_position, get_node("/root/main/red_nexus").global_position]
	elif team_color == "red":
		if lane == Lane.Top:
			instance.position += Vector2(-100, -100)
			instance.waypoints = [get_node("/root/main/bluetopt1").global_position, get_node("/root/main/bluetopt2").global_position, get_node("/root/main/blue_nexus").global_position]
		elif lane == Lane.Mid:
			instance.position += Vector2(-100, 100)
			instance.waypoints = [get_node("/root/main/bluemidt1").global_position, get_node("/root/main/bluemidt2").global_position, get_node("/root/main/blue_nexus").global_position]
		elif lane == Lane.Bot:
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

# This is a bit overkill for an enum that won't change
# Converts the enum to a list of its int values and picks a random one.
func get_random_lane() -> Lane:
	return Lane.values()[randi() % Lane.size()] as Lane
	
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

func set_selected_unit(unit, cost: int):
	selected_unit = unit
	selected_unit_mana_cost = cost

func process_ai(delta: float):
	if current_mana >= 50:
		try_spawn_unit(get_random_unit(), get_random_lane())

func _physics_process(delta: float):
	# I havent changed this part, see the large comment below
	var delay_timer = 10
	delay_timer -= 1
	if delay_timer <= 0:
		get_enemy_lane_buildings()
	if hurt_timer > 0: 
		hurt_timer -= 1
	else: 
		$castleicon.modulate = Color.WHITE

	if current_mana < max_mana and game_active: 
		# You know all about the issues with tying framerate to physics right?  Plenty of games
		# do that and cause all sorts of problems when running at fps higher or lower than intended.
		# Thats why the right way to do it is to handle physics with the physics delta, or a value
		# not dependant on the fps, but on a constant time ratio.  A higher delta value means
		# whatever you do your physics stuff for more time.  Here, a delta of 1 means one second.
		# If you add 1 mana regardless of the delta, you end up with the same problem in reverse.
		# This also means we need to change the type of current_mana from int to float.
		# We multiply by Engine.physics_tics_per_second because otherwise at 60pfps, it would take
		# 60 seconds to add 1 mana.  60 calls per seconds means delta = 1/60 = 0.01666...
		current_mana += mana_per_second * Engine.physics_ticks_per_second * delta
	
	manabar.value = current_mana
	
	if controlled_by == "ai":
		process_ai(delta)

# Handling inputs this way is better than polling for them in the physics loop,
# but not quite as good as using an InputMap.  For accepting multiple control
# schemes, like keyboard and controller input, an InputMap is better.
# We also don't need to worry about the ai logic this way.
# The mana cost handling has been moved to a new function, try_spawn_unit().
func _unhandled_key_input(event: InputEvent):
	if event is InputEventKey:
		match event.keycode:
			# Unit selection keys
			KEY_S: set_selected_unit(unit_slinger, slinger_mana_cost)
			KEY_H: set_selected_unit(unit_hurler, hurler_mana_cost)
			KEY_B: set_selected_unit(unit_berserker, berserker_mana_cost)
			KEY_C: set_selected_unit(unit_heavycav, heavycav_mana_cost)
			KEY_W: set_selected_unit(unit_wizard, wizard_mana_cost)
			# Lane spawn keys
			KEY_DOWN: try_spawn_unit(selected_unit, Lane.Bot)
			KEY_UP: try_spawn_unit(selected_unit, Lane.Top)
			KEY_LEFT, KEY_RIGHT: try_spawn_unit(selected_unit, Lane.Mid)

# Handles the mouse input if it wasn't handled by a gui element (in the future)
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event:
			match event.button_index:
				MOUSE_BUTTON_LEFT when event.is_pressed(): 
					try_spawn_unit(selected_unit, get_random_lane())
			
