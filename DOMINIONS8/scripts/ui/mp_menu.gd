extends PanelContainer


const DEFAULT_PORT := 54321

var internal_window: InternalWindow: set=set_internal_window
var upnp := EzUPNP.new()

var use_upnp: bool = false
var players_ready: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print(position, global_position, size)
	%MpModeVBox.visible = true
	%MpHostVBox.visible = false
	%MpHostVBox/MpHostStatusVBox.visible = false
	%MpJoinVBox/MpJoinStatusVbox.visible = false
	%MpHostVBox/MpHostStatusVBox/StartGameButton.visible = false
	%MpJoinVBox.visible = false
	%BackButton.visible = false
	#if not internal_window:
		#into_window.call_deferred()

	_connect_signals()
	#test_upnp()
	#%MpHostVBox/UPNPButton.disabled = true
	#use_upnp = await test_upnp()
	#%MpHostVBox/UPNPButton.button_pressed = use_upnp
	#%MpHostVBox/UPNPButton.disabled = not use_upnp

# TODO: remove this or change it to check if we're ready to start the game
func _exit_tree() -> void:
	if not players_ready:
		MultiplayerManager.shutdown()


func into_window() -> void:
	var root := get_node("/root")
	internal_window = InternalWindow.embed_into_window(self)
	root.add_child(internal_window)

func set_internal_window(window: InternalWindow) -> void:
	print(position, global_position, size)
	internal_window = window
	internal_window.title = "Multiplayer"
	internal_window.global_position = position
	internal_window.window_size = size

func test_upnp() -> bool:
	upnp.discover()
	await upnp.discover_done
	return upnp.is_usable()

func get_port() -> int:
	if %MpHostVBox.visible:
		return %MpHostVBox/PortHBox/PortSpinBox.value
	elif %MpJoinVBox.visible:
		return %MpJoinVBox/PortHBox/PortSpinBox.value
	return DEFAULT_PORT

func get_address() -> String:
	if %MpJoinVBox.visible and %MpJoinVBox/HostIPLineEdit.text:
		return %MpJoinVBox/HostIPLineEdit.text
	return "127.0.0.1"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and not event.echo and event.pressed:
			_on_back_button_pressed()
			# close server if needed, or confirm with user if active
			get_viewport().set_input_as_handled()

		if event.keycode == KEY_F1 and not event.echo and event.pressed:
			MultiplayerManager.mp_server.add_test_node()

		if event.keycode == KEY_F2 and not event.echo and event.pressed:
			var rpctestnode = MultiplayerManager.mp_client.get_node("rpctestnode")
			if rpctestnode:
				rpctestnode.rpc_test_console_print.rpc("f1 test")

func _on_back_button_pressed() -> void:
	%MpModeVBox.visible = true
	%MpJoinVBox.visible = false
	%MpHostVBox.visible = false
	%BackButton.visible = false
	MultiplayerManager.shutdown()
	MultiplayerManager.game_start.disconnect(_on_game_start)


func _on_host_button_pressed() -> void:
	%MpModeVBox.visible = false
	%MpHostVBox.visible = true
	%BackButton.visible = true
	MultiplayerManager.game_start.connect(_on_game_start)


func _on_join_button_pressed() -> void:
	%MpModeVBox.visible = false
	%MpJoinVBox.visible = true
	%BackButton.visible = true
	MultiplayerManager.game_start.connect(_on_game_start)


# Host menu callbacks

func _on_upnp_button_toggled(toggled_on: bool) -> void:
	use_upnp = toggled_on
	if toggled_on:
		var btn := %MpHostVBox/%UPNPButton as CheckButton
		btn.disabled = true
		queue_redraw()
		var usable = await test_upnp()
		btn.disabled = false
		if not usable:
			use_upnp = false
			btn.set_pressed_no_signal(false)
			%MpHostVBox/OpenServerButton.visible = true
	else:
		upnp.delete_port_mapping(get_port(), "UDP")
		upnp.delete_port_mapping(get_port(), "TCP")

