class_name GameMap extends Node2D

# TODO: dont be an idiot and just store the teams in a fucking dict
var teams: Array[Team] = [Team.UNAFFILIATED]

# Debug options
var _debug_mps: int = 0
var _debug_navmap := false
var _debug_pathing := false
var _debug_hitbox := false
var _debug_collisions := false

@onready var tilemap: TileMap = $TileMap

func _init() -> void:
	add_to_group("map")
	register_team("AI", 0, Color.RED)

func _ready() -> void:
	var unit_node = Node2D.new()
	unit_node.name = 'units'
	add_child(unit_node)

## Creates and registers a new Team in the map's team registry and returns it.
func register_team(_name: String, id: int, color: Color) -> Team:
	if teams.any(func(t): return t.id == id):
		push_warning("Team with id %s already exists: %s" % [id, get_team(id)])

	var team = Team.new(_name, id, color)
	teams.append(team)
	return team

## Returns a registered Team by it's id, if it exists.
func get_team(id: int):
	var matches = teams.filter(func(t): return t.id == id)
	match matches.size():
		0: return null
		1: return matches.front()
		var n:
			push_warning("%s.teams has %s teams with id %s" % [self, n, id])
			return null

## Returns a registered Team by it's name, if it exists.
func get_team_by_name(_name: String):
	var matches = teams.filter(func(t): return t.name == _name)
	match matches.size():
		0: return null
		1: return matches.front()
		var n:
			push_warning("%s.teams has %s teams with name '%s'" % [self, n, _name])
			return null

## Removes a team by id from the team registry, if there is one.  Please don't
## call this on a team that still has units on it I don't want to think of the consequences.
func delete_team(id: int) -> void:
	var team = get_team(id)
	if team == Team.UNAFFILIATED:
		push_warning("Not deleting fallback team %s" % team)
	teams.erase(team)


func _unhandled_input(event: InputEvent) -> void:
	var vp := get_viewport()

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE when event.double_click:
				$camera.position = Vector2.ZERO
				vp.set_input_as_handled()

	elif event is InputEventMouseMotion:
		match event.button_mask:
			MOUSE_BUTTON_MASK_MIDDLE:
				var pos = $camera.position - event.relative
				var offset = 40 * 4 # tile_size * tile_count
				$camera.position = pos.clamp(Vector2(-offset, -offset), Vector2(offset, offset))
				vp.set_input_as_handled()


# TODO: move to some Debug singleton
func _unhandled_key_input(event: InputEvent):
	var vp := get_viewport()

	if event is InputEventKey:
		match event.keycode:
			# ? - Toggle control panel visibility
			KEY_SLASH when event.shift_pressed and event.pressed and not event.echo:
				$controls_panel.visible = not $controls_panel.visible
				vp.set_input_as_handled()

			# F11 - Toggle combat log
			KEY_F11 when event.pressed and not event.echo:
				CombatLog.visible = not CombatLog.visible
				vp.set_input_as_handled()

			#
			# Debug controls
			#

			# F9 - Reload scene
			KEY_F9 when event.pressed and not event.echo:
				get_tree().reload_current_scene()
				vp.set_input_as_handled()

			# F2 - Show tilemap navmap
			KEY_F2 when event.pressed and not event.echo:
				if tilemap.navigation_visibility_mode == TileMap.VISIBILITY_MODE_FORCE_SHOW:
					tilemap.navigation_visibility_mode = TileMap.VISIBILITY_MODE_DEFAULT
					_debug_navmap = false
				else:
					tilemap.navigation_visibility_mode = TileMap.VISIBILITY_MODE_FORCE_SHOW
					_debug_navmap = true

				Console.print_console("Debug: show tilemap navmap = %s" % _debug_navmap)
				vp.set_input_as_handled()

			# F3 - Show unit shapes
			KEY_F3 when event.pressed and not event.echo:
				_debug_hitbox = not _debug_hitbox
				_debug_collisions = not _debug_collisions

				toggle_collision_shape_visibility()
				Console.print_console("Debug: show unit hitboxes = %s" % _debug_hitbox)
				vp.set_input_as_handled()

			# F4 - Show unit pathing
			KEY_F4 when event.pressed and not event.echo:
				_debug_pathing = not _debug_pathing
				BaseUnit._debug_show_pathing = true

				for unit in get_tree().get_nodes_in_group("unit"):
					var nav: NavigationAgent2D = unit.get("nav")
					if nav is NavigationAgent2D:
						nav.debug_enabled = _debug_pathing
						nav.debug_path_custom_color = unit.team.color if unit.get('team') else Color.YELLOW

				Console.print_console("Debug: show unit paths = %s" % _debug_pathing)
				vp.set_input_as_handled()

			# F5 - Freespawn
			KEY_F5 when event.pressed and not event.echo:
				return
				#Console.print_console("Debug: mps = %s" % _debug_mps)
				#var nexus: OldNexus = $blue_nexus
				#if mps == 0 or nexus.mana_per_second == mps:
					#mps = nexus.mana_per_second
					#nexus.mana_per_second = 10000000
				#else:
					#var cur_mps = nexus.mana_per_second
					#nexus.mana_per_second = mps
					#nexus.current_mana = nexus.max_mana
					#mps = cur_mps




func toggle_collision_shape_visibility() -> void:
	var tree := get_tree()
	tree.debug_collisions_hint = not tree.debug_collisions_hint

	# Traverse tree to call queue_redraw on instances of
	# CollisionShape2D and CollisionPolygon2D.
	var node_stack: Array[Node] = [tree.get_root()]
	while not node_stack.is_empty():
		var node: Node = node_stack.pop_back()
		if is_instance_valid(node):
			if node is CollisionShape2D or node is CollisionPolygon2D:
				node.queue_redraw()
			node_stack.append_array(node.get_children())

class Team extends RefCounted:
	var name: String
	var id: int
	var color: Color

	static var UNAFFILIATED: Team = Team.new()

	static func _static_init() -> void:
		UNAFFILIATED.name = "[Unaffiliated]"
		UNAFFILIATED.id = -1
		UNAFFILIATED.color = Color.GRAY

	func _init(_name="null", _id=0, _color=Color.WHITE) -> void:
		name = _name
		id = _id
		color = _color

	func _to_string() -> String:
		return "<Team id=%s name=%s color=%s>" % [id, name, color]


