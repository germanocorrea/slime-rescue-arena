extends CharacterBody2D


const SPEED = 600.0
const JUMP_VELOCITY = -900.0
const BOUNCE_STRENGTH = 0.8

var bounce_cooldown := 0.0

func _physics_process(delta: float) -> void:
	process_movement(delta)
	var before_slide_velocity := velocity
	move_and_slide()
	bounce_response(before_slide_velocity)

func is_just_enough_close_to_floor():
	return is_on_floor()

func process_jump(delta: float) -> void:
	if not is_just_enough_close_to_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_up") and is_just_enough_close_to_floor():
		velocity.y = JUMP_VELOCITY

func process_lateral_movement() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func process_movement(delta: float) -> void:
	process_jump(delta)
	if bounce_cooldown > 0:
		bounce_cooldown -= delta
		return
	process_lateral_movement()

func bounce_response(before_slide_velocity: Vector2) -> void:
	if Input.is_action_pressed("ui_down"):
		return

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if not collision:
			continue

		velocity = before_slide_velocity.bounce(collision.get_normal()) * BOUNCE_STRENGTH

		if abs(collision.get_normal().x) > 0.5:
			bounce_cooldown = 0.2
