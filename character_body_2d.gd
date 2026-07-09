extends CharacterBody2D

@export var default__max_speed = 600.0
@export var default__jump_velocity = -900.0
@export var default__bounce_strength = 0.8
@export var default__acceleration = 1200.0
@export var default__friction = 1450.0
@export var default__coyote_time = 0.25

var max_speed: float
var jump_velocity: float
var bounce_strength: float
var acceleration: float
var friction: float
var coyote_time: float

var bounce_cooldown := 0.0
var score := 0

var coyote_cooldown := 0.0
var jump_time_left := 0.0

@onready var initial_position: Vector2 = global_position
var is_respawning := false

func restar_properties() -> void:
	max_speed = default__max_speed
	jump_velocity = default__jump_velocity
	bounce_strength = default__bounce_strength
	acceleration = default__acceleration
	friction = default__friction
	coyote_time = default__coyote_time

func _process(_delta: float) -> void:
	get_tree().call_group("FollowPlayer", "updatePlayerPosition", global_position)

func _ready() -> void:
	add_to_group("player")
	initial_position = global_position
	restar_properties()
	add_to_group("slime")

	var softbody = get_parent().get_node_or_null("SoftBody2D")
	if softbody:
		for child in softbody.get_children():
			if child is RigidBody2D:
				child.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
				child.add_to_group("slime")

				child.contact_monitor = true
				child.max_contacts_reported = max(child.max_contacts_reported, 4)
				if not child.body_entered.is_connected(_on_softbody_bone_body_entered):
					child.body_entered.connect(_on_softbody_bone_body_entered)


func _is_killing_block(node: Node) -> bool:
	return node != null and (node.name.begins_with("Killing Block") or node.is_in_group("killing_block"))

func _on_softbody_bone_body_entered(body: Node) -> void:
	if _is_killing_block(body):
		respawn()

func _physics_process(delta: float) -> void:
	process_movement(delta)
	var before_slide_velocity := velocity
	move_and_slide()
	bounce_response(before_slide_velocity, delta)
	prevent_slime_stretching()

func prevent_slime_stretching() -> void:
	var softbody = get_parent().get_node_or_null("SoftBody2D")
	if softbody:
		for child in softbody.get_children():
			if child is RigidBody2D:
				if child.global_position.distance_to(global_position) > 120.0:
					child.global_transform.origin = global_position
					child.linear_velocity = Vector2.ZERO

func get_custom_gravity():
	var gravity_multiplier := 1.0
	if Input.is_action_pressed("ui_down"):
		gravity_multiplier = 2.0

	return get_gravity() * gravity_multiplier

func process_jump(delta: float) -> void:
	if not is_on_floor():
		velocity += get_custom_gravity() * delta

		if Input.is_action_pressed("ui_up") and jump_time_left > 0.0:
			jump_time_left -= delta
			# Compounding the total jump velocity over time!
			velocity.y += jump_velocity * 3.0 * delta
		else:
			jump_time_left = 0.0

		if coyote_cooldown > 0.0:
			coyote_cooldown -= delta
	else:
		coyote_cooldown = coyote_time
		jump_time_left = 0.0

	if Input.is_action_pressed("ui_up") and (is_on_floor() or coyote_cooldown > 0.0):
		velocity.y = jump_velocity * 0.4
		coyote_cooldown = 0.0
		jump_time_left = 0.2

func add_score(amount: int) -> void:
	score = max(0, score + amount)
	get_tree().call_group("hud", "update_score", score)
	if score >= 500:
		get_tree().call_group("game_manager", "end_game", score)

func respawn() -> void:
	if is_respawning:
		return
	is_respawning = true

	# Calculate the score after penalty (clamped at 0)
	var new_score = max(0, score - 2)

	# Make the character and softbody disappear
	var slime_root = get_parent()
	var softbody = slime_root.get_node_or_null("SoftBody2D")
	if softbody:
		softbody.visible = false
	visible = false

	# Stop updates on this node during transition
	set_physics_process(false)
	set_process(false)

	# Wait for 0.8 seconds (representing the disappeared/death duration)
	await get_tree().create_timer(0.8).timeout

	# Re-instantiate the slime character
	var character_scene = load("res://slime_character.tscn")
	var new_character = character_scene.instantiate()
	new_character.global_position = initial_position

	# Pass the clamped score to the new character's body
	var new_char_body = new_character.get_node("CharacterBody2D")
	new_char_body.score = new_score

	# Add the new character to the level scene (the grandparent)
	var level_root = slime_root.get_parent()
	level_root.add_child(new_character)

	# Force the HUD to update with the new score
	new_char_body.add_score(0)

	# Remove the old character completely from the game
	slime_root.queue_free()

func process_lateral_movement(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
		get_tree().call_group("SlimeEyes", "updatePlayerDirection", direction)

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
		if _is_killing_block(collider):
			respawn()
			continue

		velocity.x = move_toward(velocity.x, 0, friction * delta)

		if bounce_breaks:
			continue

		velocity = before_slide_velocity.bounce(collision.get_normal()) * bounce_strength

		if abs(collision.get_normal().x) > 0.5:
			bounce_cooldown = 0.2
