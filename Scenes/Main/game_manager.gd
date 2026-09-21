extends Node

const LevelProgress = preload("res://Scenes/Main/level_progress.gd")
const SkinSettings = preload("res://Scenes/Main/skin_settings.gd")
const AudioSettings = preload("res://Scenes/Main/audio_settings.gd")
const DisplaySettings = preload("res://Scenes/Main/display_settings.gd")
const TitleBanner = preload("res://Scenes/Main/title_banner.gd")
const CONFIG_ICON = preload("res://assets/Configuration.png")
const CONFIG_BUTTON_SIZE := Vector2(192, 192) # 2x o tamanho original do ícone (96 px)
const PIXEL_FONT = preload("res://fonts/PressStart2P-Regular.ttf")
const MINISLIME_SCENE = preload("res://Scenes/MiniSlime.tscn") # só para reaproveitar as animações
const CREDITS_PHOTO_1 = preload("res://assets/FotoCreditos1.jpeg")
const CREDITS_PHOTO_2 = preload("res://assets/FotoCreditos2.jpeg")
const CREDITS_EMAIL := "carlos.cunha002@edu.pucrs.br"
const MUSIC_ICON = preload("res://assets/MusicNote.png")
const MUSIC_PREVIEW = preload("res://audio/music/slime-rescue-arena-level-music-loopavel.ogg")
const STAR_ON_TEXTURE = preload("res://assets/Star.png")
const STAR_OFF_TEXTURE = preload("res://assets/Star_off.png")
const STAR_TEXTURE_SIZE := Vector2(144, 144)
# Minislime que aparece ao lado do botão sob o mouse (spritesheet 4 colunas, 11 quadros de 80x80).
const SELECTOR_TEXTURE = preload("res://assets/Minislimes/Minislime_anin3.png")
const SELECTOR_FRAME_COUNT := 11
const SELECTOR_FPS := 8.0
const SELECTOR_SCALE := 1.2
const SELECTOR_DISTANCE := 50.0 # do centro do minislime até a borda esquerda do botão (px)

# Frases do menu principal: uma é sorteada toda vez que o jogador entra na tela inicial.
const TAGLINES: Array[String] = [
	"Gotta rescue them all",
	"Bloing bloing bloing",
	"Doe mil milhões para o dev, que tal?",
	"Oi rsrs... o dev está solteiro",
	"Slimes são 90% gosma e 10% gosma nojenta",
	"Nenhum slime foi ferido... muito",
	"Pule com responsabilidade!",
	"Dica: espinhos machucam. Acredita?",
	"Feito com carinho, café e bugs",
	"Se o slime caiu, foi de propósito",
	"100% gosma orgânica, zero conservantes",
	"O maior record da fase 3 foi 214, boa sorte!",
	"Combo x5? Isso é que é talento!",
	"Insira uma moeda... ah, é de graça",
	"Alguém realmente lê isso?",
	"Tá difícil? Culpa do slime, não sua",
	"Sem glúten, com muita gosma",
	"Ninguém pula tão bem quanto uma gelatina",
	"1 a cada 10 slimes não recomendariam a sua pasta de dente",
]

# Abertura de fase: tela preta entra da direita, "carrega" e sai para a esquerda; depois, a contagem.
const LOADING_TOTAL := 5.0 # duração da tela de carregamento, contando as duas transições (s)
const WIPE_TIME := 0.6 # duração de cada transição da tela preta (s)
const COUNTDOWN_SECONDS := 3
const LOADING_ANIMATIONS: Array[StringName] = [&"action1", &"action2", &"action3"]

const STAR_COUNT := 3

# Fases da tela de seleção, na ordem em que aparecem. "stars" = pontuação mínima
# de cada estrela. A cena é carregada só quando a fase é aberta; se o arquivo
# ainda não existe, a fase aparece como "Em breve". "free" = modo livre (Playground):
# sem estrelas nem pontuação salva, mas as estrelas da tela de fim ainda usam "stars".
const LEVELS := [
	{"id": "level1", "name": "Fase 1", "path": "res://Scenes/Levels/level.tscn", "stars": [30, 55, 85]},
	{"id": "level2", "name": "Fase 2", "path": "res://Scenes/Levels/level2.tscn", "stars": [40, 70, 100]},
	{"id": "level3", "name": "Fase 3", "path": "res://Scenes/Levels/level3.tscn", "stars": [50, 85, 120]},
	{"id": "", "name": "Playground", "path": "res://Scenes/Levels/levelInitial.tscn", "stars": [30, 55, 85], "free": true},
]

var start_screen: CanvasLayer
var end_screen: CanvasLayer
var final_score_label: Label
var star_rects: Array[TextureRect] = []
var next_star_label: Label
var current_level_instance: Node = null
var current_scene_to_load: PackedScene = null
var current_star_thresholds: Array[int] = [30, 55, 85]
var current_level_id := "" # vazio = Playground (não salva progresso)
var level_select_screen: CanvasLayer
var skins_screen: CanvasLayer
var skins_tower: VBoxContainer
var settings_screen: CanvasLayer
var credits_screen: CanvasLayer
var title_banner: Control
var tagline_label: Label
var _last_tagline := ""

var transition_layer: CanvasLayer
var transition_rect: ColorRect # cortina preta que desliza
var loading_sprite: AnimatedSprite2D
var loading_label: Label
var countdown_label: Label
var transitioning := false # true durante a abertura da fase (bloqueia cliques e Esc)
var music_slider: HSlider
var music_value_label: Label
var music_preview: AudioStreamPlayer
var fullscreen_button: Button
var settings_from_end_screen := false # de onde a tela de configurações foi aberta
var skins_stars_label: Label
var selector_frames: SpriteFrames
var level_rows: VBoxContainer

