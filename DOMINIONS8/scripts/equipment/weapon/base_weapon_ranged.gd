class_name BaseWeaponRanged extends BaseWeapon

## The projectile scene to use
@export var projectile_scene: PackedScene

## Bonus damage applied to the projectile.
@export var bonus_damage: int = 0

## Bonus pierce value added to the fired projectile.
@export var bonus_pierce: int = 0

## Speed at which the fired projectile moves.
@export_range(0, 1000, 1) var projectile_speed: int = 500

## The color to modulate projectiles with.
var projectile_color: Color

@onready var projectile_origin: Marker2D = $sprite/projectile_origin

## Shoots at a unit and starts the weapon cooldown.
func attack(target: BaseUnit) -> void:
	fire_at(target)
	start_cooldown()

## Fires the weapon at this target, spawning a projectile and sending it at the
## coordinates of the target node.
func fire_at(target: Node2D) -> Node2D:
	var shot: BaseProjectile = spawn_projectile()

	projectile_origin.look_at(target.global_position)
	shot.global_position = projectile_origin.global_position
	shot.rotation = projectile_origin.rotation * randf_range(.95, 1.05)

	if projectile_color:
		shot.color = projectile_color

	var map = get_tree().get_first_node_in_group("map")
	if map:
		map.add_child(shot)
	else:
		push_warning("Shot fired with no map")
		add_child(shot)

	return shot

## Creates and returns a projectile instance.  Does not add it to the scene tree.
func spawn_projectile() -> BaseProjectile:
	var shot: BaseProjectile = projectile_scene.instantiate()
	shot.add_to_group("projectile")

	if projectile_color:
		shot.color = projectile_color

	return shot

func _ready() -> void:
	assert(projectile_scene != null, "No projectile loaded")
	super()
