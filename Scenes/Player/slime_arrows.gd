extends Node2D

# Mostra uma seta ao redor do player para cada minislime vivo, apontando para ele.
# O slime dourado ganha uma seta dourada própria, um pouco mais afastada.

const SkinSettings = preload("res://Scenes/Main/skin_settings.gd")
const GOLD_ARROW_TEXTURE = preload("res://assets/Skins/Arrow_gold.png")

@export var radius := 85.0 # distância das setas até o centro do player
@export var gold_radius := 115.0
@export var arrow_scale := 4.0 # tamanho da seta quando o minislime está no tamanho normal
@export var pulse := 6.0 # quanto a seta vai e volta (px)
@export var pulse_speed := 4.0

var _arrow_texture: Texture2D # seta da skin escolhida
var _arrows: Array[Sprite2D] = []
var _gold_arrows: Array[Sprite2D] = []

func _ready() -> void:
	_arrow_texture = SkinSettings.arrow_texture(SkinSettings.get_selected())

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 * pulse_speed
	_update_arrows(_arrows, "minislimes", _arrow_texture, radius, 5, t)
	_update_arrows(_gold_arrows, "golden_minislime", GOLD_ARROW_TEXTURE, gold_radius, 6, t)

func _update_arrows(pool: Array[Sprite2D], group: StringName, texture: Texture2D,
		arrow_radius: float, z: int, t: float) -> void:
	var targets: Array = get_tree().get_nodes_in_group(group).filter(
		func(m): return not m.coletado)

	while pool.size() < targets.size():
		var arrow := Sprite2D.new()
		arrow.texture = texture
		arrow.scale = Vector2.ONE * arrow_scale
		arrow.z_index = z
		add_child(arrow)
		pool.append(arrow)
	while pool.size() > targets.size():
		pool.pop_back().queue_free()

	for i in targets.size():
		var direction: Vector2 = (targets[i].global_position - global_position).normalized()
		var arrow := pool[i]
		# A seta acompanha o tamanho do minislime: ele encolhe com o tempo, ela também.
		arrow.scale = Vector2.ONE * arrow_scale * targets[i].scale.x
		arrow.global_position = global_position + direction * (arrow_radius + sin(t) * pulse)
		# O sprite aponta para cima, então gira 90° a mais que a direção
		arrow.global_rotation = direction.angle() + PI / 2.0
