class_name BaseUnit extends CharacterBody2D

## The name of the unit
@export var object_name: String

## The base maximum health of the unit.
@export var max_health: int = 10

## The base protection of the unit.
@export var protection: int = 1

## The base movement speed of the unit (in px?).
@export_range(0, 1000, 1, "or_greater") var move_speed: int = 100

## The bonus attack range of the unit.  This value can be added to a weapon's
## base attack range, if the weapon will use it.
@export_range(0, 1000, 1, "exp") var bonus_attack_range: int = 0

## The bonus acquisition range of a unit.  The range at which the unit will lock
## onto a target and begin to attack it.  This value can be added to a weapon's
## base acquisition range, if the weapon will use it.
@export var bonus_acquisition_range: int = 0

## Base attack time, a coefficient to modify weapon attack speed.  Works the
## same way it does in Dota. [br]
## 1 = 100% (normal)[br]
## 2 = 50% (half speed)[br]
## 0.6 = 166% (2/3rds faster)
@export_range(0.01, 10, 0.01, "exp") var bat: float = 1.0

## How much mana it costs to spawn this unit.
@export_range(0, 1000, 1) var mana_cost: int = 100

## Debug setting
@export var default_team_id: int

var current_target: BaseUnit
var spawn_point: SpawnPoint
var team: GameTeam: set=set_team, get=get_team
var movement_state: MovementState = MovementState.STOPPED:
	set=set_movement_state,
	get=get_movement_state

var oob_kill_range: int = 200

# Debug vars
static var _debug_show_pathing: bool = false
static var _debug_show_hitbox: bool = false
static var _debug_show_collision: bool = false

@onready var current_health: int = max_health

# Node aliases
@onready var sprite: AnimatedSprite2D = %sprite as AnimatedSprite2D
@onready var attack_origin: Marker2D = %attack_origin as Marker2D
@onready var health_bar: ProgressBar = %health_bar as ProgressBar
@onready var nav: NavigationAgent2D = %nav as NavigationAgent2D
@onready var equipment: Array[Node]:
	get: return $equipment.get_children()

enum MovementState {MOVING, STANDING, STOPPED}

## Emitted when a unit dies
signal unit_died(unit: BaseUnit)


func _ready():
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.visible = false

	if default_team_id:
		var temp_team = get_map().get_game().get_team(default_team_id)
		if team == GameTeam.UNAFFILIATED:
			team = get_map().get_game().create_team(
				"Debug Team %s" % default_team_id,
				Color.from_hsv(randf(), .9, .9),
				default_team_id,
			)

	# TODO: switch to use signals
	if OS.is_debug_build():
		# sets spawning with pathfinding visible
		var map = get_tree().get_first_node_in_group("map")
		nav.debug_enabled = BaseUnit._debug_show_pathing or map._debug_pathing if map else false

## Returns the GameMap node for this scene.
func get_map() -> GameMap:
	# TODO: fix for dedicated server
	return get_tree().get_first_node_in_group("map")

func get_game() -> GameSession:
	return get_map().get_game()

## Returns the GameTeam the unit is on, or GameTeam.UNAFFILIATED if unassigned.
func get_team() -> GameTeam:
	return team if team else GameTeam.UNAFFILIATED

## Sets the team for this unit.
func set_team(value: GameTeam) -> void:
	if team:
		remove_from_group("team_%s" % team.id)
	team = value
	if $team_marker:
		$team_marker.color = team.color
	add_to_group("team_%s" % team.id)

func set_movement_state(state: MovementState) -> void:
	movement_state = state
	if state == MovementState.STANDING:
		velocity = Vector2.ZERO

func get_movement_state() -> MovementState:
	return movement_state

### Returns the unit's current target, or chooses and returns a new target.
#func get_target():
	#if Utils.is_alive(current_target):
		#return current_target
	#return choose_target()
#
### Picks and returns a target within the attack range of the unit, or null if none found
#func choose_target():
	#pass

## Attacks a target with its first available weapon, if any.  Returns a bool
## value for if attack was made.
func attack(target: BaseUnit) -> bool:
	for item in equipment:
		if not item is BaseWeapon:
			continue
		if item.ready_to_use:
			item.attack(target)
			return true
	return false

## Attacks a target with a specific weapon
func attack_with(target: BaseUnit, weapon: BaseWeapon) -> void:
	assert(weapon in equipment, "weapon %s not owned by %s?" % [weapon, self])
	weapon.attack(target)

## Uses the weapon without a unit target in a specific direction or ground target
func use_weapon(weapon: BaseWeapon, target: Vector2) -> void:
	assert(weapon in equipment, "weapon %s not owned by %s?" % [weapon, self])
	weapon.use(target)

## Deal damage to the unit, calculating damage taken
func take_damage(damage: int) -> void:
	if damage > 0:
		current_health -= damage
		health_bar.visible = true
		health_bar.value = current_health

		if current_health <= 0:
			die()
			return

		# Use float devision
		flash_damage(Color.RED, 1 - current_health * 1.0 / max_health)
	else:
		flash_damage(Color.GRAY, 0.5)

## Flashes the unit a given color and strength for a duration.
func flash_damage(color: Color, intensity: float = 1, duration: float = 0.25) -> void:
	# TODO: this seems wrong, maybe I should scale saturation based on intensity
	sprite.self_modulate = Color.from_hsv(color.h, color.s * intensity, color.v)
	await get_tree().create_timer(duration, false).timeout
	sprite.self_modulate = Color.WHITE

## Kill the unit.  Emits [signal unit_died] and frees the object.
func die() -> void:
	unit_died.emit(self)
	queue_free()

## Checks to see if the unit has gone out of bounds and deletes it.  Does not
## call die() on the unit.
func check_oob() -> bool:
	if not oob_kill_range:
		return false

	var limit := get_viewport_rect().size
	if abs(global_position).x - oob_kill_range > limit.x or \
		abs(global_position).y - oob_kill_range > limit.y:

		print(self, ": OOB deleted at ", global_position)
		queue_free()
		return true
	return false

## Moves the unit.  Defaults to simply calling move_and_slide()
func move(_delta: float):
	match movement_state:
		MovementState.MOVING:
			move_and_slide()
		MovementState.STANDING:
			velocity = Vector2.ZERO
			move_and_slide()
		MovementState.STOPPED:
			return


#func _process(delta: float) -> void:
	#sprite.scale.x = -1 if velocity.x > 0 else 1
	#$sprite.flip_h = velocity.x < 0

func _physics_process(delta: float) -> void:
	if check_oob():
		return

	if velocity != Vector2.ZERO:
		sprite.scale.x = -1 if velocity.x > 0 else 1
