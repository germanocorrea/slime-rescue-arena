extends CharacterBody2D

const SkinSettings = preload("res://Scenes/Main/skin_settings.gd")
const CollectEffect = preload("res://Scenes/collect_effect.gd")
const GOLDEN_TRAIL_SCENE = preload("res://Scenes/GoldenTrail.tscn")

@export var default__max_speed = 600.0
@export var default__jump_velocity = -900.0
@export var default__bounce_strength = 0.8
@export var default__acceleration = 1200.0
@export var default__friction = 1450.0
@export var default__coyote_time = 0.15
@export var default__jump_buffer_time = 0.12
@export var default__jump_hold_time = 0.2
@export var default__air_control = 1.0
@export var default__turn_multiplier = 1.0
@export var default__jump_release_gravity = 1.0

var max_speed: float
var jump_velocity: float
var bounce_strength: float
var acceleration: float
var friction: float
var coyote_time: float
var jump_buffer_time: float
var jump_hold_time: float
var air_control: float
var turn_multiplier: float
var jump_release_gravity: float

const JUMP_INITIAL_FACTOR := 0.4
const JUMP_HOLD_BOOST := 3.0

# Velocidade de queda (px/s) a partir da qual o impacto treme a tela, e a
# velocidade em que o tremor chega ao máximo.
const SHAKE_MIN_IMPACT_SPEED := 700.0
const SHAKE_MAX_IMPACT_SPEED := 1800.0

const ACTION_LEFT := &"move_left"
const ACTION_RIGHT := &"move_right"
const ACTION_UP := &"move_up"
const ACTION_DOWN := &"move_down"

var bounce_cooldown := 0.0
var score := 0
var grounded_bone_count := 0

# Variação sutil dos sons: a cada vez, o tom e o volume mudam um pouquinho.
# random_pitch 1.08 = tom sorteado entre 1/1.08 e 1.08 do original (cerca de ±1,3 semitom).
const JUMP_RANDOM_PITCH := 1.08
const JUMP_RANDOM_VOLUME_DB := 1.5
const COLLECT_RANDOM_PITCH := 1.05 # pequeno, para não embaralhar os degraus do combo
# Cada nível de combo sobe o tom da coleta em N semitons (x5 = 12 semitons = uma oitava acima).
const COMBO_PITCH_SEMITONES := 3.0
const COLLECT_RANDOM_VOLUME_DB := 1.0

# Combo: coletar outro minislime em até COMBO_WINDOW segundos aumenta o multiplicador (máx. COMBO_MAX)
const COMBO_WINDOW := 3.0
const COMBO_MAX := 5
const RESPAWN_DELAY := 0.8 # tempo que o slime fica "morto" antes de renascer (s)
var combo := 0
var combo_time_left := 0.0

var skin_trail: CPUParticles2D # rastro da skin dourada (nulo nas outras skins)
var softbody_bones: Array[RigidBody2D] = []
var max_bone_distance := 0.0
var bone_return_distance := 0.0
const BONE_MAX_DISTANCE_FACTOR := 3.0
const BONE_RETURN_DISTANCE_FACTOR := 1.2

var coyote_cooldown := 0.0
var jump_time_left := 0.0
var jump_buffer_cooldown := 0.0

@onready var initial_position: Vector2 = global_position
var is_respawning := false

@onready var jumpSound := $jumpSound
@onready var deathSound := $deathSound
@onready var collectSound := $collectSound
@onready var collisionSound := $collisionSound
@onready var dustParticles := $DustParticles

func restar_properties() -> void:
	max_speed = default__max_speed
	jump_velocity = default__jump_velocity
	bounce_strength = default__bounce_strength
	acceleration = default__acceleration
	friction = default__friction
	coyote_time = default__coyote_time
	jump_buffer_time = default__jump_buffer_time
	jump_hold_time = default__jump_hold_time
	air_control = default__air_control
	turn_multiplier = default__turn_multiplier
	jump_release_gravity = default__jump_release_gravity

# Registra as ações de movimento aceitando setas e WASD (posição física da tecla).
static func _ensure_input_actions() -> void:
	var bindings := {
		ACTION_LEFT: [KEY_LEFT, KEY_A],
		ACTION_RIGHT: [KEY_RIGHT, KEY_D],
		ACTION_UP: [KEY_UP, KEY_W],
		ACTION_DOWN: [KEY_DOWN, KEY_S],
	}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _process(_delta: float) -> void:
	get_tree().call_group("FollowPlayer", "updatePlayerPosition", global_position)
	get_tree().call_group("CameraZoom", "updatePlayerMotion", velocity, max_speed)

