class_name MpClient extends MpConnector


signal connected
signal connection_failed
signal server_disconnected
signal player_connected(id: int)
signal player_disconnected(id: int)


func _init(_address: String = DEFAULT_ADDRESS, _port: int = DEFAULT_PORT) -> void:
	_log = _make_logger("MpClient")
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


func get_address() -> String:
	if address:
		return address
	return LOCALHOST

## Connects to a server.
func start() -> int:
	var _addr = "%s:%s" % [address, port]
	_log.info("Connecting to ", _addr)

	var _peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(address, port)

	if err == OK:
		peer = _peer
		#_log.info("Connected to server")
	else:
		_log.warn("Could not connect to ", _addr)
	return err


# # # #
# Multiplayer events

# client only
func _on_connected_to_server():
	_log.info("Connected to server")
	connected.emit()

# client only
func _on_connection_failed():
	_log.info("Could not connect to server")
	stop()
	MultiplayerManager.shutdown()
	connection_failed.emit()

# client and server
func _on_peer_connected(id: int):
	_log.info("Peer connected: %s" % id)
	# send our data to the newly connected peer
	#rpc_register_player.rpc_id(id, MultiplayerManager.get_player_data().to_dict())
	player_connected.emit(id)

# client and server
func _on_peer_disconnected(id: int):
	_log.info("Peer disconnected: %s" % id)
	#players.erase(id)
	player_disconnected.emit(id)

# client only
func _on_server_disconnected():
	_log.info("Disconnected from server")
	stop()
	MultiplayerManager.shutdown()
	#players.clear()
	server_disconnected.emit()

