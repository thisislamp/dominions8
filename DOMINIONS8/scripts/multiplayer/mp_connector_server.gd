class_name MpServer extends MpConnector

var max_clients: int = 2

## The id of the client who is running the host, or 0 if there is none, e.g. a
## local server.
var host_client_id: int = 0


signal player_connected(id: int)
signal player_disconnected(id: int)


func _init(_max_clients: int = 0, _port: int = DEFAULT_PORT) -> void:
	_log = _make_logger("MpServer")
	port = _port
	if _max_clients:
		max_clients = _max_clients

func _ready() -> void:
	name = "MpServer"
	super()
	add_to_group("mp_server")

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func start() -> int:
	_log.info("Creating server on port %s with max clients %s" % [port, max_clients])

	var _peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, max_clients)

	_log.err_cond_not_ok(err, "Could not create server on port %s" % port, false)
	if err == OK:
		peer = _peer
	#else:
		#_log.error("Server error: Error=%s" % err)
	return 0




# # # #
# Multiplayer events

# client and server
func _on_peer_connected(id: int):
	_log.info("Peer connected: %s" % id)
	player_connected.emit(id)

# client and server
func _on_peer_disconnected(id: int):
	_log.info("Peer disconnected: %s" % id)
	#_delete_player(id)
	player_disconnected.emit(id)

