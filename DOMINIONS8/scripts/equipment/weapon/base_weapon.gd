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


func _ready() -> void:
	var _parent = get_parent()
	if _parent is BaseUnit:
		unit = _parent
	else:
		push_warning("weapon %s has no parent unit" % self)

	setup_range.call_deferred()

## Returns the GameMap node for this scene.
func get_map() -> GameMap:
	return get_tree().get_first_node_in_group("map")

## Attacks the target, rolling for damage, dealing it, then going on cooldown.
func attack(target: BaseUnit) -> void:
	# TODO: un-hack this
	if unit.sprite.sprite_frames.has_animation("attack"):
		unit.sprite.play("attack")

	var drn_challenge := DRN.challenge(damage, target.protection)
	CombatLog.log_attack(unit, target, self, drn_challenge)
	target.take_damage(drn_challenge.result)
	start_cooldown()

func use(target: Vector2) -> void:
	push_warning("use() not implemented yet")

## Starts the weapon cooldown.  The cooldown will be asynchronously reset.
func start_cooldown() -> void:
	if attack_speed <= 0:
		return

	ready_to_use = false
	cooldown = attack_speed * unit.bat

## Instantly reset the weapon cooldown.
func reset_cooldown() -> void:
	ready_to_use = true

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

func update_attack_range() -> void:
	weapon_range_shape.radius = attack_range
	if not ignore_unit_bonus_range:
		weapon_range_shape.radius += unit.bonus_attack_range

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

func set_unit_target(target: BaseUnit) -> void:
	unit.current_target = target

## Gets a new target in range and returns it, or null if there is none.
func get_new_target():
	for enemy in enemies_in_range:
		if not enemy or not Utils.is_alive(enemy):
			_remove_enemy.call_deferred(enemy)
			continue
		# TODO: targeting priority selection (default closest probably)
		if is_valid_target(enemy):
			return enemy

func _remove_enemy(item) -> void:
	if Utils.is_alive(item):
		enemies_in_range.erase(item)

func _physics_process(delta: float) -> void:
	if cooldown:
		cooldown -= delta
		if cooldown <= 0.0:
			cooldown = 0.0
			ready_to_use = true

	if ready_to_use:
		if Utils.is_alive(unit) and Utils.is_alive(unit.current_target):
			attack(unit.current_target)
		else:
			set_unit_target(get_new_target())

func _on_enemy_hitbox_enter_range(area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if not is_valid_target(area):
		return

	var target := area.get_parent() as BaseUnit
	enemies_in_range.append(target)
	if not unit.current_target:
		set_unit_target(target)

func _on_enemy_hitbox_exit_range(area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if not is_valid_target(area):
		return

	var target := area.get_parent() as BaseUnit
	enemies_in_range.erase(target)
	if unit.current_target == target:
		set_unit_target(get_new_target())
