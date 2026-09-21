extends Camera2D

@export var max_shake_offset := 32.0
@export var shake_decay := 0.7
# Zoom extra quando o player está parado (0.25 = 25% mais perto).
@export var idle_zoom_boost := 0.25
@export var zoom_smoothing := 3.0
# Look-ahead: quanto a câmera se adianta na direção do movimento (px) e a velocidade da transição.
@export var look_ahead_distance := 120.0
@export var look_ahead_smoothing := 2.5
# Dead zone: metade do tamanho (px) da caixa em que o player pode se mexer sem a câmera seguir.
@export var dead_zone_half_size := Vector2(60.0, 40.0)

var trauma := 0.0
var base_zoom := Vector2.ONE
var target_zoom_factor := 1.0

var player_position := Vector2.ZERO
var focus_position := Vector2.ZERO
var has_focus := false
var target_look_ahead := 0.0
var look_ahead := 0.0

func _ready() -> void:
	add_to_group("FollowPlayer")
	add_to_group("ScreenShake")
	add_to_group("CameraZoom")
	base_zoom = zoom
	target_zoom_factor = 1.0 + idle_zoom_boost

func _process(delta):
	_update_follow(delta)
	_update_zoom(delta)
	_update_shake(delta)

func updatePlayerPosition(currentPlayerPosition: Vector2):
	player_position = currentPlayerPosition
	if not has_focus:
		focus_position = currentPlayerPosition
		global_position = currentPlayerPosition
		has_focus = true

# Recebe a velocidade do player e a velocidade máxima dele.
# Zoom: 0 = parado (mais perto), 1 = velocidade máxima (zoom normal).
func updatePlayerMotion(player_velocity: Vector2, max_speed: float) -> void:
	var speed_ratio := clampf(player_velocity.length() / max_speed, 0.0, 1.0)
	target_zoom_factor = 1.0 + idle_zoom_boost * (1.0 - speed_ratio)
	target_look_ahead = clampf(player_velocity.x / max_speed, -1.0, 1.0) * look_ahead_distance

func _update_follow(delta: float) -> void:
	if not has_focus:
		return
	# Dead zone: o foco só anda quando o player encosta na borda da caixa.
	var diff := player_position - focus_position
	focus_position.x += diff.x - clampf(diff.x, -dead_zone_half_size.x, dead_zone_half_size.x)
	focus_position.y += diff.y - clampf(diff.y, -dead_zone_half_size.y, dead_zone_half_size.y)

	look_ahead = lerpf(look_ahead, target_look_ahead, clampf(look_ahead_smoothing * delta, 0.0, 1.0))
	global_position = focus_position + Vector2(look_ahead, 0.0)

func _update_zoom(delta: float) -> void:
	var current_factor := zoom.x / base_zoom.x
	var factor := lerpf(current_factor, target_zoom_factor, clampf(zoom_smoothing * delta, 0.0, 1.0))
	zoom = base_zoom * factor

# strength vai de 0 a 1; o tremor cresce de forma quadrática e decai sozinho.
func shake(strength: float) -> void:
	trauma = max(trauma, clampf(strength, 0.0, 1.0))

func _update_shake(delta: float) -> void:
	if trauma <= 0.0:
		offset = Vector2.ZERO
		return
	trauma = max(0.0, trauma - shake_decay * delta)
	var amount := max_shake_offset * trauma * trauma
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * amount
