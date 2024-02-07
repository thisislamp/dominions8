class_name BaseWeaponRanged extends BaseWeapon

## The projectile scene to use.  MUST be a BaseProjectile type.
@export var projectile_scene: PackedScene

## Bonus pierce value added to the fired projectile.
@export var bonus_pierce: int = 0

## Speed at which the fired projectile moves.
@export_range(0, 1000, 1) var projectile_speed: int = 100

## Overrides the unit's base projectile origin point.
@export var custom_projectile_origin: Marker2D

## The color to modulate projectiles with.
var projectile_color: Color


func _ready() -> void:
	assert(projectile_scene != null, "No projectile loaded")
	super()


func get_projectile_origin() -> Vector2:
	if custom_projectile_origin:
		return custom_projectile_origin.global_position
	return unit.get_node("%attack_origin").global_position


## Shoots at a unit and starts the weapon cooldown.
func attack(target: BaseUnit) -> void:
	unit.sprite.play(&"attack")
	fire_at(target)
	start_cooldown()

## Fires the weapon at this target, spawning a projectile and sending it at the
## coordinates of the target node.
func fire_at(target: Node2D) -> Node2D:
	if not Utils.is_alive(target):
		push_warning(self, " tried to fire on a dead node: ", target)
		return

	var shot := spawn_projectile()
	var origin := get_projectile_origin()
	var direction: Vector2

	if target is BaseUnit:
		direction = origin.direction_to(target.get_node("%hitbox_shape").global_position)
	else:
		direction = origin.direction_to(target.global_position)

	shot.global_position = origin
	shot.rotation = direction.angle() + deg_to_rad(90)  # * randf_range(.95, 1.05)
	shot.velocity = direction * projectile_speed
	shot.team = unit.team

	if projectile_color:
		shot.color = projectile_color

	var map := get_map()
	if map:
		map.add_child.call_deferred(shot)
	else:
		push_warning("Shot fired with no map")
		add_child.call_deferred(shot)

	return shot

## Creates and returns a projectile instance.  Does not add it to the scene tree.
func spawn_projectile() -> BaseProjectile:
	var shot: BaseProjectile = projectile_scene.instantiate() as BaseProjectile
	assert(shot is BaseProjectile)

	shot.weapon = self
	if projectile_color:
		shot.color = projectile_color

	shot.add_to_group("projectile")
	return shot

