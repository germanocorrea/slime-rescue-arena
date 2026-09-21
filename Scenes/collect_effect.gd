extends Node2D

# Efeito de coleta: partículas douradas "explodem" de onde o minislime estava (uma por
# ponto ganho) e o "+N" em verde pula no meio da explosão. Com combo (x2 a x5) o
# multiplicador aparece ao lado, indo de verde a vermelho. Some sozinho no fim.
#
# Uso: CollectEffect.spawn(self, global_position, pontos, multiplicador)

const PARTICLES_TEXTURE = preload("res://assets/Particles/Golden_particles.png")
const PIXEL_FONT = preload("res://fonts/PressStart2P-Regular.ttf")

const PARTICLE_LIFETIME := 0.9
const MAX_PARTICLES := 40 # limite para combos altos não pesarem
const POINTS_FONT_SIZE := 32
const MULTIPLIER_FONT_SIZE := 36
const LABEL_GAP := 14.0 # espaço entre o "+N" e o "xM"
const LABEL_COLOR := Color(0.4, 1.0, 0.4)
const COMBO_MIN := 2 # menor multiplicador exibido
const COMBO_MAX := 5

var points := 1
var multiplier := 1

static func spawn(context: Node, world_position: Vector2, points_earned: int, combo_multiplier: int = 1) -> void:
	var effect = new()
	effect.points = points_earned
	effect.multiplier = combo_multiplier
	# Fica na raiz da cena (não no minislime, que é removido logo depois da coleta)
	var root: Node = context.get_tree().current_scene
	if root == null:
		root = context.get_tree().root
	root.add_child(effect)
	effect.global_position = world_position

func _ready() -> void:
	z_index = 10
	_add_particles()
	_add_points_label()

func _add_particles() -> void:
	# A spritesheet tem 3x2 quadros; o último está vazio, por isso o sorteio vai só até 0.83
	var material := CanvasItemMaterial.new()
	material.particles_animation = true
	material.particles_anim_h_frames = 3
	material.particles_anim_v_frames = 2
	material.particles_anim_loop = false

	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])

	var particles := CPUParticles2D.new()
	particles.texture = PARTICLES_TEXTURE
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.material = material
	particles.amount = clampi(points, 1, MAX_PARTICLES)
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = PARTICLE_LIFETIME
	particles.direction = Vector2.UP
	particles.spread = 160.0
	particles.initial_velocity_min = 180.0
	particles.initial_velocity_max = 380.0
	particles.gravity = Vector2(0, 700)
	particles.damping_min = 40.0
	particles.damping_max = 80.0
	particles.color_ramp = fade
	particles.anim_offset_max = 0.83
	add_child(particles)
	particles.emitting = true

# Verde no x2, passando por amarelo e laranja, até vermelho no x5
func _multiplier_color() -> Color:
	var t := clampf(float(multiplier - COMBO_MIN) / float(COMBO_MAX - COMBO_MIN), 0.0, 1.0)
	return Color.from_hsv(lerpf(0.33, 0.0, t), 0.8, 1.0)

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", PIXEL_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	label.add_theme_constant_override("outline_size", 8)
	return label

func _add_points_label() -> void:
	# O "+N" e o "xM" ficam num grupo só, centralizado no ponto da coleta, que pula junto
	var popup := Node2D.new()
	add_child(popup)

	var points_label := _make_label("+%d" % points, POINTS_FONT_SIZE, LABEL_COLOR)
	popup.add_child(points_label)
	var width := PIXEL_FONT.get_string_size(points_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, POINTS_FONT_SIZE).x

	if multiplier >= COMBO_MIN:
		var mult_label := _make_label("x%d" % mini(multiplier, COMBO_MAX), MULTIPLIER_FONT_SIZE, _multiplier_color())
		popup.add_child(mult_label)
		var mult_width := PIXEL_FONT.get_string_size(mult_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, MULTIPLIER_FONT_SIZE).x
		mult_label.position = Vector2(width + LABEL_GAP, -MULTIPLIER_FONT_SIZE / 2.0)
		width += LABEL_GAP + mult_width
	points_label.position = Vector2(0, -POINTS_FONT_SIZE / 2.0)

	# Centraliza o grupo inteiro na origem do popup
	for child in popup.get_children():
		child.position.x -= width / 2.0

	# Dois pulinhos e um fade; começa com um "pop" de escala
	var tween := create_tween()
	tween.tween_property(popup, "scale", Vector2.ONE, 0.25).from(Vector2(0.5, 0.5)) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "position:y", -100.0, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "position:y", -40.0, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(popup, "position:y", -75.0, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "position:y", -40.0, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(popup, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
