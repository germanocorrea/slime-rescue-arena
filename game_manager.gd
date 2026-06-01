extends Node

const LEVEL_SCENE = preload("res://level.tscn")

var start_screen: CanvasLayer
var end_screen: CanvasLayer
var final_score_label: Label
var current_level_instance: Node = null

func _ready() -> void:
	# Add this node to the "game_manager" group
	add_to_group("game_manager")
	
	setup_start_screen()
	setup_end_screen()
	
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
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	center.add_child(vbox)
	
	# Beautiful title
	var title = Label.new()
	title.text = "SLIME RESCUE ARENA"
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5)) # Neon slime green
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Subtitle/Description
	var subtitle = Label.new()
	subtitle.text = "Capture Minislimes to score! Reach 500 points or survive 2 minutes."
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8)) # Premium silver
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
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
	
	# Hook signals for hover micro-animations
	btn_iniciar.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(btn_iniciar, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)
	)
	btn_iniciar.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn_iniciar, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	)
	
	btn_iniciar.pressed.connect(start_game)
	btn_center.add_child(btn_iniciar)

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
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 35)
	center.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "ARENA CONCLUDED"
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
	
	# Micro-animations
	btn_reiniciar.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(btn_reiniciar, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)
	)
	btn_reiniciar.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn_reiniciar, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	)
	
	btn_reiniciar.pressed.connect(start_game)
	btn_center.add_child(btn_reiniciar)

	var btn_exit_center = CenterContainer.new()
	vbox.add_child(btn_exit_center)
	
	# Exit Button
	var btn_exit = Button.new()
	btn_exit.text = "Sair"
	btn_exit.custom_minimum_size = Vector2(250, 80)
	btn_exit.add_theme_font_size_override("font_size", 36)
	
	var style_exit_normal = StyleBoxFlat.new()
	style_exit_normal.bg_color = Color(0.2, 0.2, 0.25) # Premium dark grey/blue
	style_exit_normal.corner_radius_top_left = 12
	style_exit_normal.corner_radius_top_right = 12
	style_exit_normal.corner_radius_bottom_left = 12
	style_exit_normal.corner_radius_bottom_right = 12
	style_exit_normal.shadow_size = 8
	style_exit_normal.shadow_color = Color(0.2, 0.2, 0.25, 0.3)
	
	var style_exit_hover = StyleBoxFlat.new()
	style_exit_hover.bg_color = Color(0.3, 0.3, 0.38) # Lighter grey/blue
	style_exit_hover.corner_radius_top_left = 12
	style_exit_hover.corner_radius_top_right = 12
	style_exit_hover.corner_radius_bottom_left = 12
	style_exit_hover.corner_radius_bottom_right = 12
	style_exit_hover.shadow_size = 12
	style_exit_hover.shadow_color = Color(0.3, 0.3, 0.38, 0.5)
	
	var style_exit_pressed = StyleBoxFlat.new()
	style_exit_pressed.bg_color = Color(0.12, 0.12, 0.15) # Darker grey/blue
	style_exit_pressed.corner_radius_top_left = 12
	style_exit_pressed.corner_radius_top_right = 12
	style_exit_pressed.corner_radius_bottom_left = 12
	style_exit_pressed.corner_radius_bottom_right = 12
	
	btn_exit.add_theme_stylebox_override("normal", style_exit_normal)
	btn_exit.add_theme_stylebox_override("hover", style_exit_hover)
	btn_exit.add_theme_stylebox_override("pressed", style_exit_pressed)
	btn_exit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Micro-animations
	btn_exit.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(btn_exit, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)
	)
	btn_exit.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn_exit, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	)
	
	btn_exit.pressed.connect(func():
		get_tree().quit()
	)
	btn_exit_center.add_child(btn_exit)

func show_start_screen() -> void:
	start_screen.visible = true
	end_screen.visible = false

func show_end_screen(score: int) -> void:
	final_score_label.text = "Final Score: " + str(score)
	start_screen.visible = false
	end_screen.visible = true

func start_game() -> void:
	# Hide screens
	start_screen.visible = false
	end_screen.visible = false
	
	# Clean up existing level if any
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null
		
	# Instance and add new level
	current_level_instance = LEVEL_SCENE.instantiate()
	add_child(current_level_instance)

func end_game(final_score: int) -> void:
	show_end_screen(final_score)
	
	# Clean up level instance
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null

func _input(event: InputEvent) -> void:
	if current_level_instance:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			var current_score := 0
			var character = current_level_instance.find_child("CharacterBody2D", true, false)
			if character:
				current_score = character.score
			
			end_game(current_score)
