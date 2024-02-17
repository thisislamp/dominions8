extends Panel

var delta_mod: int = 60

var status_name := {
	0: "Disconnected",
	1: "Connecting",
	2: "Connected"
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_labels()
	pass # Replace with function body.


func set_status(status: String) -> void:
	%StatusLabel.text = status

func set_ping(ping: int) -> void:
	%PingLabel.text = "%sms" % ping

func set_ping_str(ping: String) -> void:
	%PingLabel.text = ping



func check_mp_active():
	return MultiplayerManager.is_active()

func update_labels() -> void:
	if not check_mp_active():
		set_status("Disconnected")
		set_ping(0)
		return

	if MultiplayerManager.mp_server:
		var mps := MultiplayerManager.mp_server as MpServer
		set_status("Server (%s/%s)" % [mps.get_peer_count(), mps.max_clients])
		set_ping_str("local")

	elif MultiplayerManager.mp_client:
		var mpc := MultiplayerManager.mp_client as MpClient
		var status = mpc.peer.get_connection_status()
		set_status(status_name[status])

		var serverpeer = mpc.peer.get_peer(1)
		var rtt = serverpeer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
		set_ping(int(rtt))


	#if mpp.host.get_peers():
		#print((mpp as ENetMultiplayerPeer).host.get_peers())
		#var p = mpp.host.get_peers()[0] as ENetPacketPeer
		#print("rtt: ", p.get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME))
		#print("rttd: ", p.get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME_VARIANCE))

	#set_status(status_name[status])



func draw_ping():
	pass


func _process(delta: float) -> void:
	if Engine.get_physics_frames() % delta_mod != 0:
		return

	update_labels()
