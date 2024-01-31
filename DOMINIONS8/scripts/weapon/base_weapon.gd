class_name BaseWeapon extends Node

## Base damage of the weapon.
@export var damage: int

## Base range of the weapon.  0 means the unit's hitbox must collide with
## another to attack with it.
@export var attack_range: int

## Range at which the unit will begin to use this weapon.
## Try not to set this higher than [annotation Range].
@export var aquisition_range: int

## Attack speed of the weapon.  This can also be interpreted as the cooldown
## or reload speed.
@export var attack_speed: float = 1

### The speed of the actual attack, or 0 if melee.
#@export var projectile_speed: int = 0

### The hitbox of the attack.  Not used if attack directly targets a unit.
#@export var hitbox: Area2D

var ready_to_use: bool = true
var parent: BaseUnit


func attack(target: BaseUnit) -> void:
	var damage_taken := DRN.roll_vs(damage, target.protection)
	target.take_damage(damage_taken)
	start_cooldown()

func use(target: Vector2) -> void:
	push_warning("use() not implemented yet")

func start_cooldown() -> void:
	if attack_speed <= 0:
		return

	ready_to_use = false
	await get_tree().create_timer(attack_speed).timeout
	reset_cooldown.call_deferred()  # might be unnecessary to defer

func reset_cooldown() -> void:
	ready_to_use = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _parent = get_parent()
	if _parent is BaseUnit:
		parent = _parent
	else:
		push_warning("weapon %s has no parent unit" % self)
