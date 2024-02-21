class_name GameTeam extends RefCounted


var name: String
var id: int
var color: Color

static var UNAFFILIATED: GameTeam = GameTeam.new("[Unaffiliated]", Color.GRAY, -1)


func _init(_name: String = "null", _color: Color = Color.WHITE, _id: int = 0) -> void:
	name = _name
	color = _color
	id = _id

func _to_string() -> String:
	return "<GameTeam id=%s name=%s color=%s>" % [id, name, color]


func to_dict() -> Dictionary:
	return {
		"name": name,
		"color": color,
		"id": id,
	}

static func from_dict(data: Dictionary) -> GameTeam:
	return new(
		data["name"],
		data["color"],
		data["id"],
	)