func _ready() -> void:
	# Durante a abertura da fase o jogo (a fase) fica pausado, e só o GameManager continua rodando
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Add this node to the "game_manager" group
	add_to_group("game_manager")
	
	setup_start_screen()
	setup_end_screen()
	setup_level_select_screen()
	setup_skins_screen()
	setup_settings_screen()
	setup_credits_screen()
	setup_transition_layer()
	AudioSettings.apply() # aplica o volume da música salvo
	DisplaySettings.apply() # tela cheia (padrão) ou janela, conforme salvo
	
	# Show start screen first
	show_start_screen()

func setup_start_screen() -> void:
	start_screen = CanvasLayer.new()
	start_screen.layer = 10
	add_child(start_screen)
	
	# Root control for start screen
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen.add_child(control)
	
	# Premium dark/gradient background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 0.95) # Sleek dark blue-gray
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(bg)
	
	# Center container for UI elements
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(center)
	
	_add_settings_button(control, false)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	center.add_child(vbox)
	
	# Título animado (letras ondulando, slimes e estrelas)
	title_banner = TitleBanner.new()
	vbox.add_child(title_banner)
	
	# Frase aleatória (trocada em show_start_screen)
	tagline_label = Label.new()
	tagline_label.add_theme_font_size_override("font_size", 28)
	tagline_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8)) # Premium silver
	tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tagline_label)
	
	# Button Container (for styling / center alignment)
	var btn_center = CenterContainer.new()
	vbox.add_child(btn_center)
	
	# Iniciar Button
	var btn_iniciar = Button.new()
	btn_iniciar.text = "Iniciar"
	btn_iniciar.custom_minimum_size = Vector2(250, 80)
	btn_iniciar.add_theme_font_size_override("font_size", 36)
	
	# Styling the button programmatically with premium StyleBoxes
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.18, 0.65, 0.35) # Premium green
	style_normal.corner_radius_top_left = 12
	style_normal.corner_radius_top_right = 12
	style_normal.corner_radius_bottom_left = 12
	style_normal.corner_radius_bottom_right = 12
	style_normal.shadow_size = 8
	style_normal.shadow_color = Color(0.18, 0.65, 0.35, 0.3)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.25, 0.8, 0.45) # Brighter green
	style_hover.corner_radius_top_left = 12
	style_hover.corner_radius_top_right = 12
	style_hover.corner_radius_bottom_left = 12
	style_hover.corner_radius_bottom_right = 12
	style_hover.shadow_size = 12
	style_hover.shadow_color = Color(0.25, 0.8, 0.45, 0.5)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.12, 0.5, 0.25) # Darker green
	style_pressed.corner_radius_top_left = 12
	style_pressed.corner_radius_top_right = 12
	style_pressed.corner_radius_bottom_left = 12
	style_pressed.corner_radius_bottom_right = 12
	
	btn_iniciar.add_theme_stylebox_override("normal", style_normal)
	btn_iniciar.add_theme_stylebox_override("hover", style_hover)
	btn_iniciar.add_theme_stylebox_override("pressed", style_pressed)
	btn_iniciar.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Minislime seletor ao passar o mouse
	_attach_selector(btn_iniciar)
	
	btn_iniciar.pressed.connect(show_level_select)
	btn_center.add_child(btn_iniciar)

	# Skins Button
	var btn_skins_center = CenterContainer.new()
	vbox.add_child(btn_skins_center)
	var btn_skins = _make_menu_button("Skins", Color(0.65, 0.35, 0.8), Vector2(250, 80), 36) # Premium purple
	btn_skins.pressed.connect(show_skins_screen)
	btn_skins_center.add_child(btn_skins)

	# Credits Button
	var btn_credits_center = CenterContainer.new()
	vbox.add_child(btn_credits_center)
	var btn_credits = _make_menu_button("Créditos", Color(0.25, 0.5, 0.85), Vector2(250, 80), 36) # Premium blue
	btn_credits.pressed.connect(show_credits_screen)
	btn_credits_center.add_child(btn_credits)

	# Exit Button Container for Start Screen
	var btn_start_exit_center = CenterContainer.new()
	vbox.add_child(btn_start_exit_center)
	
	var btn_start_exit = Button.new()
	btn_start_exit.text = "Sair"
	btn_start_exit.custom_minimum_size = Vector2(250, 80)
	btn_start_exit.add_theme_font_size_override("font_size", 36)
	
	var style_start_exit_normal = StyleBoxFlat.new()
	style_start_exit_normal.bg_color = Color(0.2, 0.2, 0.25) # Premium dark grey/blue
	style_start_exit_normal.corner_radius_top_left = 12
	style_start_exit_normal.corner_radius_top_right = 12
	style_start_exit_normal.corner_radius_bottom_left = 12
	style_start_exit_normal.corner_radius_bottom_right = 12
	style_start_exit_normal.shadow_size = 8
	style_start_exit_normal.shadow_color = Color(0.2, 0.2, 0.25, 0.3)
	
	var style_start_exit_hover = StyleBoxFlat.new()
	style_start_exit_hover.bg_color = Color(0.3, 0.3, 0.38) # Lighter grey/blue
	style_start_exit_hover.corner_radius_top_left = 12
	style_start_exit_hover.corner_radius_top_right = 12
	style_start_exit_hover.corner_radius_bottom_left = 12
	style_start_exit_hover.corner_radius_bottom_right = 12
	style_start_exit_hover.shadow_size = 12
	style_start_exit_hover.shadow_color = Color(0.3, 0.3, 0.38, 0.5)
	
	var style_start_exit_pressed = StyleBoxFlat.new()
	style_start_exit_pressed.bg_color = Color(0.12, 0.12, 0.15) # Darker grey/blue
	style_start_exit_pressed.corner_radius_top_left = 12
	style_start_exit_pressed.corner_radius_top_right = 12
	style_start_exit_pressed.corner_radius_bottom_left = 12
	style_start_exit_pressed.corner_radius_bottom_right = 12
	
	btn_start_exit.add_theme_stylebox_override("normal", style_start_exit_normal)
	btn_start_exit.add_theme_stylebox_override("hover", style_start_exit_hover)
	btn_start_exit.add_theme_stylebox_override("pressed", style_start_exit_pressed)
	btn_start_exit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Minislime seletor ao passar o mouse
	_attach_selector(btn_start_exit)
	
	btn_start_exit.pressed.connect(func():
		get_tree().quit()
	)
	btn_start_exit_center.add_child(btn_start_exit)

