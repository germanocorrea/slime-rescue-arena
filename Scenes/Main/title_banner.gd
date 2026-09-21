extends Control

# Título animado do menu principal: as letras ondulam, o slime do player (com a skin
# escolhida) pula de um lado, um minislime anima do outro e duas estrelas piscam em
# volta de "ARENA". Tudo é montado por código com sprites que o jogo já tem.

const PIXEL_FONT = preload("res://fonts/PressStart2P-Regular.ttf")
const SkinSettings = preload("res://Scenes/Main/skin_settings.gd")
const MINISLIME_SHEET = preload("res://assets/Minislimes/Minislime_anin3.png")
const STAR_TEXTURE = preload("res://assets/Star.png")

const BANNER_SIZE := Vector2(1300, 290)
const OUTLINE_COLOR := Color(0.04, 0.06, 0.1)

const WAVE_HEIGHT := 8.0 # quanto cada letra sobe e desce (px)
const WAVE_SPEED := 3.0
const WAVE_PHASE_STEP := 0.45 # defasagem entre letras vizinhas

const MINISLIME_FRAMES := 11 # spritesheet 4 colunas, quadros de 80x80
const MINISLIME_FPS := 8.0

var _time := 0.0
var _letters: Array[Dictionary] = [] # {"label", "base_y", "phase"}
var _skin_rect: TextureRect
var _minislime_rect: TextureRect
var _minislime_frame: AtlasTexture
var _stars: Array[TextureRect] = []

func _ready() -> void:
	custom_minimum_size = BANNER_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_add_line("SLIME RESCUE", 64, 12.0, _line1_colors("SLIME RESCUE"))
	var arena_x0 := _add_line("ARENA", 96, 100.0, _gold_colors(5))

	# Estrelas dos dois lados de "ARENA"
	var arena_width := 5 * 96.0
	_add_star(Vector2(arena_x0 - 110.0, 120.0), 0.0)
	_add_star(Vector2(arena_x0 + arena_width + 38.0, 120.0), PI)

	_skin_rect = _add_sprite(Vector2(40, 90), Vector2(170, 170))
	_skin_rect.pivot_offset = Vector2(85, 170) # gira/achata a partir do chão
	refresh_skin()

	_minislime_frame = AtlasTexture.new()
	_minislime_frame.atlas = MINISLIME_SHEET
	_minislime_frame.region = Rect2(0, 0, 80, 80)
	_minislime_rect = _add_sprite(Vector2(BANNER_SIZE.x - 40 - 170, 90), Vector2(170, 170))
	_minislime_rect.texture = _minislime_frame

# Mostra o slime com a skin escolhida no momento (chamado ao voltar para o menu).
func refresh_skin() -> void:
	_skin_rect.texture = SkinSettings.slime_texture(SkinSettings.get_selected())

func _add_sprite(pos: Vector2, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.position = pos
	rect.size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect

func _add_star(pos: Vector2, phase: float) -> void:
	var star := _add_sprite(pos, Vector2(80, 80))
	star.texture = STAR_TEXTURE
	star.pivot_offset = Vector2(40, 40)
	star.set_meta("phase", phase)
	_stars.append(star)

# Uma linha de letras (a fonte é monoespaçada, então cada letra ocupa `size` px).
# Retorna o x onde a linha começa.
func _add_line(text: String, size: int, y: float, colors: Array[Color]) -> float:
	var x0 := (BANNER_SIZE.x - text.length() * size) / 2.0
	for i in text.length():
		if text[i] == " ":
			continue
		var label := Label.new()
		label.text = text[i]
		label.position = Vector2(x0 + i * size, y)
		label.add_theme_font_override("font", PIXEL_FONT)
		label.add_theme_font_size_override("font_size", size)
		label.add_theme_color_override("font_color", colors[i])
		label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", 14)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		label.add_theme_constant_override("shadow_offset_y", 8)
		add_child(label)
		_letters.append({"label": label, "base_y": y, "phase": _letters.size() * WAVE_PHASE_STEP})
	return x0

# "SLIME" em verde e "RESCUE" em azul-ciano, como as cores do slime
func _line1_colors(text: String) -> Array[Color]:
	var colors: Array[Color] = []
	for i in text.length():
		colors.append(Color(0.4, 0.9, 0.5) if i < 5 else Color(0.45, 0.85, 1.0))
	return colors

func _gold_colors(count: int) -> Array[Color]:
	var colors: Array[Color] = []
	for i in count:
		colors.append(Color(1.0, 0.92, 0.45).lerp(Color(1.0, 0.7, 0.2), float(i) / (count - 1)))
	return colors

func _process(delta: float) -> void:
	_time += delta

	for letter in _letters:
		var label: Label = letter["label"]
		label.position.y = letter["base_y"] + sin(_time * WAVE_SPEED + letter["phase"]) * WAVE_HEIGHT

	# O slime do player pula e achata ao cair
	var hop := absf(sin(_time * 2.5))
	_skin_rect.position.y = 90.0 - hop * 34.0
	_skin_rect.scale = Vector2(1.0 + (1.0 - hop) * 0.08, 1.0 - (1.0 - hop) * 0.08)

	# O minislime alterna os quadros da animação e balança levemente
	var frame := int(_time * MINISLIME_FPS) % MINISLIME_FRAMES
	_minislime_frame.region = Rect2((frame % 4) * 80, floori(frame / 4.0) * 80, 80, 80)
	_minislime_rect.position.y = 90.0 + sin(_time * 3.0) * 6.0

	# As estrelas pulsam e balançam, uma defasada da outra
	for star in _stars:
		var phase: float = star.get_meta("phase")
		var pulse := 1.0 + 0.15 * sin(_time * 3.5 + phase)
		star.scale = Vector2(pulse, pulse)
		star.rotation = sin(_time * 2.0 + phase) * 0.12
