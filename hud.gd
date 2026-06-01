extends CanvasLayer

@onready var score_label: Label = $ScoreLabel

var time_label: Label
var timer: Timer
var time_left := 120.0

func _ready() -> void:
	update_score(0)
	setup_timer()

func setup_timer() -> void:
	# Create and style TimeLabel
	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.add_theme_font_size_override("font_size", 50)
	
	# Layout settings for top-right alignment
	time_label.anchor_left = 1.0
	time_label.anchor_top = 0.0
	time_label.anchor_right = 1.0
	time_label.anchor_bottom = 0.0
	time_label.offset_left = -350
	time_label.offset_top = 10
	time_label.offset_right = -20
	time_label.offset_bottom = 80
	time_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	add_child(time_label)
	update_timer_display()

	# Create Timer node
	timer = Timer.new()
	timer.one_shot = false
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func update_score(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)

func update_timer_display() -> void:
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]

func _on_timer_timeout() -> void:
	if time_left > 0:
		time_left -= 1.0
		if time_left < 0:
			time_left = 0.0
		update_timer_display()
		if time_left == 0.0:
			timer.stop()
