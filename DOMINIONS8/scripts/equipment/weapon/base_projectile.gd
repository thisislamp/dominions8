class_name BaseProjectile extends Area2D

## The base damage this projectile does
@export var damage: int = 1

## Pierce value of the projectile.  Could represent a number of units it
## passes through, or a pool of "health" the projectile has available to use.
## The usage of the value is implementation dependant.
@export var pierce: int = 0

## The weapon that shot this projectile
var weapon: BaseWeaponRanged

var team: GameMap.Team = GameMap.Team.UNAFFILIATED

var velocity: Vector2 = Vector2.ZERO


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

func is_valid_target(target: Node2D) -> bool:
	if not target is BaseUnit:
		return false

	if not Utils.is_alive(target):
		return false

	if team == target.team:
		return false

	return true

## Destory the projectile.  Calls queue_free() by default.
func destroy() -> void:
	queue_free()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func _on_screen_exited() -> void:
	queue_free()

func _on_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	#print(self, ": entered ", area, "\n  -> owned by ", area.get_parent())
	var target = area.get_parent()
	if is_valid_target(target):
		hit(target)
