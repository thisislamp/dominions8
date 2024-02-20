class_name MpConnector extends Node

const DEFAULT_PORT: int = 54321
const DEFAULT_ADDRESS: String = "0.0.0.0"
const LOCALHOST: String = "127.0.0.1"

## Alias for multiplayer.multiplayer_peer
var peer: ENetMultiplayerPeer:
	get:
		return multiplayer.multiplayer_peer if multiplayer else null
	set(v):
		peer = v
		multiplayer.multiplayer_peer = v

## The port that either the:
## - server is running on, or
## - client is connecting to the server on.
var port: int:
	get=get_port,
	set=set_port

## The address that either the:
## - server is running on, or
## - client is connecting to.
var address: String:
	get=get_address

## Returns the unique id of this peer
var uid: int:
	get: return multiplayer.get_unique_id()

var _log: LogStream



func _init() -> void:
	push_error("Use a subclass!!!")

func _ready() -> void:
	pass

func _exit_tree() -> void:
	multiplayer.multiplayer_peer = null


func _make_logger(_name: String) -> LogStream:
	return LogStream.new(_name)

func get_port() -> int:
	if port:
		return port
	return DEFAULT_PORT

func set_port(p: int) -> void:
	if p not in range(65536):
		push_error("Invalid port number ", p)
	port = p

func get_address() -> String:
	if address:
		return address
	if OS.is_debug_build():
		return LOCALHOST
	else:
		return DEFAULT_ADDRESS

func is_active() -> bool:
	return multiplayer.has_multiplayer_peer() \
		and multiplayer.multiplayer_peer.get_connection_status() \
		and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer

## Creates a new MultiplayerAPI and sets the path to this node.
func setup_mp_api() -> void:
	var mpapi = MultiplayerAPI.create_default_interface()
	_log.info("Made new mpapi: %s" % mpapi)
	_log.info("Setting server mpapi path to %s" % get_path())
	get_tree().set_multiplayer(mpapi, get_path())


## Starts the connection.  Should be overridden.
func start() -> int:
	return -1

## Closes the connection.
func stop() -> void:
	if peer:
		peer.close()
		peer = null


## Returns the ENetPacketPeer class for the given uid.
func get_packetpeer(_uid: int = 0) -> ENetPacketPeer:
	if _uid == 0:
		_uid = uid
	return peer.get_peer(_uid)


