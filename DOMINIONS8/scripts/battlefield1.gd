extends Node2D

@onready var tilemap: TileMap = $TileMap

var mps: int = 0
var nav_debug: bool = false

func _ready() -> void:
	add_to_group("map")

func _unhandled_key_input(event: InputEvent):
	#print_debug("Got input event ", event)
	if event is InputEventKey:
		match event.keycode:
			# ? - Toggle control panel visibility
			KEY_SLASH when event.shift_pressed and event.pressed and not event.echo:
				$controls_panel.visible = not $controls_panel.visible

			# F9 - Reload scene
			KEY_F9 when event.pressed and not event.echo:
				get_tree().reload_current_scene()

			# F2 - Show tilemap navmap
			KEY_F2 when event.pressed and not event.echo:
				if tilemap.navigation_visibility_mode == TileMap.VISIBILITY_MODE_FORCE_SHOW:
					tilemap.navigation_visibility_mode = TileMap.VISIBILITY_MODE_DEFAULT
				else:
					tilemap.navigation_visibility_mode = TileMap.VISIBILITY_MODE_FORCE_SHOW

			# F3 - Show unit pathing
			KEY_F3 when event.pressed and not event.echo:
				nav_debug = not nav_debug
				var units = get_tree().get_nodes_in_group("unit")
				for unit in units:
					var nav: NavigationAgent2D = unit.get("nav")
					if nav is NavigationAgent2D:
						nav.debug_enabled = nav_debug
						nav.debug_path_custom_color = Color(unit.team_color)

			# F4 - Freespawn
			KEY_F4 when event.pressed and not event.echo:
				var nexus: UnitNexus = $blue_nexus
				if mps == 0 or nexus.mana_per_second == mps:
					mps = nexus.mana_per_second
					nexus.mana_per_second = 10000000
				else:
					var cur_mps = nexus.mana_per_second
					nexus.mana_per_second = mps
					nexus.current_mana = nexus.max_mana
					mps = cur_mps
