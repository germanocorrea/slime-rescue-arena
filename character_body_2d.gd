extends CharacterBody2D


const MAX_SPEED = 600.0
const JUMP_VELOCITY = -900.0
const BOUNCE_STRENGTH = 0.8
const ACCELERATION = 1200.0
const FRICTION = 1450.0

var bounce_cooldown := 0.0
var score := 0

func _physics_process(delta: float) -> void:
	process_movement(delta)
	var before_slide_velocity := velocity
	move_and_slide()
	bounce_response(before_slide_velocity, delta)

func process_jump(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		score += 1
		get_tree().call_group("hud", "update_score", score)

func process_lateral_movement(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)

func process_movement(delta: float) -> void:
	process_jump(delta)
	if bounce_cooldown > 0:
		bounce_cooldown -= delta
		return
	process_lateral_movement(delta)

func bounce_response(before_slide_velocity: Vector2, delta: float) -> void:
	var bounce_breaks := Input.is_action_pressed("ui_down")

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if not collision:
			continue

		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

		if bounce_breaks:
			continue

		velocity = before_slide_velocity.bounce(collision.get_normal()) * BOUNCE_STRENGTH

		if abs(collision.get_normal().x) > 0.5:
			bounce_cooldown = 0.2
