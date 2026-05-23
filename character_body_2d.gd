extends CharacterBody2D


const SPEED = 600.0
const JUMP_VELOCITY = -900.0
const BOUNCE_STRENGTH = 0.8


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
#
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	var tmp_velocity := velocity
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision:
			velocity = tmp_velocity.bounce(collision.get_normal()) * BOUNCE_STRENGTH
	
