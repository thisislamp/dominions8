class_name MpClient extends MpBase

## If this client is the one running the server.  Can be in the same process,
## locally on the same computer or network, or authorized remotely.
var is_host: bool = false


signal connected
signal connection_failed
signal server_disconnected
signal player_connected(id: int)
signal player_disconnected(id: int)


func _init(_address: String = DEFAULT_ADDRESS, _port: int = DEFAULT_PORT) -> void:
	_log = LogStream.new("MpClient")
	address = _address
	port = _port

func _ready() -> void:
	name = "MpClient"
	super()
	add_to_group("mp_client")
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	# set multiplayerapi on self?


func start() -> int:
	var err = _create_client(get_address(), get_port())
	if err == OK:
		multiplayer.multiplayer_peer = peer
	else:
		_log.info("Connection error: Error=%s" % err)
	return err

func _create_client(_address: String, _port: int) -> int:
	_log.info("Connecting to %s:%s" % [_address, _port])

	var _peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(_address, _port)
	peer = _peer
	return err

func get_peer_wrapper():
	peer.get_peer(multiplayer.get_unique_id())

# # # #
# Multiplayer events

# client only
func _on_connected_to_server():
	_log.info("Connected to server")
	var pid = multiplayer.get_unique_id()
	var data := MultiplayerManager.get_player_data()
	players[pid] = data
	_register_player.rpc_id(1, data.to_dict())
	connected.emit()


# client only
func _on_connection_failed():
	_log.info("Could not connect to server")
	stop()
	connection_failed.emit()

# client and server
func _on_peer_connected(id: int):
	_log.info("Peer connected: %s" % id)
	# send our data to the newly connected peer
	_register_player.rpc_id(id, MultiplayerManager.get_player_data().to_dict())
	player_connected.emit(id)

# client and server
func _on_peer_disconnected(id: int):
	_log.info("Peer disconnected: %s" % id)
	players.erase(id)
	player_disconnected.emit(id)

# client only
func _on_server_disconnected():
	_log.info("Disconnected from server")
	stop()
	players.clear()
	server_disconnected.emit()
