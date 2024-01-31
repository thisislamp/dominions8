class_name BaseProjectile extends Node2D

## The base damage this projectile does
@export var damage: int = 1

## Pierce value of the projectile.  Could represent a number of units it
## passes through, or a pool of "health" the projectile has available to use.
## The usage of the value is implementation dependant.
@export var pierce: int = 0

## The weapon that shot this projectile
var weapon: BaseWeapon

## The color used to modulate the sprite of this projectile.
var color: Color = Color.WHITE:
	set(c):
		color = c
		$sprite.modulate(c)


## Hits the target, dealing damage if the target is a unit.
func hit(target: Node2D) -> void:
	if target is BaseUnit:
		hit_unit(target as BaseUnit)

	after_hit(target)

## Rolls for damage and deals it to the unit.
func hit_unit(target: BaseUnit) -> void:
	var damage_taken := DRN.roll_vs(damage, target.protection)
	target.take_damage(damage_taken)

## Called after the target hits and deals damage to the target.
func after_hit(target: Node2D) -> void:
	destroy()

## Destory the projectile.  Calls queue_free() by default.
func destroy() -> void:
	queue_free()


func _on_screen_exited() -> void:
	queue_free()


func _on_hitbox_area_entered(area: Area2D) -> void:
	var area_parent = area.get_parent()
	if area_parent is BaseUnit:
		hit(area_parent)
