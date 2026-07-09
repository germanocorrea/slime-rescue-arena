extends Sprite2D

@onready var globalPlayerPosition = global_position
@onready var playerDirection = -1

func _ready() -> void:
	add_to_group("FollowPlayer")
	add_to_group("SlimeEyes")

func _process(delta):
	flip_h = playerDirection == 1
	global_position = global_position.lerp(globalPlayerPosition, 3 * delta)

func updatePlayerPosition(currentPlayerPosition: Vector2):
	globalPlayerPosition = currentPlayerPosition

func updatePlayerDirection(currentDirection: int):
	playerDirection = currentDirection
