extends Node


var connector: MpConnector

var address: String:
	get: return connector.address if connector else ""

var port: int:
	get: return connector.port if connector else 0

# For dedicated server game instances
var _server_instances: Dictionary = {}

var _log := LogStream.new("MpManager")


# mp signals
signal connected()
signal connection_failed()
signal server_disconnected()
signal player_connected(id: int)
signal player_disconnected(id: int)

# type specific signals
signal client_player_connected(id: int)
signal client_player_disconnected(id: int)
signal server_player_connected(id: int)
signal server_player_disconnected(id: int)

signal connection_update()
signal connection_shutdown(port: int)
signal rpc_request_response(request_type: int, request_id: int, ruid: int, response_data)

signal game_start(game_id: int)


func _ready() -> void:
	pass


func is_active() -> bool:
	return Utils.is_alive(connector) and connector is MpConnector

func is_server() -> bool:
	return connector is MpServer

func is_client() -> bool:
	return connector is MpClient

func is_host() -> bool:
	if not connector:
		return false
	if connector is MpLocalServer:
		return true
	#if connector is MpClient:
		#return connector.is_host
	return false

func is_dedicated() -> bool:
	# TODO: add a argv flag check or whatever it is
	return connector == null and _server_instances.size() > 0


func join_game(_address: String, _port: int) -> int:
	connector = MpClient.new(_address, _port)
	var session = start_session()
	get_tree().root.add_child(connector)
	_connect_client_signals()

	var err = connector.start()
	if err != OK:
		_log.warn("Failed to start client connector")
		shutdown()
		session.queue_free()

	connection_update.emit()
	return err

func host_game(max_players: int, _port: int) -> int:
	connector = MpLocalServer.new(max_players, _port)
	var session = start_session()
	get_tree().root.add_child(connector)
	_connect_server_signals()

	var err = connector.start()
	if err != OK:
		_log.warn("Failed to start server connector")
		shutdown()
		session.queue_free()

	connection_update.emit()
	return err

## Creates and returns a new MpServer node, or an int error code on failure.
func spawn_server(max_players: int, _port: int = 0):
	# TODO: move under MpServer and add root path
	var session = start_session()
	# TODO: give session a random id, maybe "host" uid?
	# TODO: check port usage in dict
	var server = MpServer.new(max_players, _port)
	var err = server.start()
	if err == OK:
		_server_instances[_port] = server
		return server
	return err

func shutdown(spawned: bool = false):
	if connector:
		connector.stop()
		connection_shutdown.emit(connector.port)
		connector.queue_free()
		connector = null
		connection_update.emit()
	if spawned:
		# TODO: kill servers in dict
		pass

func start_session(root: Node = null) -> GameSession:
	var session = GameSession.new()
	#session.name = "GameSession"
	if not root:
		root = get_tree().root
	root.add_child(session, true)
	return session

# TODO: https://www.somethinglikegames.de/en/blog/2023/network-tutorial-4-login-2/
func auth_cb() -> void:
	pass

func get_player_data(uid: int = 0) -> MpPlayerData:
	if uid == 0:
		pass
	return null


func request_start_game() -> void:
	# TODO: fix for dedicated servers
	var session := get_tree().get_first_node_in_group("game") as GameSession
	if not session:
		_log.warn("No game session, cannot start game")
		return

	session.rpc_load_map.rpc("res://scenes/maps/mp_test_map.tscn")
	await get_tree().create_timer(.1).timeout
	session.rpc_start_game.rpc()
	game_start.emit(session.game_id)



# signal connectors
func _connect_client_signals():
	connector.connected.connect(_on_connected)
	connector.connection_failed.connect(_on_connection_failed)
	connector.server_disconnected.connect(_on_server_disconnected)
	connector.player_connected.connect(_on_player_connected)
	connector.player_disconnected.connect(_on_player_disconnected)
	# client specific variants
	connector.player_connected.connect(_on_client_player_connected)
	connector.player_disconnected.connect(_on_client_player_disconnected)

func _connect_server_signals():
	connector.player_connected.connect(_on_player_connected)
	connector.player_disconnected.connect(_on_player_disconnected)
	# server specific variants
	connector.player_connected.connect(_on_server_player_connected)
	connector.player_disconnected.connect(_on_server_player_disconnected)

# signal emitters
func _on_connected() -> void:
	connected.emit()
	connection_update.emit()

func _on_connection_failed() -> void:
	connection_failed.emit()
	connection_update.emit()

func _on_server_disconnected() -> void:
	server_disconnected.emit()
	connection_update.emit()

func _on_player_connected(id: int) -> void:
	player_connected.emit(id)
	connection_update.emit()

func _on_player_disconnected(id: int) -> void:
	player_disconnected.emit(id)
	connection_update.emit()

# client specific signals
func _on_client_player_connected(id: int) -> void:
	client_player_connected.emit(id)
	connection_update.emit()

func _on_client_player_disconnected(id: int) -> void:
	client_player_disconnected.emit(id)
	connection_update.emit()

# server only signals
func _on_server_player_connected(id: int) -> void:
	server_player_connected.emit(id)
	connection_update.emit()

func _on_server_player_disconnected(id: int) -> void:
	server_player_disconnected.emit(id)
	connection_update.emit()
