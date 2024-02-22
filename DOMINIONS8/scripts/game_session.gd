class_name GameSession extends Node


# Player registry.  multiplayer.unique_id: int -> MpPlayerData
var players: Dictionary = {}

# Team registry.  id: int -> GameTeam
var teams: Dictionary = {}

var map: GameMap

var _map_scene: PackedScene
var _team_counter: int = 1
var _log := LogStream.new("GameSession")


signal player_data_update(uid: int, data: MpPlayerData)
signal team_update(tid: int, team: GameTeam)


func _init() -> void:
	name = "GameSession"
	add_to_group("game")


func _ready() -> void:
	_connect_signals()
	players[multiplayer.get_unique_id()] = get_own_player_data()
	create_team("Team 1", Color.RED)
	create_team("Team 2", Color.DEEP_SKY_BLUE)


func _connect_signals() -> void:
	MultiplayerManager.server_player_connected.connect(_on_server_player_connected)
	MultiplayerManager.server_player_disconnected.connect(_on_server_player_disconnected)
	MultiplayerManager.connected.connect(_on_connected)
	team_update.connect(_on_team_update)


# control functions

func start_game() -> void:
	_log.info("%s: Changing scene to %s" % [multiplayer.get_unique_id(), _map_scene])

	_change_scene()
	map.setup()

func stop():
	pass

func _change_scene() -> void:
	var tree := get_tree()
	tree.current_scene.queue_free()
	tree.current_scene = null

	map = _map_scene.instantiate()
	add_child(map)
	tree.current_scene = self


# map functions

func load_map_scene(map: PackedScene) -> void:
	if not map.can_instantiate():
		_log.error("Cannot instantiate map scene: ", map)
		return
	_map_scene = map

func load_map(path: String) -> void:
	var scene := load(path) as PackedScene
	if scene:
		load_map_scene(scene)
	else:
		_log.error("Cannot load path as scene: ", path)


# player functions

func get_own_player_data() -> MpPlayerData:
	if MultiplayerManager.is_dedicated():
		return null
	var data := MpPlayerData.new()
	data.name = "Host" if MultiplayerManager.is_host() else ("Player%s" % multiplayer.get_unique_id())
	data.id = multiplayer.get_unique_id()
	data.is_host = MultiplayerManager.is_host()
	return data

func get_player(uid: int) -> MpPlayerData:
	return players.get(uid)

func update_player(uid: int, new_data: Dictionary, emit: bool = true) -> void:
	var data: MpPlayerData = players.get(uid)
	if not new_data:
		delete_player(uid)
	elif data:
		data.update(new_data)
	else:
		players[uid] = MpPlayerData.from_dict(new_data)
	if emit:
		player_data_update.emit(uid, players.get(uid))

func delete_player(uid: int) -> void:
	players.erase(uid)


# team functions

## Creates a new team.  An id is automatically assigned if not specificed.
func create_team(_name: String, color: Color, id: int = -1) -> GameTeam:
	if get_team(id) and id != -1:
		push_error("Team id %s already exists" % id)
		return null
	elif id == -1:
		id = _team_counter
		_team_counter += 1

	var team := GameTeam.new(_name, color, id)
	teams[id] = team
	team_update.emit(id, team)
	return team

## Returns the team of a given id, if it exists.
func get_team(id: int) -> GameTeam:
	return teams.get(id)

## Returns the first team of a name, if it exists.
func get_team_by_name(_name: String) -> GameTeam:
	var matches = teams.values().filter(func(t): return t.name == _name)
	match matches.size():
		0: return null
		1: return matches.front()
		var n:
			push_warning("%s.teams has %s teams with name '%s'" % [self, n, _name])
			return null

## Returns an existing team based on a serialized team dict (by id), if it exists.
func get_team_from_dict(data: Dictionary) -> GameTeam:
	return get_team(data["id"]) if data.has("id") else null

## Updates a team with new data.  Can use either a serialized team Dictionary or a GameTeam object.
func update_team(id: int, new_data):
	if new_data is GameTeam:
		_log.err_cond_not_equal(id, new_data.id, "Team update id mismatch", false)
		teams[id] = new_data
		team_update.emit(id, new_data)
	elif new_data is Dictionary:
		_log.err_cond_not_equal(id, new_data.get("id"), "Team update id mismatch", false)
		teams[id] = GameTeam.from_dict(new_data)
		team_update.emit(id, teams[id])
	else:
		_log.warn("Invalid data to update team with: ", type_string(typeof(new_data)))

## Deletes a team, if it exists.
func delete_team(id: int) -> void:
	var team := get_team(id)
	if team == GameTeam.UNAFFILIATED:
		push_warning("Not deleting fallback team %s" % team)
	teams.erase(team)
	team_update.emit(id, null)





# RPC functions

## Called to send our data to the server
@rpc("any_peer", "call_remote", "reliable")
func rpc_update_player_data(uid: int, player_info: Dictionary) -> void:
	var rid := multiplayer.get_remote_sender_id()
	if uid != rid and rid != 1:
		_log.warn("Remote uid %s cannot update data for %s" % [rid, uid])
		return

	_log.info("%s: got player info for %s from  %s" % [multiplayer.get_unique_id(), uid, rid])
	update_player(uid, player_info)

## Called by the server to update everyone's player list
@rpc("authority", "call_remote", "reliable")
func rpc_player_list_update(datum: Dictionary) -> void:
	_log.info("%s: got player list update" % multiplayer.get_unique_id())
	for uid: int in datum.keys():
		update_player(uid, datum[uid])

## Called by the server to update a team for everyone
@rpc("authority", "call_remote", "reliable")
func rpc_team_update(team_id: int, team_data: Dictionary) -> void:
	if team_data.is_empty():
		_log.info("Deleting team %s" % team_id)
		delete_team(team_id)
	else:
		_log.info("Updating team data for team %s" % team_id)
		teams[team_id] = GameTeam.from_dict(team_data)


@rpc("authority", "call_local", "reliable")
func rpc_load_map(map: String):
	load_map(map)
	_log.info("%s: loaded map: %s" % [multiplayer.get_unique_id(), map])


@rpc("authority", "call_local", "reliable")
func rpc_start_game():
	_log.info("Starting game")
	start_game()



# event functions

# the server got a new connection, send them the player list
func _on_server_player_connected(uid: int) -> void:
	_log.info("[server] Sending player data to ", uid)
	var pdata := {}
	for pid in players.keys():
		pdata[pid] = players[pid].to_dict()

	rpc_player_list_update.rpc_id(uid, pdata)

# the server got a disconnect, tell everyone to remove their data
func _on_server_player_disconnected(uid: int) -> void:
	rpc_update_player_data.rpc(uid, {})

# client connected to the server, send our data to the server
func _on_connected() -> void:
	# update our own player info now that we're connected
	players[multiplayer.get_unique_id()] = get_own_player_data()

	_log.info("%s: Sending our data to the server" % multiplayer.get_unique_id())
	rpc_update_player_data.rpc(multiplayer.get_unique_id(), get_own_player_data().to_dict())

func _on_team_update(tid: int, team: GameTeam) -> void:
	if multiplayer.get_unique_id() == 1:
		rpc_team_update.rpc(tid, team.to_dict())
