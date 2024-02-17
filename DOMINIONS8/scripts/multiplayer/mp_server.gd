class_name MpServer extends MpBase


var max_clients: int = 2

## The id of the client who is running the host, or 0 if there is none, e.g. a
## dedicated server.
var host_client_id: int = 0

signal player_connected(id: int)
signal player_disconnected(id: int)


func _init(_port: int = DEFAULT_PORT, _max_clients: int = 2) -> void:
	_log = LogStream.new("MpServer")
	port = _port
	max_clients = _max_clients

func _ready() -> void:
	name = "MpServer"
	super()
	add_to_group("mp_server")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


#func setup_mp_api() -> void:
	#var mpapi = MultiplayerAPI.create_default_interface()
	#_log.info("Made new mpapi: %s" % mpapi)
	#_log.info("Setting server mpapi path to %s" % get_path())
	#get_tree().set_multiplayer(mpapi, get_path())

func start() -> int:
	var err = _create_server(get_port(), max_clients)
	var mp = multiplayer
	_log.err_cond_not_ok(err, "Could not create server", false)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	#else:
		#_log.error("Server error: Error=%s" % err)
	return 0

func _create_server(port: int, max_clients: int) -> int:
	_log.info("Creating server on port %s with max clients %s" % [port, max_clients])

	var _peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, max_clients)
	peer = _peer
	return err

func get_peer_count() -> int:
	if not peer:
		return 0
	return peer.host.get_peers().size()

# # # #
# Multiplayer events

# client and server
func _on_peer_connected(id: int):
	_log.info("Peer connected: %s" % id)
	player_connected.emit(id)

# client and server
func _on_peer_disconnected(id: int):
	_log.info("Peer disconnected: %s" % id)
	_delete_player(id)
	player_disconnected.emit(id)
