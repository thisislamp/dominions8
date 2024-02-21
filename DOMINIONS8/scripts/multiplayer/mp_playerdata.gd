class_name MpPlayerData extends RefCounted

## The unique id of the player.
var id: int = 0

## The name of the player
var name: String = "Player"

## If this player is also the one hosting the game.  Does not mean that they
## are the same peer.
var is_host: bool = false

## The team id of the player.
var team_id: int = GameTeam.UNAFFILIATED.id

## Misc data
var extra_data: Dictionary = {}


static var _log := LogStream.new("MpPlayerData")

## Gets the GameTeam of the player.  Since teams are map specific you need the map
## to get the proper team.
func get_team(map: GameMap) -> GameTeam:
	return map.get_team(team_id)

## Updates the object with new info.  Extra fields will be stored in the
## extra_data property.
func update(data: Dictionary) -> void:
	for key in data.keys():
		_update(key, data[key])

func _update(key: String, value) -> void:
	if key in self and key != "extra_data":
		set(key, value)
	else:
		extra_data[key] = value

func _to_string() -> String:
	var val = "<%s:%s" % [name, id]
	if is_host:
		val += " [host]"
	val += " team=%s" % team_id
	val += ">"
	return val

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"is_host": is_host,
		"team_id": team_id,
		"data": extra_data
	}

static func from_dict(data: Dictionary) -> MpPlayerData:
	var mpdata = MpPlayerData.new()
	for key in data.keys():
		match key:
			"extra_data":
				mpdata.extra_data = data[key]
			_ when key in mpdata:
				mpdata.set(key, data[key])
			_:
				_log.debug("Ignoring extraneous key ", key)
	return mpdata
