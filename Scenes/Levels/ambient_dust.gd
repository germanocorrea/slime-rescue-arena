extends Node2D

const DUST_TEXTURES: Array[Texture2D] = [
	preload("res://assets/poeiraAr.png"),
	preload("res://assets/poeiraAr2.png"),
]
const ALT_TEXTURE_CHANCE := 0.3 # chance of using poeiraAr2.png

@export var area := Rect2(0, 0, 1920, 1080) # motes stay inside this rect
@export var count := 50
@export var drift_speed_min := 6.0 # slow free-floating speed (px/s)
@export var drift_speed_max := 18.0
@export var turn_rate := 0.8 # how much the drift direction wanders (rad/s)
@export var home_pull_speed := 10.0 # very slow pull back to where the mote started (px/s)
@export var home_pull_distance := 150.0 # pull reaches full strength this far from home
@export var flee_radius := 200.0 # distance from the player that triggers the escape
@export var flee_speed := 600.0 # push speed when the player is right on top of a mote
@export var flee_smoothing := 7.0 # how fast the escape starts / fades

var _motes: Array[Dictionary] = []
var _player: Node2D = null
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	for i in count:
		var sprite := Sprite2D.new()
		var alt := _rng.randf() < ALT_TEXTURE_CHANCE
		sprite.texture = DUST_TEXTURES[1 if alt else 0]
		sprite.scale = Vector2.ONE * _rng.randf_range(3.0, 5.0)
		sprite.modulate.a = _rng.randf_range(0.35, 0.8)
		sprite.position = Vector2(
			_rng.randf_range(area.position.x, area.end.x),
			_rng.randf_range(area.position.y, area.end.y))
		add_child(sprite)
		_motes.append({
			"sprite": sprite,
			"home": sprite.position,
			"angle": _rng.randf_range(0.0, TAU),
			"speed": _rng.randf_range(drift_speed_min, drift_speed_max),
			"flee_velocity": Vector2.ZERO,
		})

func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	var blend := 1.0 - exp(-flee_smoothing * delta)

	for mote in _motes:
		var sprite: Sprite2D = mote.sprite
		mote.angle += _rng.randf_range(-1.0, 1.0) * turn_rate * delta * 4.0
		var drift: Vector2 = Vector2.from_angle(mote.angle) * mote.speed

		# Gentle pull back home: none nearby, full strength when far away
		var to_home: Vector2 = mote.home - sprite.position
		var home_pull := to_home.normalized() * home_pull_speed * clampf(to_home.length() / home_pull_distance, 0.0, 1.0)

		var flee_target := Vector2.ZERO
		var offset := Vector2.ZERO
		if _player:
			offset = sprite.global_position - _player.global_position
			var distance := offset.length()
			if distance < flee_radius:
				if offset.is_zero_approx():
					offset = Vector2.from_angle(mote.angle)
				# Stronger push the closer the player is
				flee_target = offset.normalized() * flee_speed * (1.0 - distance / flee_radius)
		mote.flee_velocity = mote.flee_velocity.lerp(flee_target, blend)

		sprite.global_position += (drift + home_pull + mote.flee_velocity) * delta

		# Fast player: never let the mote touch, even mid-transition
		if _player:
			var min_distance := flee_radius * 0.6
			offset = sprite.global_position - _player.global_position
			if offset.length() < min_distance:
				if offset.is_zero_approx():
					offset = Vector2.from_angle(mote.angle)
				sprite.global_position = _player.global_position + offset.normalized() * min_distance

		# Bounce softly off the edges of the area
		var pos := sprite.position
		if pos.x < area.position.x or pos.x > area.end.x:
			mote.angle = PI - mote.angle
		if pos.y < area.position.y or pos.y > area.end.y:
			mote.angle = -mote.angle
		sprite.position = pos.clamp(area.position, area.end)
