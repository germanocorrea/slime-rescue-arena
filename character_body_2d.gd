extends CharacterBody2D


const SPEED = 600.0
const JUMP_VELOCITY = -900.0
const BOUNCE_STRENGTH = 0.8

func _physics_process(delta: float) -> void:
	process_movement(delta)
	var before_slide_velocity := velocity
	move_and_slide()
	bounce_response(before_slide_velocity)

func bounce_response(before_slide_velocity: Vector2) -> void:
	if Input.is_action_pressed("ui_down"):
		return

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if not collision:
			continue

		before_slide_velocity = before_slide_velocity.bounce(collision.get_normal()) * BOUNCE_STRENGTH
		var bounce_diff := before_slide_velocity.length() - velocity.length()
		if bounce_diff > 200:
			velocity = before_slide_velocity

func process_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
#
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if not is_on_floor():
		return

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
