@tool
class_name LaneNavigatorComponent extends BaseComponent


var nav: NavigationAgent2D:
	get: return unit.nav

## If the navigation component is active or not.  Disabling it will turn stop
## any pathfinding and movement activity.
var enabled: bool = false:
	set(v):
		enabled = v
		set_physics_process(v)

## The index of the current waypoint the unit is headed to.  Does not account
## for if the spawn point is reversed.
var current_waypoint: int = 1

## The lane the unit is assigned to.
var lane: LanePath:
	get:
		return unit.spawn_point.lane if unit.spawn_point else null

## If the unit follows the lane waypoints in reverse.
var reversed: bool:
	get:
		return unit.spawn_point.reversed if unit.spawn_point else false

var unit_velocity: Vector2 = Vector2.ZERO


func _init() -> void:
	set_physics_process(false)

func _ready() -> void:
	if Engine.is_editor_hint():
		connect("tree_entered", _on_tree_entered)
		return

	var col_area = unit.get_node("collision_shape") as CollisionShape2D
	if not col_area:
		push_error("Could not get unit collision shape")
		return

	_setup_nav.call_deferred()

func _setup_nav() -> void:
	if not unit.spawn_point:
		return

	await get_tree().physics_frame
	nav.avoidance_enabled = true
	nav.max_speed = unit.move_speed
	nav.connect("velocity_computed", _on_avoidance_velocity_computed)
	set_destination(lane.get_waypoint(current_waypoint, reversed))
	enabled = true
	unit.movement_state = unit.MovementState.MOVING

## Called when the unit has reached its current waypoint and gets a new one.
func update_waypoint(new_waypoint: int, position: Vector2) -> void:
	current_waypoint = new_waypoint
	nav.target_position = position

## Sets the target position of the nav agent.
func set_destination(position: Vector2) -> void:
	#print("Setting destination for ", unit, " to ", position)
	if position as Vector2:
		nav.target_position = position as Vector2
	else:
		nav.target_position = lane.get_waypoint(current_waypoint, reversed)

func get_next_waypoint() -> void:
	#print(unit, ": target reached")
	nav.target_position = lane.get_next_waypoint(current_waypoint, reversed)
	#print(unit, ": got next position: ", nav.target_position)
	current_waypoint += 1

	if nav.target_position == Vector2.INF:
		#print(unit, ": Lane traversed")
		enabled = false

func move(delta: float) -> void:
	unit.velocity = unit_velocity
	unit.move.call_deferred(delta)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not enabled:
		return

	if not nav.is_target_reachable():
		print(unit, ": unreachable target %s from position %s" % [nav.target_position, unit.global_position])
		pass
		return

	if nav.is_navigation_finished():
		#if not enabled:
			#print(unit, ": Current position: ", unit.global_position, ", target: ", nav.target_position)
			#print(self, ": Target position:  ", nav.target_position)
		#print(unit, ": nav done/enabled=(%s)" % enabled)
		#print(self, ": Getting out: enabled=%s, finished=%s" % [enabled, nav.is_navigation_finished()])
		get_next_waypoint()

	var next_pos := nav.get_next_path_position()
	var new_velocity := unit.global_position.direction_to(next_pos) * unit.move_speed
	#print(unit, ": got next path position: ", next_pos, ", velocity: ", new_velocity)

	if nav.avoidance_enabled:
		nav.velocity = new_velocity
	else:
		_on_avoidance_velocity_computed(new_velocity, delta)

func _on_avoidance_velocity_computed(safe_velocity: Vector2, delta: float=0.0):
	#print(self, ": got safe velocity: ", safe_velocity)
	unit_velocity = safe_velocity
	move(delta)

func _on_collision_area_entered(_area_rid: RID, node: Node2D, _area_shape_index: int, local_shape_index: int):
	var _lane := node as LanePath
	if not _lane:
		return

	if unit.lane and unit.lane != _lane:
		print("wrong lane dumbo go back %s" % unit.lane.lane_name)
		return

	unit.current_waypoint = local_shape_index
	#print("Set ", self, " waypoint to ", local_shape_index)


# Tool code
func _on_tree_entered() -> void:
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	if not unit is BaseUnit:
		return ["Parent node must be a BaseUnit type"]
	return []