func _on_open_server_button_pressed() -> void:
	var open_server_btn = %MpHostVBox/OpenServerButton as Button
	open_server_btn.disabled = true

	var port = get_port()
	var err

	if use_upnp:
		if not upnp.discovered:
			Console.log("Waiting for upnp")
			await upnp.discover_done

		Console.log("Adding upnp port mapping for port %s" % port)
		err = upnp.add_port_mapping(port, "UDP")
		if err != OK:
			push_error("Could not map UPNP on UDP port %s: %s" % [port, err])
		print("Mapped UPNP UDP port ", port)

		err = upnp.add_port_mapping(port, "TCP")
		if err != OK:
			push_error("Could not map UPNP on TCP port %s: %s" % [port, err])

	open_server_btn.disabled = false
	%MpHostVBox/MpHostStatusVBox.visible = true

	err = MultiplayerManager.host_game(1, port)
	if err:
		push_error("Could not create server: ", err)


func _on_copy_ip_button_pressed() -> void:
	if use_upnp and upnp.is_usable():
		DisplayServer.clipboard_set(await upnp.get_ip())
		var ip_btn = %MpHostVBox/MpHostStatusVBox/CopyIPButton as Button
		ip_btn.disabled = true
		ip_btn.text = "Copied"
		await get_tree().create_timer(2).timeout
		ip_btn.disabled = false
		ip_btn.text = "Copy IP Address"
	else:
		# ifconfig.me
		pass


# Join menu callbacks

func _on_join_game_button_pressed() -> void:
	%MpJoinVBox/MpJoinStatusVbox.visible = true
	%MpJoinVBox/JoinButton.disabled = true

	var err := MultiplayerManager.join_game(get_address(), get_port())
	if err:
		push_error("Could not create server: ", err)



func _on_game_start(game_id: int):
	Console.log("Closing mp window")
	internal_window.close_window()
	queue_free()

# Multiplayer events

func _connect_signals():
	MultiplayerManager.connected.connect(_on_connected_ok)
	MultiplayerManager.connection_failed.connect(_on_connected_fail)
	MultiplayerManager.server_disconnected.connect(_on_server_disconnected)
	MultiplayerManager.client_player_connected.connect(_on_client_player_connected)
	MultiplayerManager.client_player_disconnected.connect(_on_client_player_disconnected)

	MultiplayerManager.server_player_connected.connect(_on_server_player_connected)
	MultiplayerManager.server_player_disconnected.connect(_on_server_player_disconnected)

func _on_client_player_connected(id: int):
	%MpJoinVBox/MpJoinStatusVbox/NetStatusLabel.text = "Connected to server"

func _on_server_player_connected(id: int):
	%MpHostVBox/MpHostStatusVBox/NetStatusLabel.text = "Player connected"
	# TODO: change this to count total number of players or get player ready status
	players_ready = true
	%MpHostVBox/MpHostStatusVBox/StartGameButton.visible = true
	%MpHostVBox/MpHostStatusVBox/StartGameButton.disabled = false

func _on_client_player_disconnected(id: int):
	#%MpHostVBox/MpHostStatusVBox/NetStatusLabel.text = "Disconnected"
	players_ready = false

func _on_server_player_disconnected(id: int):
	%MpHostVBox/MpHostStatusVBox/NetStatusLabel.text = "Waiting for player..."
	pass

func _on_connected_ok():
	if not MultiplayerManager.is_server():
		%MpJoinVBox/JoinButton.disabled = false

func _on_connected_fail():
	if not MultiplayerManager.is_server():
		%MpJoinVBox/JoinButton.disabled = false

	%MpJoinVBox/MpJoinStatusVbox/NetStatusLabel.text = "Connection failed"

func _on_server_disconnected():
	%MpJoinVBox/MpJoinStatusVbox/NetStatusLabel.text = "Server disconnected"



func _on_start_game_button_pressed() -> void:
	Console.log("Requesting game start")
	MultiplayerManager.request_start_game()

