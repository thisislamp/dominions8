extends CharacterBody2D

@export var team_color: String

const speed = 300.0
var dir : Vector2

func _ready():
	add_to_group(team_color)

func _physics_process(_delta):
	velocity = dir * speed
	move_and_slide()


func _input(_event: InputEvent):
	dir.x = Input.get_axis("ui_left", "ui_right")
	dir.y = Input.get_axis("ui_up", "ui_down")
	dir = dir.normalized()
