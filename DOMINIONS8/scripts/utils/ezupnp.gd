class_name EzUPNP extends RefCounted

var _upnp: UPNP
var _thread: Thread

var discovered: bool = false
var description: String = ""
var port_mappings := {}


signal discover_done(err: int)

func _init(desc: String = "") -> void:
	_upnp = UPNP.new()
	description = desc

func _cleanup(_err = 0):
	#print("5 - thread: ", OS.get_thread_caller_id())
	if _thread and _thread.is_alive():
		_thread.wait_to_finish()
		_thread = null

func _add_mapping(port: int, proto: String) -> void:
	var mapping: Array = port_mappings.get(port, [])
	if proto in mapping:
		push_warning("UPNP already mapped for %s:%s" % [port, proto])
		return
	port_mappings[port] = mapping + [proto]

func _delete_mapping(port: int, proto: String = "") -> void:
	var mapping: Array = port_mappings.get(port, [])
	mapping.erase(proto)
	port_mappings[port] = mapping


func discover():
	#print("2 - thread: ", OS.get_thread_caller_id())
	Console.log("Discovering UPNP devices")
	_thread = Thread.new()
	_thread.start(_discover)
	connect("discover_done", _cleanup, CONNECT_ONE_SHOT | CONNECT_REFERENCE_COUNTED)
	#print("2.5 - thread: ", OS.get_thread_caller_id())
	#await discover_done
	#_thread.wait_to_finish()
	#_cleanup()

func _discover():
	#print("3 - thread: ", OS.get_thread_caller_id())
	#print("[upnp] discovering devices")
	var err := _upnp.discover()
	#print("[upnp] discovery done, err code: ", err)

	if err != OK:
		push_error("UPNP discovery failed: ", str(err))

	Console.log("Found %s UPNP device(s)" % _upnp.get_device_count(), true, "", false)
	Console.log("Default gateway status: %s" % \
		["OK" if _upnp.get_gateway().igd_status == OK else _upnp.get_gateway().igd_status]
	)
	discovered = true
	emit_signal.call_deferred("discover_done", err)
	_cleanup.call_deferred()

func _wait_discovered():
	if not discovered:
		if not _thread:
			discover()
		await discover_done

func get_devices() -> Array[UPNPDevice]:
	var devices: Array[UPNPDevice] = []
	for n in _upnp.get_device_count():
		devices.append(_upnp.get_device(n))
	return devices

func get_gateway() -> UPNPDevice:
	return _upnp.get_gateway()

func get_ip() -> String:
	await _wait_discovered()
	return _upnp.query_external_address()

func is_usable() -> bool:
	return _upnp.get_gateway() and _upnp.get_gateway().is_valid_gateway()

func add_port_mapping(port: int, proto: String = "UDP", desc: String = "") -> int:
	var err = _upnp.add_port_mapping(port, port, desc if desc else description, proto)
	if err == OK:
		_add_mapping(port, proto)
	return err

func delete_port_mapping(port: int, proto: String) -> int:
	var err = _upnp.delete_port_mapping(port, proto)
	if err == OK:
		_delete_mapping(port, proto)
	return err

func shutdown() -> void:
	var _mapping = port_mappings.duplicate(true)
	for port in _mapping.keys():
		for proto in _mapping.get(port, []):
			delete_port_mapping(port, proto)
	port_mappings.clear()
