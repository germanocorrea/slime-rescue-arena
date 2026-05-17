extends RigidBody2D

var speed = 75.0
var jump_speed := -1000.0
#var gravity := 2500.0

var thrust = Vector2(0, -250)
var torque = 20000
var freio = 50001

var next_velocity = 0

func _ready() -> void:
	physics_material_override.bounce = 0.4
	physics_material_override.absorbent = false
	physics_material_override.friction = 0
	#lock_rotation = true # slimes nao rolam!
	contact_monitor = true
	max_contacts_reported = 8

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var on_floor: bool = false
	var on_wall: bool = false
	var on_ceiling: bool = false
	var i := 0

	while i < state.get_contact_count():
		var normal := state.get_contact_local_normal(i)
		on_floor = normal.dot(Vector2.UP) > 0.90 # 1
		on_wall = normal.dot(Vector2.UP) < 0.1 && normal.dot(Vector2.UP) >= 0 # 0
		on_ceiling = normal.dot(Vector2.UP) < -0.90 # -1
		i += 1
	
	var jump_factor = 0
	if  on_floor && Input.is_action_pressed("ui_up"):
		jump_factor = jump_speed
	elif on_floor && Input.is_action_pressed("ui_down"):
		if state.linear_velocity.y > 0:
			state.linear_velocity.y = min(state.linear_velocity.y + freio, 0)
		if state.linear_velocity.x > 0:
			state.linear_velocity.x = min(state.linear_velocity.x + freio, 0)
	
	var rotation_direction = 0
	if Input.is_action_pressed("ui_right"):
		rotation_direction += 1
	if Input.is_action_pressed("ui_left"):
		rotation_direction -= 1
	state.apply_central_impulse(Vector2(rotation_direction * speed, jump_factor))
