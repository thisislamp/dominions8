class_name BaseWeaponProjectile extends BaseWeapon

@export_range(0, 1000, 1) var projectile_speed: int = 500
@export_range(0, 10, 1, "or_greater") var pierce: int = 0

@onready var projectile: Node2D = $projectile

# I have no idea if this is going to work but I have my doubts
@onready var Self: PackedScene = load(scene_file_path)


func spawn_from_unit(source: BaseUnit) -> BaseWeaponProjectile:
	var proj: BaseWeaponProjectile = spawn()
	proj.projectile.rotation = source.rotation
	proj.projectile.global_position = source.attack_origin.global_position
	return proj

func spawn_from_node(origin: Node2D) -> BaseWeaponProjectile:
	var proj: BaseWeaponProjectile = spawn()
	return proj

func spawn() -> BaseWeaponProjectile:
	return Self.instantiate()

func _ready() -> void:
	super()
	add_to_group("projectile")

func set_color(color: Color) -> void:
	$projectile/sprite.modulate = color

## Deals damage to a target unit
func attack(target: BaseUnit) -> void:
	var damage_taken := DRN.roll_vs(damage, target.protection)
	target.take_damage(damage_taken)

## Returns if the projectile should hit a target node.  Should be overridden.
func affects_target(target: Node2D) -> bool:
	push_warning("%s.affects_target() is not overridden" % self)
	return true

## Interacts the projectile with a target
func hit_target(target: Node2D) -> void:
	if target is BaseUnit:
		attack(target)
	pierce_enemy(target)

## Calculates pierce for an enemy and destroys the projectile if exhausted
func pierce_enemy(enemy: Node2D, amount: int = 1) -> void:
	pierce -= amount
	if pierce <= 0:
		destroy()

## Destroys the projectile.
func destroy() -> void:
	queue_free()

func _on_screen_exited() -> void:
	queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if affects_target(area):
		hit_target(area)
