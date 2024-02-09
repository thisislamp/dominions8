class_name BaseWeapon extends Node2D

## The name of the weapon
@export var object_name: String

## Base damage of the weapon.
@export var damage: int

## Base range of the weapon.  0 means the unit's hitbox must collide with
## another to attack with it.
@export var attack_range: int

## Range at which the unit will begin to use this weapon.
## Try not to set this higher than the attack_range.
@export var aquisition_range: int

## Attack speed of the weapon.  This can also be interpreted as the cooldown
## or reload speed.
@export_range(0, 10, 0.01, "or_greater") var attack_speed: float = 1

## Determines if the weapon should take the unit's base attack time into
## account when calculating cooldown duration.
@export var ignore_unit_bat: bool = false

## Determines if the unit's bonus range is added to the weapon's effective range.
@export var ignore_unit_bonus_range: bool = false

## If the weapon is ready to be used, e.g. not on cooldown.
var ready_to_use: bool = true

## The time remaining on cooldown.
var cooldown: float

## The owner of the weapon.
var unit: BaseUnit

var weapon_range_area := Area2D.new()
var weapon_range_shape := CircleShape2D.new()

var enemies_in_range: Array[Node2D] = []

# Signals

## Called when a valid target enters the range of the weapon.
signal target_entered_area(target: BaseUnit)

## Called when a valid target exits the range of the weapon.
signal target_exited_area(target: BaseUnit)

## Called when a valid target is acquired for attacking.
signal target_changed(target: BaseUnit)

## Called when there are no longer any targets in attack range.
signal no_target_in_range()

## Called when the cooldown has completed.
signal cooldown_over()

# TODO: more events? on

func _ready() -> void:
	var _parent = get_parent()
	if _parent is BaseUnit:
		unit = _parent
	else:
		push_warning("weapon %s has no parent unit" % self)

	setup_range.call_deferred()

## Called to setup the weapon range aoe Area2D/shape.
func setup_range() -> void:
	var col_shape := CollisionShape2D.new()
	col_shape.shape = weapon_range_shape
	col_shape.debug_color = Color(Color.DARK_RED, 0.33)
	update_attack_range()

	weapon_range_area.area_shape_entered.connect(_on_enemy_hitbox_enter_range)
	weapon_range_area.area_shape_exited.connect(_on_enemy_hitbox_exit_range)
	weapon_range_area.collision_layer = 1 << 3
	weapon_range_area.collision_mask = 1 << 1
	weapon_range_area.name = name + "RangeArea"
	weapon_range_area.add_child(col_shape)
	add_child(weapon_range_area)

## Returns the GameMap node for this scene.
func get_map() -> GameMap:
	return get_tree().get_first_node_in_group("map")

## Called before the target is attacked.
func before_attack(target: BaseUnit) -> void:
	unit.movement_state = unit.MovementState.STANDING

## Attacks the target, rolling for damage, dealing it, then going on cooldown.
func attack(target: BaseUnit) -> void:
	# TODO: un-hack this
	if unit.sprite.sprite_frames.has_animation("attack"):
		unit.sprite.play("attack")

	var drn_challenge := DRN.challenge(damage, target.protection)
	CombatLog.log_attack(unit, target, self, drn_challenge)
	target.take_damage(drn_challenge.result)
	after_attack(target)

## Called after the target is attacked.
func after_attack(target: BaseUnit) -> void:
	start_cooldown()

## Uses the weapon in the target direction or target location.  Does nothing by default.
func use(target: Vector2) -> void:
	start_cooldown()

## Starts the weapon cooldown.  The cooldown will be asynchronously reset.
func start_cooldown() -> void:
	if attack_speed <= 0:
		return

	ready_to_use = false
	cooldown = attack_speed * unit.bat

## Instantly reset the weapon cooldown.
func reset_cooldown() -> void:
	cooldown = 0.0
	ready_to_use = true
	cooldown_over.emit()
	unit.movement_state = unit.MovementState.MOVING

## Updates the area shape's radius to the weapon's attack range.
func update_attack_range() -> void:
	weapon_range_shape.radius = attack_range
	if not ignore_unit_bonus_range:
		weapon_range_shape.radius += unit.bonus_attack_range

## Returns true IIF:[br]
## 0. (If the target is an Area2D named "hitbox", the target is set to the parent node)[br]
## 1. The target is a BaseUnit object.[br]
## 2. The target node is "alive". (see [method Utils.is_alive])[br]
## 3. The target is on a different team from the weapon's wielder.
func is_valid_target(target: Node2D) -> bool:
	if target is Area2D:
		if target.name != "hitbox":
			return false
		target = target.get_parent()

	if not target is BaseUnit:
		return false

	if not Utils.is_alive(target):
		return false

	if unit.team == target.team:
		return false

	return true

func is_in_range(target) -> bool:
	if not target:
		return false
	return Utils.is_alive(target) and target in enemies_in_range

## Gets, sets, and returns a target.
func acquire_target(retarget: bool = false) -> BaseUnit:
	if unit.current_target and not is_in_range(unit.current_target):
		unit.current_target = null

	if not retarget and unit.current_target:
		return

	var target := get_new_target()
	if target:
		set_unit_target(target)
	else:
		_on_no_target_in_range()
	return target

## Setter for unit.current_target
func set_unit_target(target: BaseUnit) -> void:
	unit.current_target = target
	_on_target_changed(target)

## Gets a new target in range and returns it, or null if there is none.
func get_new_target() -> BaseUnit:
	for enemy in enemies_in_range:
		if not enemy or not Utils.is_alive(enemy):
			_remove_enemy.call_deferred(enemy)
			continue
		# TODO: targeting priority selection (default closest probably)
		if is_valid_target(enemy):
			return enemy
	return null

## Removes an invalid entry from the enemies list.  Usually called deferred.
func _remove_enemy(item) -> void:
	if Utils.is_alive(item):
		enemies_in_range.erase(item)

# Internal events

## Called when a valid target enters the range of the weapon.
func _on_target_entered_area(target: BaseUnit) -> void:
	enemies_in_range.append(target)
	target_entered_area.emit(target)
	if not unit.current_target:
		set_unit_target(target)

## Called when a valid target exits the range of the weapon.
func _on_target_exited_area(target: BaseUnit) -> void:
	enemies_in_range.erase(target)
	target_exited_area.emit(target)
	if unit.current_target == target:
		acquire_target()
	if not unit.current_target and unit.movement_state == unit.MovementState.STANDING:
		unit.movement_state = unit.MovementState.MOVING

## Called when a valid target is acquired for attacking.
func _on_target_changed(target: BaseUnit) -> void:
	target_changed.emit(target)

## Called when there are no longer any targets in attack range.
func _on_no_target_in_range() -> void:
	no_target_in_range.emit()


func _physics_process(delta: float) -> void:
	if cooldown:
		cooldown -= delta
		if cooldown <= 0.0:
			reset_cooldown()

	if ready_to_use:
		if Utils.is_alive(unit) and Utils.is_alive(unit.current_target):
			attack(unit.current_target)
		else:
			acquire_target()

func _on_enemy_hitbox_enter_range(area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if not is_valid_target(area):
		return
	_on_target_entered_area(area.get_parent())


func _on_enemy_hitbox_exit_range(area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if not is_valid_target(area):
		return
	_on_target_exited_area(area.get_parent())
