extends Camera2D

@onready var globalPlayerPosition = global_position

func _ready() -> void:
	add_to_group("FollowPlayer")

func _process(delta):
	global_position = global_position.lerp(globalPlayerPosition, 5.0 * delta)

func updatePlayerPosition(currentPlayerPosition: Vector2):
	global_position = currentPlayerPosition
