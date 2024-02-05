@tool
class_name SpawnPoint extends Marker2D

## The path this point spawns units for.
@export var lane: LanePath:
	set(l):
		lane = l
		update_configuration_warnings()

## If the units should follow the points in reverse order.  Usually set for the
## enemy nexus.
@export var reversed: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false

func _process(_delta: float):
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if lane == null or lane.points.size() == 0 or not Engine.is_editor_hint():
		return

	var node = lane.points[-1] if reversed else lane.points[0]
	draw_line(Vector2.ZERO, node - global_position, Color.GREEN, 2)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := []
	if lane == null:
		warnings.append("Needs a LanePath set to work")
	return warnings
