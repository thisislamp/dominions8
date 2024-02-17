extends Node


## If multiplayer is active or not.
var active: bool = false:
	get=is_active

var mp_client: MpClient

var mp_server: MpServer

var multiplayer_client: MultiplayerAPI:
	get: return mp_client.multiplayer

var multiplayer_server: MultiplayerAPI:
	get: return mp_server.multiplayer

var _log := LogStream.new("MpManager")


signal server_player_connected(id: int)
signal server_player_disconnected(id: int)

signal client_connected()
signal client_connection_failed()
signal client_server_disconnected()
signal client_player_connected(id: int)
signal client_player_disconnected(id: int)


# ready
func _ready() -> void:
	pass


func is_active() -> bool:
	if mp_client:
		return mp_client.is_active()
	elif mp_server:
		return mp_server.is_active()
	return false

func is_server(uid: int = 0) -> bool:
	if uid == 0:
		return mp_server != null
	else:
		return uid == 1

func is_server_host(uid: int = 0) -> bool:
	if uid == 0:
		return mp_client.is_host
	else:
		return mp_client.peer.get_unique_id() == uid

## Shuts down all multiplayer connections.
func shutdown() -> void:
	if mp_client:
		_log.info("Shutting down mp client")
		mp_client.stop()
		mp_client.queue_free()
		mp_client = null

	if mp_server:
		_log.info("Shutting down mp server")
		mp_server.stop()
		mp_server.queue_free()
		mp_server = null

## Hosts a new game locally.
func host_game(port: int, max_players: int = 2) -> int:
	var server_node := MpServer.new(port, max_players)
	#server_node.name = "MpServer"
	mp_server = server_node
	get_node("/root").add_child(server_node)
	var err = server_node.start()
	#Log.err_cond_not_ok(err, "Error starting server", false)
	if err:
		push_error("Could not start server, ", error_string(err))
		return err
	_connect_server_signals()

	var client_node := MpClient.new(MpClient.LOCALHOST, port)
	#client_node.name = "InternalMpClient"
	mp_client = client_node
	get_node("/root").add_child(client_node)
	err = client_node.start()
	#Log.err_cond_not_ok(err, "Error joining local server", false)
	if err:
		push_error("Could not join local server, ", error_string(err))
		return err
	_connect_client_signals()

	client_node.is_host = true
	server_node.host_client_id = client_node.peer.get_unique_id()

	print("Current mp: ", multiplayer)
	print("Server mp:  ", server_node.multiplayer)
	print("Client mp:  ", client_node.multiplayer)
	print("Client mp peer: ", client_node.peer)
	print("Server mp peer: ", server_node.peer)

	return err

## Connects to a multiplayer game.
func join_game(address: String, port: int) -> int:
	var client_node := MpClient.new(address, port)
	mp_client = client_node
	get_node("/root").add_child(client_node)
	var err = client_node.start()
	#Log.err_cond_not_ok(err, "Error joining server: ", true)
	if err:
		push_error("Could not join game")
		return err
	_connect_client_signals()
	return err


func get_player_data() -> MpPlayerData:
	# TODO: do this properly
	var data = MpPlayerData.new()
	data.name = "Host" if mp_client.is_host else ("Player%s" % mp_client.uid)
	data.id = mp_client.uid
	data.is_host = mp_client.is_host if mp_client else false
	return data

func get_player(uid: int) -> MpPlayerData:
	if mp_client:
		return mp_client.players.get(uid)
	else:
		return mp_server.players.get(uid)

# server signals
func _connect_server_signals() -> void:
	mp_server.player_connected.connect(_on_server_player_connected)
	mp_server.player_disconnected.connect(_on_server_player_disconnected)

func _on_server_player_connected(id: int) -> void:
	server_player_connected.emit(id)

func _on_server_player_disconnected(id: int) -> void:
	server_player_disconnected.emit(id)

# client signals
func _connect_client_signals() -> void:
	mp_client.connected.connect(_on_client_connected)
	mp_client.connection_failed.connect(_on_client_connection_failed)
	mp_client.server_disconnected.connect(_on_client_server_disconnected)
	mp_client.player_connected.connect(_on_client_player_connected)
	mp_client.player_disconnected.connect(_on_client_player_disconnected)

func _on_client_connected() -> void:
	client_connected.emit()

func _on_client_connection_failed() -> void:
	client_connection_failed.emit()

func _on_client_server_disconnected() -> void:
	client_server_disconnected.emit()

func _on_client_player_connected(id: int) -> void:
	client_player_connected.emit(id)

func _on_client_player_disconnected(id: int) -> void:
	client_player_disconnected.emit(id)