func setup_end_screen() -> void:
	end_screen = CanvasLayer.new()
	end_screen.layer = 10
	add_child(end_screen)
	
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_screen.add_child(control)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.05, 0.05, 0.95) # Crimson tinted dark background
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(center)
	
	_add_settings_button(control, true) # depois do center, para ficar por cima dele
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 35)
	center.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "ARENA CONCLUÍDA"
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3)) # Vibrant sunset crimson
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Final Score Display
	final_score_label = Label.new()
	final_score_label.text = "Final Score: 0"
	final_score_label.add_theme_font_size_override("font_size", 48)
	final_score_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3)) # Bright Amber
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(final_score_label)
	
	# Stars (start turned off, lit according to the final score)
	var stars_box = HBoxContainer.new()
	stars_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_box.add_theme_constant_override("separation", 24)
	vbox.add_child(stars_box)
	
	star_rects.clear()
	for i in STAR_COUNT:
		var star = TextureRect.new()
		star.texture = STAR_OFF_TEXTURE
		star.custom_minimum_size = STAR_TEXTURE_SIZE
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stars_box.add_child(star)
		star_rects.append(star)
	
	next_star_label = Label.new()
	next_star_label.add_theme_font_size_override("font_size", 32)
	next_star_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	next_star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(next_star_label)
	
	var btn_center = CenterContainer.new()
	vbox.add_child(btn_center)
	
	# Reiniciar Button
	var btn_reiniciar = Button.new()
	btn_reiniciar.text = "Reiniciar"
	btn_reiniciar.custom_minimum_size = Vector2(250, 80)
	btn_reiniciar.add_theme_font_size_override("font_size", 36)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.75, 0.25, 0.25) # Vibrant crimson
	style_normal.corner_radius_top_left = 12
	style_normal.corner_radius_top_right = 12
	style_normal.corner_radius_bottom_left = 12
	style_normal.corner_radius_bottom_right = 12
	style_normal.shadow_size = 8
	style_normal.shadow_color = Color(0.75, 0.25, 0.25, 0.3)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.9, 0.35, 0.35) # Lighter crimson
	style_hover.corner_radius_top_left = 12
	style_hover.corner_radius_top_right = 12
	style_hover.corner_radius_bottom_left = 12
	style_hover.corner_radius_bottom_right = 12
	style_hover.shadow_size = 12
	style_hover.shadow_color = Color(0.9, 0.35, 0.35, 0.5)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.6, 0.18, 0.18) # Darker crimson
	style_pressed.corner_radius_top_left = 12
	style_pressed.corner_radius_top_right = 12
	style_pressed.corner_radius_bottom_left = 12
	style_pressed.corner_radius_bottom_right = 12
	
	btn_reiniciar.add_theme_stylebox_override("normal", style_normal)
	btn_reiniciar.add_theme_stylebox_override("hover", style_hover)
	btn_reiniciar.add_theme_stylebox_override("pressed", style_pressed)
	btn_reiniciar.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Minislime seletor ao passar o mouse
	_attach_selector(btn_reiniciar)
	
	btn_reiniciar.pressed.connect(_begin_level.bind(false))
	btn_center.add_child(btn_reiniciar)

	var btn_menu_center = CenterContainer.new()
	vbox.add_child(btn_menu_center)
	
	# Main Menu Button
	var btn_menu = Button.new()
	btn_menu.text = "Menu Principal"
	btn_menu.custom_minimum_size = Vector2(250, 80)
	btn_menu.add_theme_font_size_override("font_size", 36)
	
	var style_menu_normal = StyleBoxFlat.new()
	style_menu_normal.bg_color = Color(0.2, 0.4, 0.7) # Nice blue
	style_menu_normal.corner_radius_top_left = 12
	style_menu_normal.corner_radius_top_right = 12
	style_menu_normal.corner_radius_bottom_left = 12
	style_menu_normal.corner_radius_bottom_right = 12
	style_menu_normal.shadow_size = 8
	style_menu_normal.shadow_color = Color(0.2, 0.4, 0.7, 0.3)
	
	var style_menu_hover = StyleBoxFlat.new()
	style_menu_hover.bg_color = Color(0.3, 0.5, 0.8) # Brighter blue
	style_menu_hover.corner_radius_top_left = 12
	style_menu_hover.corner_radius_top_right = 12
	style_menu_hover.corner_radius_bottom_left = 12
	style_menu_hover.corner_radius_bottom_right = 12
	style_menu_hover.shadow_size = 12
	style_menu_hover.shadow_color = Color(0.3, 0.5, 0.8, 0.5)
	
	var style_menu_pressed = StyleBoxFlat.new()
	style_menu_pressed.bg_color = Color(0.15, 0.3, 0.55) # Darker blue
	style_menu_pressed.corner_radius_top_left = 12
	style_menu_pressed.corner_radius_top_right = 12
	style_menu_pressed.corner_radius_bottom_left = 12
	style_menu_pressed.corner_radius_bottom_right = 12
	
	btn_menu.add_theme_stylebox_override("normal", style_menu_normal)
	btn_menu.add_theme_stylebox_override("hover", style_menu_hover)
	btn_menu.add_theme_stylebox_override("pressed", style_menu_pressed)
	btn_menu.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Minislime seletor ao passar o mouse
	_attach_selector(btn_menu)
	
	btn_menu.pressed.connect(return_to_main_menu)
	btn_menu_center.add_child(btn_menu)


