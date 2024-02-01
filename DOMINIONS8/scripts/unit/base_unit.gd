class_name BaseUnit extends CharacterBody2D

## The base maximum health of the unit.
@export var max_health: int = 10

## The base protection of the unit.
@export var protection: int = 1

## The base movement speed of the unit (in px?).
@export_range(0, 1000, 1, "or_greater") var move_speed: int = 100

## The base attack range of the unit.  This value can be modified by weapons.
@export_range(0, 1000, 1, "exp") var attack_range: int = 100

## The range at which the unit will lock onto a target and begin to attack it.
@export var aquisition_range: int = 100

## Base attack time, a coefficient to modify weapon attack speed.  Works the
## same way it does in Dota. [br]
## 1 = 100% (normal)[br]
## 2 = 50% (half speed)[br]
## 0.6 = 166% (2/3rds faster)
@export_range(0.01, 10, 0.01, "exp") var bat: float = 1.0

## How much it costs to spawn this unit.
@export_range(0, 1000, 1) var mana_cost: int = 100

@onready var current_health: int = max_health
var attack_cooldown: float = 0
var hurt_timer: int = 0
var lane: int  # temporary
var waypoints: Array = []
var destination: Vector2
var direction: Vector2:
	set(v):
		direction = v
		$sprite.scale.x = 1 if v.x < 0 else -1
var current_target: BaseUnit

# Team stuff
var team_number: int
var team_color: Color = Color.WHITE:
	set(c): $team_marker.color = c

# Node aliases
@onready var sprite: AnimatedSprite2D = $sprite
@onready var attack_origin: Marker2D = $attack_origin
@onready var health_bar: ProgressBar = $health_bar
@onready var nav: NavigationAgent2D = $nav
@onready var weapons: Array[BaseWeapon]:
	get: return $equipment/weapons.get_children() as Array[BaseWeapon]

## Emitted when a unit dies
signal unit_died(unit: BaseUnit)

## Sets the team number and color
func set_team(team: int, color: Color) -> void:
	remove_from_group("team_%s" % team)
	team_number = team
	team_color = color
	add_to_group("team_%s" % team)

## Returns the unit's current target, or chooses a new target and returns it
func get_target():
	if current_target and is_instance_valid(current_target) and not current_target.is_queued_for_deletion():
		return current_target
	return choose_target()

## Picks and returns a target within the attack range of the unit, or null if none found
func choose_target():
	pass

## Attacks a target with its first available weapon, if any.  Returns a bool
## value for whether or not an attack was made.
func attack(target: BaseUnit) -> bool:
	for weapon: BaseWeapon in weapons:
		if weapon.ready_to_use:
			weapon.attack(target)
			return true
	return false

## Attacks a target with a specific weapon
func attack_with(target: BaseUnit, weapon: BaseWeapon) -> void:
	assert(weapon in weapons, "weapon %s not in %s weapons?" % [weapon, self])
	weapon.attack(target)

## Uses the weapon without a unit target in a specific direction or ground target
func use_weapon(weapon: BaseWeapon, target: Vector2) -> void:
	assert(weapon in weapons, "weapon %s not in %s weapons?" % [weapon, self])
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
		flash_damage(Color.RED, 1 - current_health * 1.0 /max_health)
	else:
		flash_damage(Color.GRAY, 0.5)

## Flashes the unit a given color and strength for a duration.
func flash_damage(color: Color, intensity: float = 1, duration: float = 1) -> void:
	# TODO: this seems wrong, maybe I should scale saturation based on intensity
	sprite.self_modulate = Color(color, intensity)
	await get_tree().create_timer(duration, false).timeout
	sprite.self_modulate = Color.WHITE

## Kill the unit.  Emits [signal unit_died] and frees the object.
func die() -> void:
	unit_died.emit(self)
	queue_free()

func move(_delta: float):
	get_target()
	if not current_target:
		follow_waypoints()

	move_and_slide()

func follow_waypoints() -> void:
	if len(waypoints) == 0:
		return  # TODO: do something?

	nav.target_position = waypoints[0].global_position
	direction = (nav.get_next_path_position() - global_position).normalized()
	velocity = direction * move_speed

	if global_position.distance_to(nav.target_position) < 150:
		waypoints.pop_front()

func _ready():
	health_bar.value = current_health
	health_bar.max_value = max_health
	health_bar.visible = false

	if OS.is_debug_build():
		# sets spawning with pathfinding visible
		var map = get_tree().get_first_node_in_group("map")
		if map:
			nav.debug_enabled = map.nav_debug


func _physics_process(delta: float) -> void:
	move(delta)