# Troca o som do player por um AudioStreamRandomizer que toca o mesmo áudio com tom e volume
# levemente aleatórios. Assim, sons que se repetem muito não soam "de máquina".
func _add_sound_variation(player: AudioStreamPlayer, random_pitch: float, random_volume_db: float) -> void:
	var randomizer := AudioStreamRandomizer.new()
	randomizer.add_stream(-1, player.stream)
	randomizer.random_pitch = random_pitch
	randomizer.random_volume_offset_db = random_volume_db
	player.stream = randomizer

func _ready() -> void:
	_ensure_input_actions()
	_add_sound_variation(jumpSound, JUMP_RANDOM_PITCH, JUMP_RANDOM_VOLUME_DB)
	_add_sound_variation(collectSound, COLLECT_RANDOM_PITCH, COLLECT_RANDOM_VOLUME_DB)
	add_to_group("player")
	initial_position = global_position
	restar_properties()
	add_to_group("slime")

	# A skin dourada deixa um rastro de partículas
	if SkinSettings.get_selected() == SkinSettings.GOLDEN_SKIN:
		skin_trail = GOLDEN_TRAIL_SCENE.instantiate()
		add_child(skin_trail)

	var softbody = get_parent().get_node_or_null("SoftBody2D")
	if softbody:
		# Skin escolhida no menu. A malha do softbody já está pronta, só troca a imagem.
		softbody.texture = SkinSettings.slime_texture(SkinSettings.get_selected())
		for child in softbody.get_children():
			if child is RigidBody2D:
				softbody_bones.append(child)
				max_bone_distance = max(max_bone_distance, child.global_position.distance_to(global_position))
				child.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
				child.add_to_group("slime")

				child.contact_monitor = true
				child.max_contacts_reported = max(child.max_contacts_reported, 4)
				if not child.body_entered.is_connected(_on_softbody_bone_body_entered):
					child.body_entered.connect(_on_softbody_bone_body_entered)
				if not child.body_exited.is_connected(_on_softbody_bone_body_exited):
					child.body_exited.connect(_on_softbody_bone_body_exited)
		bone_return_distance = max_bone_distance * BONE_RETURN_DISTANCE_FACTOR
		max_bone_distance *= BONE_MAX_DISTANCE_FACTOR


func _is_killing_block(node: Node) -> bool:
	return node != null and (node.name.begins_with("Killing Block") or node.is_in_group("killing_block"))

func _is_terrain(node: Node) -> bool:
	return node != null and not node.is_in_group("slime") and not _is_killing_block(node)

func _on_softbody_bone_body_entered(body: Node) -> void:
	if _is_killing_block(body) and not is_respawning:
		death()
		return
	if _is_terrain(body):
		grounded_bone_count += 1

func _on_softbody_bone_body_exited(body: Node) -> void:
	if _is_terrain(body):
		grounded_bone_count = max(0, grounded_bone_count - 1)

func _physics_process(delta: float) -> void:
	if combo_time_left > 0.0:
		combo_time_left -= delta
	process_movement(delta)
	var before_slide_velocity := velocity
	move_and_slide()
	bounce_response(before_slide_velocity, delta)
	prevent_slime_stretching()
	update_dust_particles()
	if skin_trail:
		skin_trail.emitting = velocity.length() > 80.0

func update_dust_particles() -> void:
	var touching_ground := is_on_floor() or grounded_bone_count > 0
	dustParticles.emitting = touching_ground and abs(velocity.x) > 20.0

func prevent_slime_stretching() -> void:
	# Bones presos no terreno se esticam sem limite; se algum se afastar demais
	# do player, ele é trazido de volta para perto.
	for bone in softbody_bones:
		if not is_instance_valid(bone):
			continue
		var offset: Vector2 = bone.global_position - global_position
		if offset.length() <= max_bone_distance:
			continue
		bone.global_position = global_position + offset.limit_length(bone_return_distance)
		bone.linear_velocity = Vector2.ZERO
		bone.angular_velocity = 0.0

func get_custom_gravity() -> Vector2:
	var gravity_multiplier := 1.0
	if Input.is_action_pressed(ACTION_DOWN):
		gravity_multiplier = 2.0

	return get_gravity() * gravity_multiplier