func show_start_screen() -> void:
	title_banner.refresh_skin()
	_pick_tagline()
	start_screen.visible = true
	end_screen.visible = false
	level_select_screen.visible = false
	skins_screen.visible = false
	if settings_screen.visible:
		AudioSettings.save()
	settings_screen.visible = false
	credits_screen.visible = false
	music_preview.stop()

# Sorteia uma frase nova, sem repetir a que estava na tela.
func _pick_tagline() -> void:
	var options: Array = TAGLINES.filter(func(t): return t != _last_tagline)
	_last_tagline = options.pick_random()
	tagline_label.text = _last_tagline

func return_to_main_menu() -> void:
	get_tree().paused = false
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null
	show_start_screen()

func show_end_screen(score: int) -> void:
	final_score_label.text = "Final Score: " + str(score)
	update_stars(score)
	if current_level_id != "":
		LevelProgress.record_score(current_level_id, score)
	start_screen.visible = false
	level_select_screen.visible = false
	skins_screen.visible = false
	end_screen.visible = true

func update_stars(score: int) -> void:
	var lit := 0
	for i in current_star_thresholds.size():
		var earned: bool = score >= current_star_thresholds[i]
		star_rects[i].texture = STAR_ON_TEXTURE if earned else STAR_OFF_TEXTURE
		if earned:
			lit += 1
	
	if lit >= current_star_thresholds.size():
		next_star_label.text = "Todas as estrelas conquistadas!"
	else:
		var missing: int = current_star_thresholds[lit] - score
		var unit := "ponto" if missing == 1 else "pontos"
		next_star_label.text = "%d %s para a próxima estrela" % [missing, unit]

func start_level(index: int) -> void:
	if transitioning:
		return
	var level: Dictionary = LEVELS[index]
	current_scene_to_load = load(level["path"])
	current_star_thresholds.assign(level["stars"])
	current_level_id = level["id"]
	_begin_level(true)

func restart_game() -> void:
	# Hide screens
	start_screen.visible = false
	end_screen.visible = false
	level_select_screen.visible = false
	skins_screen.visible = false
	
	# Clean up existing level if any
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null
		
	# Instance and add new level
	if current_scene_to_load:
		current_level_instance = current_scene_to_load.instantiate()
		# Pausável: fica parado enquanto a árvore está pausada (abertura e contagem)
		current_level_instance.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(current_level_instance)
		_prepare_level_for_countdown()

# A fase nasce parada: sem música ainda e com a câmera já no player (nada roda pausado).
func _prepare_level_for_countdown() -> void:
	var soundtrack := current_level_instance.get_node_or_null("soundtrack") as AudioStreamPlayer
	if soundtrack:
		soundtrack.stop()
	var body := current_level_instance.find_child("CharacterBody2D", true, false) as Node2D
	if body:
		get_tree().call_group("FollowPlayer", "updatePlayerPosition", body.global_position)
	var camera := current_level_instance.find_child("Camera2D", true, false) as Camera2D
	if camera:
		camera.reset_smoothing()

func end_game(final_score: int) -> void:
	get_tree().paused = false
	show_end_screen(final_score)
	
	# Clean up level instance
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null

func _input(event: InputEvent) -> void:
	# F11 alterna a tela cheia em qualquer momento
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		DisplaySettings.toggle()
		_update_fullscreen_button()
		return
	if transitioning:
		return
	if settings_screen.visible and event.is_action_pressed("ui_cancel"):
		close_settings()
		return
	if (level_select_screen.visible or skins_screen.visible or credits_screen.visible) and event.is_action_pressed("ui_cancel"):
		show_start_screen()
		return
	if current_level_instance:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			var current_score := 0
			var character = current_level_instance.find_child("CharacterBody2D", true, false)
			if character:
				current_score = character.score
			
			end_game(current_score)

# ---------- Tela de seleção de fases ----------

func setup_level_select_screen() -> void:
	level_select_screen = CanvasLayer.new()
	level_select_screen.layer = 10
	add_child(level_select_screen)

	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_select_screen.add_child(control)

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "SELECIONE A FASE"
	title.add_theme_font_size_override("font_size", 70)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# As linhas são recriadas em show_level_select() para mostrar o progresso atual.
	level_rows = VBoxContainer.new()
	level_rows.add_theme_constant_override("separation", 20)
	vbox.add_child(level_rows)

	var btn_back_center = CenterContainer.new()
	vbox.add_child(btn_back_center)
	var btn_back = _make_menu_button("Voltar", Color(0.2, 0.2, 0.25), Vector2(250, 80), 36)
	btn_back.pressed.connect(show_start_screen)
	btn_back_center.add_child(btn_back)

