extends Node2D

const DUST_TEXTURE = preload("res://assets/poeiraAr.png")

@export var area := Rect2(0, 0, 1920, 1080)
@export var count := 50
@export var float_radius := 24.0 # how far a mote wanders around its home spot
@export var float_speed := 0.4 # wander speed (higher = faster)
@export var flee_radius := 200.0 # distance from the player that triggers the escape
@export var flee_smoothing := 7.0 # how fast a mote flees / comes back

var _motes: Array[Dictionary] = []
var _player: Node2D = null

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = DUST_TEXTURE
		sprite.scale = Vector2.ONE * rng.randf_range(3.0, 5.0)
		sprite.modulate.a = rng.randf_range(0.35, 0.8)
		add_child(sprite)
		var home := Vector2(
			rng.randf_range(area.position.x, area.end.x),
			rng.randf_range(area.position.y, area.end.y))
		sprite.position = home
		_motes.append({
			"sprite": sprite,
			"home": home,
			"phase": Vector2(rng.randf_range(0.0, TAU), rng.randf_range(0.0, TAU)),
			"freq": Vector2(rng.randf_range(0.7, 1.3), rng.randf_range(0.7, 1.3)),
			"radius": rng.randf_range(0.6, 1.0) * float_radius,
		})

func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	var t := Time.get_ticks_msec() / 1000.0 * float_speed
	var blend := 1.0 - exp(-flee_smoothing * delta)

	for mote in _motes:
		var sprite: Sprite2D = mote.sprite
		var phase: Vector2 = mote.phase
		var freq: Vector2 = mote.freq
		var target: Vector2 = mote.home + Vector2(
			sin(t * freq.x + phase.x),
			cos(t * freq.y + phase.y)) * mote.radius

		if _player:
			var away := target - _player.global_position
			if away.length() < flee_radius:
				# Stay on the edge of the circle around the player
				if away.is_zero_approx():
					away = Vector2.from_angle(phase.x)
				target = _player.global_position + away.normalized() * flee_radius

			# Fast player: never let the mote touch, even mid-transition
			var current := sprite.global_position - _player.global_position
			var min_distance := flee_radius * 0.6
			if current.length() < min_distance:
				if current.is_zero_approx():
					current = Vector2.from_angle(phase.x)
				sprite.global_position = _player.global_position + current.normalized() * min_distance

		sprite.global_position = sprite.global_position.lerp(target, blend)
