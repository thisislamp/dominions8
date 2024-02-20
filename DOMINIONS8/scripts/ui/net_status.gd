extends Panel

var update_rate: float = 1
var _timer: float = 0

var status_name := {
	0: "Disconnected",
	1: "Connecting",
	2: "Connected"
}

func _ready() -> void:
	update_labels()

	MultiplayerManager.server_disconnected.connect(_on_server_disconnected)
	MultiplayerManager.player_connected.connect(_on_player_connected)
	MultiplayerManager.connection_update.connect(update_labels)


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

	if MultiplayerManager.is_server():
		var con := MultiplayerManager.connector as MpLocalServer
		set_status("Server (%s/%s)" % [con.peer.host.get_peers().size(), con.max_clients])
		if con.peer.host.get_peers().size() == con.max_clients:
			var peers = con.peer.host.get_peers()
			var rtt = peers[0].get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
			set_ping(rtt)
		else:
			set_ping(0)

	elif MultiplayerManager.is_client():
		var con := MultiplayerManager.connector as MpClient
		var status = con.peer.get_connection_status()
		set_status(status_name[status])

		var serverpeer = con.get_packetpeer(1)
		var rtt = serverpeer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
		set_ping(rtt)


	#if mpp.host.get_peers():
		#print((mpp as ENetMultiplayerPeer).host.get_peers())
		#var p = mpp.host.get_peers()[0] as ENetPacketPeer
		#print("rtt: ", p.get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME))
		#print("rttd: ", p.get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME_VARIANCE))

	#set_status(status_name[status])



func draw_ping():
	pass


func _process(delta: float) -> void:
	_timer += delta
	if Engine.get_process_frames() % 2 != 0:
		return
	if _timer > update_rate:
		_timer -= update_rate
		update_labels()


func _on_server_disconnected():
	update_labels()
	set_process(false)

func _on_player_connected(id: int):
	set_process(true)
