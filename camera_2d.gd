extends Camera2D

@onready var player = $"../SlimeCharacter/CharacterBody2D"

func _process(delta):
	global_position = global_position.lerp(player.global_position, 5.0 * delta)
