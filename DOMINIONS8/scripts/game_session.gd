class_name GameSession extends Node


# Mapping of player mp uid to MpPlayerData
var players: Dictionary = {}

var teams: Dictionary = {}

var _log := LogStream.new("GameSession")


signal player_data_update(uid: int, data: MpPlayerData)


func _ready() -> void:
	_connect_signals()
	players[multiplayer.get_unique_id()] = get_own_player_data()
	_log.info("%s: set own player info as " % multiplayer.get_unique_id(), get_own_player_data())


func _connect_signals() -> void:
	MultiplayerManager.server_player_connected.connect(_on_server_player_connected)
	MultiplayerManager.server_player_disconnected.connect(_on_server_player_disconnected)
	MultiplayerManager.connected.connect(_on_connected)


# map functions
func load_map_scene(map: PackedScene) -> void:
	pass

func load_map(path: String) -> void:
	pass


# player functions
func get_own_player_data() -> MpPlayerData:
	if MultiplayerManager.is_dedicated():
		return null
	var data = MpPlayerData.new()
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

# TODO: port them over from map






# RPC functions

## Called to send our data to the server
@rpc("any_peer", "call_remote", "reliable")
func rpc_update_player_data(uid: int, player_info: Dictionary) -> void:
	var rid = multiplayer.get_remote_sender_id()
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

# event functions

# the server got a new connection, send them the player list
func _on_server_player_connected(uid: int) -> void:
	_log.info("[server] Sending player data to ", uid)
	var pdata = {}
	for pid: int in players.keys():
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
