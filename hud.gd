extends CanvasLayer

@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	update_score(0)

func update_score(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)
