extends CharacterBody2D


const MAX_SPEED = 600.0
const JUMP_VELOCITY = -900.0
const BOUNCE_STRENGTH = 0.8
const ACCELERATION = 1200.0
const FRICTION = 1450.0

var bounce_cooldown := 0.0
var score := 0

@onready var initial_position: Vector2 = global_position
var is_respawning := false

func _physics_process(delta: float) -> void:
	process_movement(delta)
	var before_slide_velocity := velocity
	move_and_slide()
	bounce_response(before_slide_velocity, delta)

func get_custom_gravity():
	var gravity_multiplier := 1.0
	if Input.is_action_pressed("ui_down"):
		gravity_multiplier = 2.0

	return get_gravity() * gravity_multiplier

func process_jump(delta: float) -> void:
	if not is_on_floor():
		velocity += get_custom_gravity() * delta

	if Input.is_action_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func add_score(amount: int) -> void:
	score = max(0, score + amount)
	get_tree().call_group("hud", "update_score", score)
	if score >= 500:
		get_tree().call_group("game_manager", "end_game", score)

func respawn() -> void:
	if is_respawning:
		return
	is_respawning = true
	
	# Decrease 2 points
	add_score(-2)
	
	# Make the character and softbody disappear
	var softbody = get_parent().get_node_or_null("SoftBody2D")
	if softbody:
		softbody.visible = false
	visible = false
	set_physics_process(false)
	
	# Freeze all rigid body bones to stop physics simulation during transition
	if softbody:
		for child in softbody.get_children():
			if child is RigidBody2D:
				child.freeze = true
				child.linear_velocity = Vector2.ZERO
				child.angular_velocity = 0.0

	# Wait for 0.8 seconds to represent the disappearance duration
	await get_tree().create_timer(0.8).timeout
	
	# Calculate offset to teleport to initial position
	var offset = initial_position - global_position
	global_position = initial_position
	velocity = Vector2.ZERO
	
	# Teleport all softbody rigid body bones by the same offset and unfreeze them
	if softbody:
		for child in softbody.get_children():
			if child is RigidBody2D:
				child.global_position += offset
				child.freeze = false
				child.linear_velocity = Vector2.ZERO
				child.angular_velocity = 0.0

	# Make the character and softbody reappear
	if softbody:
		softbody.visible = true
	visible = true
	set_physics_process(true)
	
	is_respawning = false

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

		var collider = collision.get_collider()
		if collider and (collider.name.begins_with("Killing Block") or collider.is_in_group("killing_block")):
			respawn()
			continue

		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

		if bounce_breaks:
			continue

		velocity = before_slide_velocity.bounce(collision.get_normal()) * BOUNCE_STRENGTH

		if abs(collision.get_normal().x) > 0.5:
			bounce_cooldown = 0.2