func show_level_select() -> void:
	for row in level_rows.get_children():
		row.queue_free()
	for i in LEVELS.size():
		level_rows.add_child(_make_level_row(i))
	start_screen.visible = false
	end_screen.visible = false
	skins_screen.visible = false
	level_select_screen.visible = true

func _make_level_row(index: int) -> Control:
	var level: Dictionary = LEVELS[index]
	var available := ResourceLoader.exists(level["path"])
	var best := LevelProgress.get_best_score(level["id"])
	var earned := LevelProgress.count_stars(best, level["stars"])

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(1100, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.21)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	if not available:
		panel.modulate = Color(1, 1, 1, 0.5)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	panel.add_child(row)

	var name_label = Label.new()
	name_label.text = level["name"]
	name_label.custom_minimum_size = Vector2(220, 0)
	name_label.add_theme_font_size_override("font_size", 40)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)

	var is_free: bool = level.get("free", false)
	var stars_box = HBoxContainer.new()
	stars_box.add_theme_constant_override("separation", 8)
	stars_box.visible = not is_free
	row.add_child(stars_box)
	for i in STAR_COUNT:
		var star = TextureRect.new()
		star.texture = STAR_ON_TEXTURE if i < earned else STAR_OFF_TEXTURE
		star.custom_minimum_size = Vector2(72, 72)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stars_box.add_child(star)

	var score_label = Label.new()
	if is_free:
		score_label.text = "Modo livre"
	else:
		score_label.text = "Pontuação: %d" % best if available and best > 0 else "Pontuação: --"
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(score_label)

	var btn = _make_menu_button("Jogar" if available else "Em breve",
			Color(0.18, 0.65, 0.35) if available else Color(0.3, 0.3, 0.35), Vector2(220, 72), 32)
	btn.disabled = not available
	btn.pressed.connect(start_level.bind(index))
	row.add_child(btn)

	return panel

