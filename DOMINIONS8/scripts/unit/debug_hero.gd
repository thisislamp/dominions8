extends BaseUnit

var force: float = 4000.0
var max_speed: float = 450.0
var friction: float = 25
var thrust: Vector2 = Vector2.ZERO
var screen_size

var team_color = ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	var m = get_map()
	if m:
		var t = m.register_team("Debug", 9000, Color.MAGENTA)
		set_team(t)

func _physics_process(delta: float) -> void:
	var _next_path := nav.get_next_path_position()

	#velocity = Utils.apply_thrust(velocity, thrust.normalized(), force, delta).limit_length(max_speed)
	if thrust.is_equal_approx(Vector2.ZERO):
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
	else:
		velocity = velocity.lerp(thrust, friction * delta)

	#velocity = velocity.lerp(thrust, friction)
	velocity = velocity.limit_length(max_speed)

	move_and_slide()
	#move_and_collide(velocity * delta)
	position = position.clamp(Vector2.ZERO, screen_size)

func _process(_delta: float) -> void:
	if Engine.get_physics_frames() % 3 == 0:
		$label.text = "Velocity: %s\nSpeed:     %0.2f"  % [velocity, velocity.length()]


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		handle_input.call_deferred(event)

func handle_input(event: InputEventKey) -> void:
	if event.echo:
		return

	#print("-----------------------")
	#print("Got event: ", event)
	#print("Velocity before: ", velocity)

	var handled: bool = true

	match event.keycode:
		KEY_RIGHT:
			thrust.x += force if event.pressed else -force
			if event.pressed:
				($sprite as AnimatedSprite2D).play("right")
		KEY_LEFT:
			thrust.x += -force if event.pressed else force
			if event.pressed:
				($sprite as AnimatedSprite2D).play("left")
		KEY_DOWN:
			thrust.y += force if event.pressed else -force
			if event.pressed:
				($sprite as AnimatedSprite2D).play("down")
		KEY_UP:
			thrust.y += -force if event.pressed else force
			if event.pressed:
				($sprite as AnimatedSprite2D).play("up")
		KEY_SPACE when event.pressed:
			nav.target_position = get_viewport().get_mouse_position()
			print(self, ": nav target reachable: ", nav.is_target_reachable())
		_:
			handled = false

	# Make sure we dont get double inputs adding double the force
	thrust = thrust.clamp(Vector2(-force, -force), Vector2(force, force))

	if handled:
		get_viewport().set_input_as_handled()

	#print("Velocity is now", velocity)

