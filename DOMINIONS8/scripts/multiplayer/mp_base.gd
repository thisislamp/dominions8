class_name MpBase extends Node

const DEFAULT_PORT: int = 54321
const LOCALHOST: String = "127.0.0.1"
const DEFAULT_ADDRESS: String = LOCALHOST

## The registery of players.  id:int -> player:MpPlayerData
var players: Dictionary = {}

## Alias for multiplayer.multiplayer_peer
var peer: ENetMultiplayerPeer:
	get: return multiplayer.multiplayer_peer if multiplayer else null
	set(v): multiplayer.multiplayer_peer = v

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
	get: return peer.get_unique_id()

var _log: LogStream


func _init() -> void:
	# I don't actually need this since it gets made in the subclasses
	_log = LogStream.new("Mp")

func _ready() -> void:
	setup_mp_api()


func setup_mp_api() -> void:
	var mpapi = MultiplayerAPI.create_default_interface()
	_log.info("Made new mpapi: %s" % mpapi)
	_log.info("Setting server mpapi path to %s" % get_path())
	get_tree().set_multiplayer(mpapi, get_path())

func is_active() -> bool:
	return multiplayer.has_multiplayer_peer() \
		and multiplayer.multiplayer_peer.get_connection_status() \
		and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer

func get_port() -> int:
	return DEFAULT_PORT

func set_port(p: int) -> void:
	if p not in range(65536):
		push_error("Invalid port number ", p)
	port = p

func get_address() -> String:
	if OS.is_debug_build():
		return LOCALHOST
	else:
		return DEFAULT_ADDRESS

func start() -> int:
	return -1

func stop() -> void:
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null



@rpc("any_peer", "reliable")
func _register_player(player_info: Dictionary) -> void:
	var pid = multiplayer.get_remote_sender_id()
	players[pid] = MpPlayerData.from_dict(player_info)
	# emit signal

func _delete_player(id: int) -> void:
	players.erase(id)

func _exit_tree() -> void:
	multiplayer.multiplayer_peer = null