# Botão no mesmo estilo dos outros menus (cantos arredondados, hover em cor mais clara).
func _make_menu_button(text: String, color: Color, min_size: Vector2, font_size: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", font_size)

	var states := {
		"normal": color,
		"hover": color.lightened(0.2),
		"pressed": color.darkened(0.25),
		"disabled": color,
	}
	for state in states:
		var style = StyleBoxFlat.new()
		style.bg_color = states[state]
		style.set_corner_radius_all(12)
		btn.add_theme_stylebox_override(state, style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	_attach_selector(btn)
	return btn

# Em vez de aumentar o botão, um minislime aparece ao lado dele enquanto o mouse está em cima.
func _attach_selector(btn: BaseButton) -> void:
	var selector := AnimatedSprite2D.new()
	selector.sprite_frames = _get_selector_frames()
	selector.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	selector.scale = Vector2.ONE * SELECTOR_SCALE
	selector.z_index = 1
	selector.visible = false
	btn.add_child(selector)

	btn.mouse_entered.connect(func():
		if btn.disabled:
			return
		selector.position = Vector2(-SELECTOR_DISTANCE, btn.size.y / 2.0)
		selector.visible = true
		selector.play("default")
	)
	btn.mouse_exited.connect(func():
		selector.visible = false
		selector.stop()
	)

func _get_selector_frames() -> SpriteFrames:
	if selector_frames == null:
		selector_frames = SpriteFrames.new()
		selector_frames.set_animation_speed("default", SELECTOR_FPS)
		for i in SELECTOR_FRAME_COUNT:
			var frame := AtlasTexture.new()
			frame.atlas = SELECTOR_TEXTURE
			frame.region = Rect2((i % 4) * 80, floori(i / 4.0) * 80, 80, 80)
			selector_frames.add_frame("default", frame)
	return selector_frames

# ---------- Tela de skins ----------

# Soma das estrelas conquistadas em todas as fases (o Playground não conta).
func get_total_stars() -> int:
	var total := 0
	for level in LEVELS:
		if level.get("free", false):
			continue
		total += LevelProgress.count_stars(LevelProgress.get_best_score(level["id"]), level["stars"])
	return total

func get_max_stars() -> int:
	var total := 0
	for level in LEVELS:
		if not level.get("free", false):
			total += level["stars"].size()
	return total

func setup_skins_screen() -> void:
	skins_screen = CanvasLayer.new()
	skins_screen.layer = 10
	add_child(skins_screen)

	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	skins_screen.add_child(control)

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "ESCOLHA SUA SKIN"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.65, 0.35, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Total de estrelas conquistadas (preenchido em _refresh_skin_tower)
	skins_stars_label = Label.new()
	skins_stars_label.add_theme_font_size_override("font_size", 30)
	skins_stars_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	skins_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(skins_stars_label)

	# A torre: o andar mais alto (skin dourada) fica no topo
	var tower_center = CenterContainer.new()
	vbox.add_child(tower_center)
	skins_tower = VBoxContainer.new()
	skins_tower.add_theme_constant_override("separation", 14)
	tower_center.add_child(skins_tower)

	var btn_back_center = CenterContainer.new()
	vbox.add_child(btn_back_center)
	var btn_back = _make_menu_button("Voltar", Color(0.2, 0.2, 0.25), Vector2(250, 80), 36)
	btn_back.pressed.connect(show_start_screen)
	btn_back_center.add_child(btn_back)

func show_skins_screen() -> void:
	_refresh_skin_tower()
	start_screen.visible = false
	end_screen.visible = false
	level_select_screen.visible = false
	skins_screen.visible = true

func _refresh_skin_tower() -> void:
	for floor_row in skins_tower.get_children():
		floor_row.queue_free()
	var total := get_total_stars()
	skins_stars_label.text = "Estrelas: %d / %d" % [total, get_max_stars()]

	var selected := SkinSettings.get_selected()
	for i in range(SkinSettings.TOWER.size() - 1, -1, -1): # de cima para baixo
		var floor_skins: Array = SkinSettings.TOWER[i]
		skins_tower.add_child(_make_tower_floor(floor_skins, total, selected))

# Um andar da torre: o custo em estrelas à esquerda e as skins do andar no centro.
func _make_tower_floor(floor_skins: Array, total_stars: int, selected: int) -> Control:
	var required: int = SkinSettings.STARS_REQUIRED[floor_skins[0]]
	var unlocked := total_stars >= required

	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(820, 0)
	row.add_theme_constant_override("separation", 20)

	var badge = HBoxContainer.new()
	badge.custom_minimum_size = Vector2(150, 0)
	badge.alignment = BoxContainer.ALIGNMENT_CENTER
	badge.add_theme_constant_override("separation", 8)
	row.add_child(badge)
	if required > 0:
		var star = TextureRect.new()
		star.texture = STAR_ON_TEXTURE if unlocked else STAR_OFF_TEXTURE
		star.custom_minimum_size = Vector2(40, 40)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		badge.add_child(star)
	var cost_label = Label.new()
	cost_label.text = str(required) if required > 0 else "Livre"
	cost_label.add_theme_font_size_override("font_size", 30)
	cost_label.add_theme_color_override("font_color",
			Color(0.95, 0.8, 0.3) if unlocked else Color(0.55, 0.55, 0.62))
	badge.add_child(cost_label)

	var cards = HBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	# Espaço grande o bastante para o minislime seletor caber ao lado de cada opção
	cards.add_theme_constant_override("separation", 90)
	row.add_child(cards)
	for skin_index in floor_skins:
		cards.add_child(_make_skin_card(skin_index, skin_index == selected, unlocked))

	# Espelha o badge do outro lado, para as skins ficarem centralizadas na torre
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(150, 0)
	row.add_child(spacer)
	return row

func _make_skin_card(index: int, is_selected: bool, unlocked: bool) -> Control:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(110, 110)
	btn.icon = SkinSettings.slime_texture(index)
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.disabled = not unlocked
	# Bloqueada: o slime aparece como uma silhueta escura
	btn.add_theme_color_override("icon_disabled_color", Color(0.1, 0.1, 0.16))
	var states := {
		"normal": Color(0.14, 0.14, 0.21),
		"hover": Color(0.2, 0.2, 0.3),
		"pressed": Color(0.1, 0.1, 0.16),
		"disabled": Color(0.1, 0.1, 0.15),
	}
	for state in states:
		var style = StyleBoxFlat.new()
		style.bg_color = states[state]
		style.set_corner_radius_all(12)
		style.set_content_margin_all(12)
		if is_selected: # a skin em uso ganha uma borda dourada
			style.border_color = Color(0.95, 0.8, 0.3)
			style.set_border_width_all(5)
		btn.add_theme_stylebox_override(state, style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(func():
		SkinSettings.set_selected(index)
		_refresh_skin_tower()
	)
	_attach_selector(btn)
	card.add_child(btn)

	# Nome da skin com a seta correspondente ao lado
	var info = HBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 10)
	card.add_child(info)

	var arrow = TextureRect.new()
	arrow.texture = SkinSettings.arrow_texture(index)
	arrow.custom_minimum_size = Vector2(30, 30)
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not unlocked:
		arrow.modulate = Color(0.3, 0.3, 0.35)
	info.add_child(arrow)

	var name_label = Label.new()
	name_label.text = SkinSettings.SKIN_NAMES[index]
	name_label.add_theme_font_size_override("font_size", 22)
	var name_color := Color(0.85, 0.85, 0.9)
	if is_selected:
		name_color = Color(0.95, 0.8, 0.3)
	elif not unlocked:
		name_color = Color(0.45, 0.45, 0.52)
	name_label.add_theme_color_override("font_color", name_color)
	info.add_child(name_label)

	return card

# ---------- Tela de configurações ----------

func setup_settings_screen() -> void:
	settings_screen = CanvasLayer.new()
	settings_screen.layer = 10
	add_child(settings_screen)

	# Enquanto a tela está aberta, toca a música da fase (no bus da música) para
	# dar para ouvir o volume enquanto se mexe no slider.
	music_preview = AudioStreamPlayer.new()
	music_preview.stream = MUSIC_PREVIEW
	music_preview.bus = &"Soundtrack"
	add_child(music_preview)

	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_screen.add_child(control)

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 50)
	center.add_child(vbox)

	var title_box = HBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 24)
	vbox.add_child(title_box)
	var title_icon = TextureRect.new()
	title_icon.texture = CONFIG_ICON
	title_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title_box.add_child(title_icon)
	var title = Label.new()
	title.text = "CONFIGURAÇÕES"
	title.add_theme_font_size_override("font_size", 70)
	title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	title_box.add_child(title)

	# Linha do volume da música: ícone, slider e porcentagem
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.14, 0.14, 0.21)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	vbox.add_child(panel)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	panel.add_child(row)

	var music_icon = TextureRect.new()
	music_icon.texture = MUSIC_ICON
	music_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(music_icon)

	var text_box = VBoxContainer.new()
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text_box)
	var music_label = Label.new()
	music_label.text = "Música"
	music_label.add_theme_font_size_override("font_size", 32)
	music_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	text_box.add_child(music_label)

	music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	music_slider.custom_minimum_size = Vector2(520, 40)
	_style_slider(music_slider, Color(0.4, 0.9, 0.5))
	music_slider.value_changed.connect(_on_music_slider_changed)
	music_slider.drag_ended.connect(func(_changed): AudioSettings.save())
	text_box.add_child(music_slider)

	music_value_label = Label.new()
	music_value_label.custom_minimum_size = Vector2(130, 0)
	music_value_label.add_theme_font_size_override("font_size", 36)
	music_value_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	music_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	music_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(music_value_label)

	# Tela cheia (também alterna com F11)
	var fullscreen_center = CenterContainer.new()
	vbox.add_child(fullscreen_center)
	fullscreen_button = _make_menu_button("", Color(0.25, 0.5, 0.85), Vector2(560, 80), 32)
	fullscreen_button.pressed.connect(func():
		DisplaySettings.toggle()
		_update_fullscreen_button()
	)
	fullscreen_center.add_child(fullscreen_button)
	_update_fullscreen_button()

	var btn_back_center = CenterContainer.new()
	vbox.add_child(btn_back_center)
	var btn_back = _make_menu_button("Voltar", Color(0.2, 0.2, 0.25), Vector2(250, 80), 36)
	btn_back.pressed.connect(close_settings)
	btn_back_center.add_child(btn_back)

