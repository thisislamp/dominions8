@tool
class_name DebugComponent2D extends BaseComponent2D

@export_multiline var text: String = ""
@export var properties: Array[String] = []
@export var offset: Vector2
#@export_range(1, 60, 1) var update_rate: int = 0

var label := Label.new()

func _init() -> void:
	connect("tree_entered", _on_tree_entered)
	label.name = "debug_label"

func _ready() -> void:
	add_child.call_deferred(label)
	set_deferred("position", offset)

func get_properties():
	var values = []
	for prop in properties:
		# TODO: parse function calls
		values.append(get_parent().get(prop))
	return values

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	label.text = text.format(get_properties())

func _on_tree_entered() -> void:
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	if not get_parent() is Node2D:
		return ["Parent must be a Node2D"]
	return []
