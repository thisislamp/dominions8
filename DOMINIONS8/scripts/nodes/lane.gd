@tool
class_name LanePath extends Line2D


const endpoint = Vector2.INF

## The name of the lane, e.g. Top, Mid, Bot, Left, etc...
@export var lane_name: String:
	set(n):
		lane_name = n
		update_configuration_warnings()

## The radius of the waypoint trigger range.  A unit who's collision
## shape touches this radius will be considered to have reached this
## waypoint, and proceed
@export_range(0, 100, 1, "or_greater") var waypoint_radius: int = 40:
	set(r):
		waypoint_radius = r
		waypoint_shape.radius = r
		queue_redraw()

## A mapping of skip threshold overrides.  By default, any waypoint can be
## skipped.  Setting an override for a waypoint limits the distance from
## where it can be skipped.  For example, setting a skip threshold of 1
## on waypoint 4 means that a unit must be within 1 waypoint of waypoint
## 4, effectively making it unskippable.  Setting a threshold of 2 would
## make it so that the unit must reach waypoint 2 before it could possibly
## skip waypoint 3 to reach waypoint 4.
@export var skip_threshold: Dictionary = {}
# TODO: type check contents

var waypoint_area := Area2D.new()
var waypoint_shape := CircleShape2D.new()


func _init() -> void:
	if Engine.is_editor_hint():
		return

	waypoint_shape.radius = waypoint_radius
	# waypoint_area.connect("body_shape_entered", _on_body_shape_entered)
	waypoint_area.input_pickable = false
	waypoint_area.collision_layer = 1 << 6
	waypoint_area.collision_mask = 1

func _ready() -> void:
	if Engine.is_editor_hint():
		connect("tree_entered", _on_tree_entered)
		return

	assert(not lane_name.is_empty(), "Someone forgot to set a lane name")
	if not lane_name:
		lane_name = "<lane>"
	visible = false
	add_to_group("lane")
	add_collision_areas()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	for p: Vector2 in points:
		draw_arc(p, waypoint_radius, 0, TAU, 30, Color.BLUE, 1, true)

	# TODO: draw skip thresholds somehow


func _get_point(index: int, to_global: bool = true) -> Vector2:
	return points[index] + global_position if to_global else points[index]

## Returns the waypoint at a given index in the lane as a Vector2.  Unsafe.
func get_waypoint(index: int, reversed: bool) -> Vector2:
	return _get_point(-1 - index if reversed else index)
	#return points[-1 - index if reversed else index]

## Returns the first waypoint in a lane.
func get_first_waypoint(reversed: bool) -> Vector2:
	return _get_point(-1 if reversed else 0)
	#return points[-1 if reversed else 0]

## Returns the next waypoint after a given waypoint.
func get_next_waypoint(current: int, reversed: bool) -> Vector2:
	if current == -1:
		return get_first_waypoint(reversed)

	if not reversed:
		if current + 1 == points.size():
			return endpoint
		return _get_point(current + 1)
		#return points[current + 1]
	else:
		if current == points.size():
			return endpoint
		return _get_point(-1 - current)
		#return points[current - 1]

## Adds shapes to the waypoint
func add_collision_areas() -> void:
	for p: Vector2 in points:
		var col_shape := CollisionShape2D.new()
		col_shape.shape = waypoint_shape
		col_shape.position = p
		waypoint_area.add_child(col_shape)

	add_child(waypoint_area)


func _on_body_shape_entered(_area_rid: RID, node: Node2D, _area_shape_index: int, local_shape_index: int):
	if not node is BaseUnit:
		push_warning(self, ": non unit node ", node, " has entered waypoint ", local_shape_index)
		return

	var unit := node as BaseUnit

	push_warning(self, ": Unit ", unit, " has reached waypoint ", local_shape_index)

	if unit.lane and unit.lane != self:
		print("wrong lane dumbo go back %s" % unit.lane.lane_name)
		return

	unit.current_waypoint = local_shape_index + 1


func _on_tree_entered() -> void:
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	if not lane_name:
		return ["Set a lane name"]
	return []
