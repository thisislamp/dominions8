class_name UnitNexus extends BaseUnit

@export_range(0, 1000, 1, "or_greater") var max_mana: int = 1000
@export_range(0, 1000, 1, "or_greater") var initial_mana: int = 10

## The amount of mana this unit gains per second.
@export var mana_regen: int = 10

@export var ai_controlled: bool = false

@export var spawn_points: Array[SpawnPoint]

@onready var mana_bar: ProgressBar = $mana_bar

var current_mana: float = 0
var player_controlled: bool:
	get: return not ai_controlled


#func _ready() -> void:
	#super()


func _set_default_team() -> void:
	if ai_controlled:
		#set_team(-1, Color.from_hsv(randf(), 1, 1))
		print("Setting team to AI: ", self)
		set_team.call_deferred(get_map().get_game().get_team_by_name("AI"))
	else:
		print("Setting team to Player: ", self)
		var player_team := get_map().get_game().create_team("Player", Color.DARK_CYAN)
		set_team.call_deferred(player_team)


func spawn_unit(unit_type: PackedScene, point: SpawnPoint):
	if not unit_type.can_instantiate():
		push_error("What the heck is this shit I can't spawn this: %s" % unit_type)
		return

	var new_unit := unit_type.instantiate() as BaseUnit
	if not new_unit is BaseUnit:
		push_error("Tried to spawn non-BaseUnit type %s" % unit_type)
		return

	#var pos = get_viewport().get_mouse_position()
	#pos = pos.clamp(Vector2.ZERO, get_viewport_rect().size)

	var pos = point.global_position
	#print("Spawning at ", pos)

	new_unit.position = pos + Vector2(randf_range(-5, 5), randf_range(-5, 5))
	new_unit.team = team
	new_unit.spawn_point = point
	#new_unit.velocity = Vector2(1,-1)

	get_map().get_node("units").add_child(new_unit)

func move(_delta: float):
	return

func process_ai(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	current_mana = min(current_mana + mana_regen * delta, max_mana)
	mana_bar.value = current_mana

	if ai_controlled:
		process_ai(delta)


func _unhandled_key_input(event: InputEvent) -> void:
	if ai_controlled:
		return
	if not event is InputEventKey:
		return
	event = event as InputEventKey
	if not event.pressed:
		return

	return
	match event.keycode:
		KEY_1:
			spawn_unit(preload("res://scenes/unit/hurler.tscn"), $spawn_top)

		KEY_2:
			spawn_unit(preload("res://scenes/unit/hurler.tscn"), $spawn_mid)

		KEY_3:
			spawn_unit(preload("res://scenes/unit/hurler.tscn"), $spawn_bot)