func process_jump(delta: float) -> void:
	var jump_held := Input.is_action_pressed(ACTION_UP)
	if Input.is_action_just_pressed(ACTION_UP):
		jump_buffer_cooldown = jump_buffer_time
	elif jump_buffer_cooldown > 0.0:
		jump_buffer_cooldown -= delta

	if not is_on_floor():
		var gravity: Vector2 = get_custom_gravity()
		if jump_held and jump_time_left > 0.0:
			jump_time_left -= delta
			# Quanto mais tempo a seta fica pressionada, mais alto o pulo.
			velocity.y += jump_velocity * JUMP_HOLD_BOOST * delta
		else:
			jump_time_left = 0.0
			# Soltou a tecla durante a subida: corta o pulo mais rápido.
			if velocity.y < 0.0 and not jump_held:
				gravity *= jump_release_gravity
		velocity += gravity * delta

		if coyote_cooldown > 0.0:
			coyote_cooldown -= delta
	else:
		coyote_cooldown = coyote_time
		jump_time_left = 0.0

	if (jump_held or jump_buffer_cooldown > 0.0) and (is_on_floor() or coyote_cooldown > 0.0):
		velocity.y = jump_velocity * JUMP_INITIAL_FACTOR
		coyote_cooldown = 0.0
		jump_buffer_cooldown = 0.0
		jump_time_left = jump_hold_time
		jumpSound.play()

func add_score(amount: int) -> void:
	score = max(0, score + amount)
	get_tree().call_group("hud", "update_score", score)
	if score >= 500:
		get_tree().call_group("game_manager", "end_game", score)
	collectSound.play()

# Chamado pelos minislimes ao serem coletados: aplica o combo, soma os pontos e
# mostra o efeito de coleta na posição do minislime.
func collect(base_points: int, world_position: Vector2) -> void:
	combo = mini(combo + 1, COMBO_MAX) if combo_time_left > 0.0 else 1
	combo_time_left = COMBO_WINDOW
	var total := base_points * combo
	collectSound.pitch_scale = pow(2.0, COMBO_PITCH_SEMITONES * (combo - 1) / 12.0)
	add_score(total)
	CollectEffect.spawn(self, world_position, total, combo)

func respawn() -> void:

	# Calculate the score after penalty: lose 10% of current score (clamped at 0)
	var penalty = int(round(score * 0.1))
	var new_score = max(0, score - penalty)

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
	await get_tree().create_timer(RESPAWN_DELAY).timeout

	# Re-instantiate the slime character
	var character_scene = load("res://Scenes/Player/slime_character.tscn")
	var new_character = character_scene.instantiate()
	new_character.global_position = initial_position

	# Pass the clamped score to the new character's body
	var new_char_body = new_character.get_node("CharacterBody2D")
	new_char_body.score = new_score

	# O combo não zera ao morrer: continua com o multiplicador, e a janela de 3 s segue
	# correndo enquanto o slime estava morto
	new_char_body.combo = combo
	new_char_body.combo_time_left = maxf(0.0, combo_time_left - RESPAWN_DELAY)

	# Add the new character to the level scene (the grandparent)
	var level_root = slime_root.get_parent()
	level_root.add_child(new_character)

	# Force the HUD to update with the new score
	new_char_body.add_score(0)

	# Remove the old character completely from the game
	slime_root.queue_free()

func process_lateral_movement(delta: float) -> void:
	var direction := Input.get_axis(ACTION_LEFT, ACTION_RIGHT)
	var control := 1.0 if is_on_floor() else air_control
	if direction:
		var accel := acceleration * control
		# Inverter o sentido é mais rápido, para o slime responder de imediato.
		if signf(velocity.x) == -signf(direction):
			accel *= turn_multiplier
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
		get_tree().call_group("SlimeEyes", "updatePlayerDirection", direction)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func process_movement(delta: float) -> void:
	process_jump(delta)
	if bounce_cooldown > 0:
		bounce_cooldown -= delta
		return
	process_lateral_movement(delta)
	
func death() -> void:
	is_respawning = true
	deathSound.play()
	respawn()

func bounce_response(before_slide_velocity: Vector2, delta: float) -> void:
	var bounce_breaks := Input.is_action_pressed(ACTION_DOWN)

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if velocity.y <= -400:
			collisionSound.play()
		# print(velocity)
		if not collision:
			continue

		var collider = collision.get_collider()
		if _is_killing_block(collider) and not is_respawning:
			death()
			continue

		# Impacto no chão: quanto mais rápida a queda, mais forte o tremor.
		if collision.get_normal().y < -0.5 and before_slide_velocity.y > SHAKE_MIN_IMPACT_SPEED:
			var strength := inverse_lerp(SHAKE_MIN_IMPACT_SPEED, SHAKE_MAX_IMPACT_SPEED, before_slide_velocity.y)
			get_tree().call_group("ScreenShake", "shake", clampf(strength, 0.15, 1.0))

		velocity.x = move_toward(velocity.x, 0, friction * delta)

		if bounce_breaks:
			continue

		velocity = before_slide_velocity.bounce(collision.get_normal()) * bounce_strength

		if abs(collision.get_normal().x) > 0.5:
			bounce_cooldown = 0.2
			if abs(velocity.x) >= 400 or velocity.y >= 300:
				collisionSound.play()
			# print(velocity)