# Volta para a tela de onde as configurações foram abertas (menu principal ou fim da fase).
func close_settings() -> void:
	AudioSettings.save()
	music_preview.stop()
	settings_screen.visible = false
	if settings_from_end_screen:
		end_screen.visible = true
	else:
		show_start_screen()

# Botão de engrenagem no canto superior direito. `from_end_screen` diz para onde "Voltar" leva.
func _add_settings_button(control: Control, from_end_screen: bool) -> void:
	# TextureButton: mostra a imagem esticada até o tamanho do botão, sem depender do estilo de Button
	var btn = TextureButton.new()
	btn.texture_normal = CONFIG_ICON
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = CONFIG_BUTTON_SIZE
	btn.size = CONFIG_BUTTON_SIZE
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	control.add_child(btn)
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 30)
	btn.pressed.connect(show_settings_screen.bind(from_end_screen))
	_attach_selector(btn)

func _update_fullscreen_button() -> void:
	fullscreen_button.text = "Tela cheia: %s (F11)" % ("SIM" if DisplaySettings.is_fullscreen() else "NÃO")

func show_settings_screen(from_end_screen: bool = false) -> void:
	settings_from_end_screen = from_end_screen
	# Ajusta o slider ao volume atual sem disparar o callback
	music_slider.set_value_no_signal(round(AudioSettings.get_music_volume() * 100.0))
	_update_music_label()
	start_screen.visible = false
	end_screen.visible = false
	level_select_screen.visible = false
	skins_screen.visible = false
	settings_screen.visible = true
	music_preview.play()

func _on_music_slider_changed(value: float) -> void:
	AudioSettings.set_music_volume(value / 100.0)
	_update_music_label()

func _update_music_label() -> void:
	music_value_label.text = "%d%%" % int(music_slider.value)

# Slider no mesmo estilo dos menus: trilho arredondado, parte preenchida colorida e bolinha grande.
func _style_slider(slider: HSlider, color: Color) -> void:
	var track = StyleBoxFlat.new()
	track.bg_color = Color(0.08, 0.08, 0.12)
	track.set_corner_radius_all(8)
	track.content_margin_top = 8
	track.content_margin_bottom = 8

	var filled = StyleBoxFlat.new()
	filled.bg_color = color
	filled.set_corner_radius_all(8)
	filled.content_margin_top = 8
	filled.content_margin_bottom = 8

	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)

	# Bolinha: textura radial branca de 32x32
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.9, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var knob = GradientTexture2D.new()
	knob.gradient = gradient
	knob.fill = GradientTexture2D.FILL_RADIAL
	knob.fill_from = Vector2(0.5, 0.5)
	knob.fill_to = Vector2(1.0, 0.5)
	knob.width = 32
	knob.height = 32
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", knob)

# ---------- Abertura da fase: tela de carregamento (falsa) e contagem ----------

func setup_transition_layer() -> void:
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 30 # acima de todas as telas
	transition_layer.visible = false
	add_child(transition_layer)

	var screen_size := Vector2(1920, 1080) # tamanho base da tela (project.godot)

	transition_rect = ColorRect.new()
	transition_rect.color = Color.BLACK
	transition_rect.size = screen_size
	transition_rect.position = Vector2(screen_size.x, 0) # começa fora da tela, à direita
	transition_layer.add_child(transition_rect)

	# Minislime animado no meio da tela preta (reaproveita as animações da cena do minislime)
	var minislime := MINISLIME_SCENE.instantiate()
	var frames: SpriteFrames = minislime.get_node("AnimatedSprite2D").sprite_frames
	minislime.free()
	loading_sprite = AnimatedSprite2D.new()
	loading_sprite.sprite_frames = frames
	loading_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	loading_sprite.scale = Vector2.ONE * 3.0
	loading_sprite.position = screen_size / 2.0 - Vector2(0, 40)
	loading_sprite.animation_finished.connect(_play_random_loading_animation)
	transition_rect.add_child(loading_sprite)

	# Frase aleatória embaixo do minislime
	loading_label = Label.new()
	loading_label.add_theme_font_size_override("font_size", 32)
	loading_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.size = Vector2(1500, 60)
	loading_label.position = Vector2(screen_size.x / 2.0 - 750.0, screen_size.y / 2.0 + 140.0)
	transition_rect.add_child(loading_label)

	# Números da contagem, no centro da tela (fora da cortina, que já saiu)
	countdown_label = Label.new()
	countdown_label.add_theme_font_override("font", PIXEL_FONT)
	countdown_label.add_theme_font_size_override("font_size", 200)
	countdown_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	countdown_label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.1))
	countdown_label.add_theme_constant_override("outline_size", 24)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.size = Vector2(1200, 300)
	countdown_label.position = Vector2(screen_size.x / 2.0 - 600.0, screen_size.y / 2.0 - 150.0)
	countdown_label.pivot_offset = countdown_label.size / 2.0
	countdown_label.visible = false
	transition_layer.add_child(countdown_label)

