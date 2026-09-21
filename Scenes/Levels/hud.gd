extends CanvasLayer

const PIXEL_FONT := preload("res://fonts/PressStart2P-Regular.ttf")
const STAR_ON_TEXTURE := preload("res://assets/Star.png")
const STAR_OFF_TEXTURE := preload("res://assets/Star_off.png")

# Contagem regressiva
const MUSIC_SPEEDUP_TIME := 30.0 # a música acelera quando falta este tempo (s)
const MUSIC_SPEEDUP_PITCH := 1.15
const TIME_WARNING := 10.0 # o timer pisca em vermelho e cresce nos últimos segundos
const TIME_FONT_SIZE := 28
const TIME_WARNING_FONT_SIZE := 44
const TIME_NORMAL_COLOR := Color(1, 1, 1)
const TIME_WARNING_COLOR := Color(1.0, 0.2, 0.2)
const STAR_SIZE := Vector2(40, 40)

@onready var score_label: Label = $ScoreLabel

var score_panel: PanelContainer
var time_panel: PanelContainer
var time_label: Label
var timer: Timer
var time_left := 120.0
var music_sped_up := false
var star_thresholds: Array = []
var star_rects: Array[TextureRect] = []
var star_earned: Array[bool] = []
@onready var total_time := time_left

# Fração do tempo da fase que já passou (0 = começo, 1 = acabou).
func elapsed_ratio() -> float:
	return 1.0 - time_left / total_time

func _ready() -> void:
	setup_score_panel()
	setup_timer()
	update_score(0)

func make_hud_panel() -> PanelContainer:
	var panel := PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.15, 0.85)          # fundo escuro semi-transparente
	style.border_color = Color(0.55, 0.75, 1.0, 1.0)        # borda azul clara
	style.set_border_width_all(4)
	style.set_corner_radius_all(0)                          # cantos retos = mais "pixel art"
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)

	return panel

func style_pixel_label(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_override("font", PIXEL_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)

func setup_score_panel() -> void:

	score_panel = make_hud_panel()
	score_panel.name = "ScorePanel"
	score_panel.anchor_left = 0.0
	score_panel.anchor_top = 0.0
	score_panel.position = Vector2(20, 10)
	add_child(score_panel)

	# Placar em cima, estrelas da fase embaixo
	var score_box := VBoxContainer.new()
	score_box.add_theme_constant_override("separation", 10)
	score_panel.add_child(score_box)

	remove_child(score_label)
	score_box.add_child(score_label)

	score_label.anchor_right = 0.0
	score_label.anchor_bottom = 0.0
	score_label.offset_right = 0.0
	score_label.offset_bottom = 0.0
	style_pixel_label(score_label, 28, Color(1, 1, 1))

	setup_stars(score_box)

# As estrelas começam apagadas e acendem quando a pontuação atinge cada limite da fase.
func setup_stars(parent: Control) -> void:
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager and "current_star_thresholds" in game_manager:
		star_thresholds = game_manager.current_star_thresholds
	if star_thresholds.is_empty():
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	for i in star_thresholds.size():
		var star := TextureRect.new()
		star.texture = STAR_OFF_TEXTURE
		star.custom_minimum_size = STAR_SIZE
		star.pivot_offset = STAR_SIZE / 2.0
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(star)
		star_rects.append(star)
		star_earned.append(false)

func update_stars(score: int) -> void:
	for i in star_rects.size():
		var earned: bool = score >= star_thresholds[i]
		if earned == star_earned[i]:
			continue
		star_earned[i] = earned
		star_rects[i].texture = STAR_ON_TEXTURE if earned else STAR_OFF_TEXTURE
		if earned:
			var tween := create_tween()
			tween.tween_property(star_rects[i], "scale", Vector2.ONE, 0.4) \
				.from(Vector2(1.8, 1.8)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setup_timer() -> void:

	time_panel = make_hud_panel()
	time_panel.name = "TimePanel"
	time_panel.anchor_left = 1.0
	time_panel.anchor_top = 0.0
	time_panel.anchor_right = 1.0
	time_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	time_panel.position = Vector2(-20, 10)
	add_child(time_panel)

	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	style_pixel_label(time_label, TIME_FONT_SIZE, TIME_NORMAL_COLOR)
	time_panel.add_child(time_label)
	update_timer_display()

	timer = Timer.new()
	timer.one_shot = false
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

var current_score := 0
var displayed_score := 0
var score_tween: Tween

func update_score(new_score: int) -> void:
	var delta := new_score - current_score
	current_score = new_score
	update_stars(new_score)

	if delta != 0:
		show_score_popup(delta)

	if score_tween and score_tween.is_running():
		score_tween.kill()

	score_tween = create_tween()
	score_tween.tween_method(_set_displayed_score, displayed_score, new_score, 0.4) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)

func _set_displayed_score(value: float) -> void:
	displayed_score = int(round(value))
	score_label.text = "Score: " + str(displayed_score)

func show_score_popup(delta: int) -> void:
	var popup := Label.new()
	style_pixel_label(popup, 24, Color(1, 1, 1))

	if delta > 0:
		popup.text = "+" + str(delta)
		popup.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		popup.text = str(delta)
		popup.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	popup.position = score_panel.position + Vector2(score_panel.size.x + 20, 20)
	add_child(popup)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 40, 2.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 2.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(popup.queue_free)

func update_timer_display() -> void:
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	time_label.text = "Tempo %02d:%02d" % [minutes, seconds]

func _on_timer_timeout() -> void:
	if time_left > 0:
		time_left -= 1.0
		if time_left < 0:
			time_left = 0.0
		update_timer_display()
		update_countdown()
		if time_left == 0.0:
			timer.stop()
			get_tree().call_group("game_manager", "end_game", current_score)

# Faltando MUSIC_SPEEDUP_TIME a música acelera; faltando TIME_WARNING o timer cresce e pisca.
func update_countdown() -> void:
	if time_left <= MUSIC_SPEEDUP_TIME and not music_sped_up:
		music_sped_up = true
		var soundtrack := get_parent().get_node_or_null("soundtrack") as AudioStreamPlayer
		if soundtrack:
			create_tween().tween_property(soundtrack, "pitch_scale", MUSIC_SPEEDUP_PITCH, 1.5)

	if time_left <= TIME_WARNING and time_left > 0.0:
		time_label.add_theme_font_size_override("font_size", TIME_WARNING_FONT_SIZE)

func _process(_delta: float) -> void:
	if time_left > TIME_WARNING or time_left <= 0.0:
		return
	# Alterna entre vermelho e branco 4 vezes por segundo
	var red := int(Time.get_ticks_msec() / 250.0) % 2 == 0
	time_label.add_theme_color_override("font_color", TIME_WARNING_COLOR if red else TIME_NORMAL_COLOR)
