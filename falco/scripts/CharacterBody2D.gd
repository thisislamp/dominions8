extends CharacterBody2D

var gravity = 980
@export var ground_speed : float = 500
@export var speed : float = 300.0
@export var jump_force : float = -475
@export var doublejump_force : float = -375
@export var air_speed : float = 300
@export var air_control: int = 11
var horizontal_input: float
var first_direction: String
var doublejump_ready: bool = false
var state: String




func _physics_process(delta):
	var move_left = Input.is_action_pressed("move_left")
	var move_right = Input.is_action_pressed("move_right")
	var horizontal_input = Input.get_axis("move_left", "move_right")
	var inherited_velocity: float
	###SOCD MESS
	if Input.is_action_pressed("move_left") and !Input.is_action_pressed("move_right"): 
		first_direction = "left"
	if Input.is_action_pressed("move_right") and !Input.is_action_pressed("move_left"): 
		first_direction = "right"
	if Input.is_action_pressed("move_right") && Input.is_action_pressed("move_left"):
		if first_direction == "left":
			horizontal_input = 1
		if first_direction == "right":
			horizontal_input = -1
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		velocity.x = speed * horizontal_input
	if Input.is_action_just_pressed("jump") and !is_on_floor() and doublejump_ready == true:
		velocity.y = doublejump_force
		velocity.x = speed * horizontal_input
		doublejump_ready = false
		$AnimatedSprite2D.play("jump")
	if is_on_floor() == true:
		$AnimatedSprite2D.play("run")
		doublejump_ready = true
		velocity.x = speed * horizontal_input
		if velocity.x > 0: scale.x = 1
		if velocity.x < 0: scale.x = -1
	else:
		velocity.y += gravity * delta
		velocity.x += horizontal_input * air_control
	print(velocity.x)
	velocity.x = clamp(velocity.x, -1 * speed - 15, speed + 15)
	move_and_slide()
	#print("inherited velocity is: ", inherited_velocity)
	print(horizontal_input)
	print(velocity.x)