func _play_random_loading_animation() -> void:
	loading_sprite.play(LOADING_ANIMATIONS.pick_random())

# Espera `seconds` de tempo real, mesmo com o jogo pausado
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

# Abre a fase: [tela preta + "carregando"] -> fase parada -> contagem -> jogo.
func _begin_level(with_loading: bool) -> void:
	if transitioning:
		return
	transitioning = true
	get_tree().paused = true # a fase só roda depois da contagem

	if with_loading:
		var started := Time.get_ticks_msec()
		transition_layer.visible = true
		loading_label.text = TAGLINES.pick_random()
		_play_random_loading_animation()
		create_tween().tween_property(transition_rect, "position:x", 0.0, WIPE_TIME) \
			.from(1920.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await _wait(WIPE_TIME)

		restart_game() # a fase é criada por trás da tela preta

		# "Carrega" o resto do tempo e a tela preta sai pela esquerda
		var elapsed := (Time.get_ticks_msec() - started) / 1000.0
		await _wait(maxf(0.0, LOADING_TOTAL - WIPE_TIME - elapsed))
		create_tween().tween_property(transition_rect, "position:x", -1920.0, WIPE_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await _wait(WIPE_TIME)
		loading_sprite.stop()
		transition_rect.position.x = 1920.0
	else:
		transition_layer.visible = true
		restart_game()

	await _run_countdown()

	get_tree().paused = false
	if current_level_instance:
		var soundtrack := current_level_instance.get_node_or_null("soundtrack") as AudioStreamPlayer
		if soundtrack:
			soundtrack.play()
	transitioning = false

func _run_countdown() -> void:
	countdown_label.visible = true
	for number in range(COUNTDOWN_SECONDS, 0, -1):
		countdown_label.text = str(number)
		countdown_label.modulate.a = 1.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.4) \
			.from(Vector2(1.6, 1.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(countdown_label, "modulate:a", 0.0, 0.3).set_delay(0.7)
		await _wait(1.0)
	countdown_label.visible = false
	transition_layer.visible = false

# ---------- Tela de créditos (álbum de fotos) ----------

func setup_credits_screen() -> void:
	credits_screen = CanvasLayer.new()
	credits_screen.layer = 10
	add_child(credits_screen)

	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	credits_screen.add_child(control)

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "CRÉDITOS"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.25, 0.5, 0.85))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Álbum de fotos do dev (nenhum slime foi ferido... muito)"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# As duas fotos, coladas no "álbum" com uma leve inclinação
	var album = HBoxContainer.new()
	album.alignment = BoxContainer.ALIGNMENT_CENTER
	album.add_theme_constant_override("separation", 90)
	vbox.add_child(album)
	album.add_child(_make_polaroid(CREDITS_PHOTO_1, Vector2(300, 400), -3.0,
			"Fig. 1: o dev testando a física de pulo ao vivo. Nota: pose 10, pantufas 0."))
	album.add_child(_make_polaroid(CREDITS_PHOTO_2, Vector2(440, 330), 2.5,
			"Fig. 2: reunião oficial de game design. Pauta: nenhuma. Ata: muitas risadas."))

	var email_label = Label.new()
	email_label.text = "Elogios, bugs e propostas de patrocínio (aceito, sim): %s" % CREDITS_EMAIL
	email_label.add_theme_font_size_override("font_size", 26)
	email_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	email_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(email_label)

	var btn_back_center = CenterContainer.new()
	vbox.add_child(btn_back_center)
	var btn_back = _make_menu_button("Voltar", Color(0.2, 0.2, 0.25), Vector2(250, 80), 36)
	btn_back.pressed.connect(show_start_screen)
	btn_back_center.add_child(btn_back)

func show_credits_screen() -> void:
	start_screen.visible = false
	end_screen.visible = false
	level_select_screen.visible = false
	skins_screen.visible = false
	settings_screen.visible = false
	credits_screen.visible = true

# Foto com moldura branca e legenda embaixo, como uma polaroid, girada `tilt` graus.
func _make_polaroid(photo: Texture2D, photo_size: Vector2, tilt: float, caption: String) -> Control:
	var frame = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.94, 0.88)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(14)
	style.shadow_size = 12
	style.shadow_color = Color(0, 0, 0, 0.5)
	frame.add_theme_stylebox_override("panel", style)
	frame.pivot_offset_ratio = Vector2(0.5, 0.5)
	frame.rotation_degrees = tilt

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	frame.add_child(box)

	var picture = TextureRect.new()
	picture.texture = photo
	picture.custom_minimum_size = photo_size
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	box.add_child(picture)

	var caption_label = Label.new()
	caption_label.text = caption
	caption_label.custom_minimum_size = Vector2(photo_size.x, 0)
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.add_theme_font_size_override("font_size", 20)
	caption_label.add_theme_color_override("font_color", Color(0.2, 0.18, 0.25))
	box.add_child(caption_label)

	return frame
