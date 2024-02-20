extends Node2D

## How many frames to wait for an update.
@export_range(0.1, 10, 0.1, "or_greater") var update_rate: float = 1.0

@onready var pingline = %PingLine as Line2D

var _timer: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pingline.clear_points()
	print("NG: ", get_viewport_rect())

func check_ping() -> void:
	if not MultiplayerManager.is_active():
		return

	# TODO

	return
	if MultiplayerManager.peer:
		if multiplayer.is_server():
			pass
			#print("server: peer uid: ", MultiplayerManager.peer.get_peer(multiplayer.get_unique_id()))
		else:
			var serverpeer = MultiplayerManager.peer.get_peer(1)
			var rtt = serverpeer.get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME)
			#print("Client %s: ping=%s" % [multiplayer.get_unique_id(), rtt])
			#print("client: peer 1: ", MultiplayerManager.peer.get_peer(1))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_timer += delta
	if Engine.get_process_frames() % 2 != 0:
		return
	if _timer > update_rate:
		_timer -= update_rate
		check_ping()

