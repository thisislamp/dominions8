class_name BaseWeapon extends Node

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
@export var attack_speed: float = 1

## Determines if the weapon should take the wielder's base attack time into
## account when calculating cooldown duration.
@export var ignore_wielder_bat: bool = false

## If the weapon is ready to be used, e.g. not on cooldown.
var ready_to_use: bool = true

## The owner of the weapon.
var wielder: BaseUnit


## Attacks the target, rolling for damage, dealing it, then going on cooldown.
func attack(target: BaseUnit) -> void:
	var damage_taken := DRN.roll_vs(damage, target.protection)
	target.take_damage(damage_taken)
	start_cooldown()

func use(target: Vector2) -> void:
	push_warning("use() not implemented yet")

## Starts the weapon cooldown.  The cooldown will be asynchronously reset.
func start_cooldown() -> void:
	if attack_speed <= 0:
		return

	ready_to_use = false
	await get_tree().create_timer(attack_speed * wielder.bat).timeout
	ready_to_use = true
	# TODO: somehow cancel the reset if reset_cooldown() was called during the timeout

## Instantly reset the weapon cooldown.
func reset_cooldown() -> void:
	ready_to_use = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# weapons -> equipment -> Unit
	var _parent = get_parent().get_parent().get_parent()
	if _parent is BaseUnit:
		wielder = _parent
	else:
		push_warning("weapon %s has no parent unit" % self)
