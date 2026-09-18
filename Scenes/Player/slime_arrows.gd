extends Node2D

# Mostra uma seta ao redor do player para cada minislime vivo, apontando para ele.

const ARROW_TEXTURE = preload("res://assets/Arrow_blue.png")

@export var radius := 85.0 # distância das setas até o centro do player
@export var arrow_scale := 3.0
@export var pulse := 6.0 # quanto a seta vai e volta (px)
@export var pulse_speed := 4.0

var _arrows: Array[Sprite2D] = []

func _process(_delta: float) -> void:
	var targets: Array = get_tree().get_nodes_in_group("minislimes").filter(
		func(m): return not m.coletado)

	while _arrows.size() < targets.size():
		var arrow := Sprite2D.new()
		arrow.texture = ARROW_TEXTURE
		arrow.scale = Vector2.ONE * arrow_scale
		arrow.z_index = 5
		add_child(arrow)
		_arrows.append(arrow)
	while _arrows.size() > targets.size():
		_arrows.pop_back().queue_free()

	var t := Time.get_ticks_msec() / 1000.0 * pulse_speed
	for i in targets.size():
		var direction: Vector2 = (targets[i].global_position - global_position).normalized()
		var arrow := _arrows[i]
		arrow.global_position = global_position + direction * (radius + sin(t) * pulse)
		# O sprite aponta para cima, então gira 90° a mais que a direção
		arrow.global_rotation = direction.angle() + PI / 2.0
