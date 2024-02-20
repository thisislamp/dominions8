class_name MpLocalServer extends MpServer


func _init(_max_clients: int = 0, _port: int = DEFAULT_PORT) -> void:
	super(_max_clients, _port)

func _ready() -> void:
	super()


func _make_logger(_name: String) -> LogStream:
	return LogStream.new("MpLocalServer")

