extends Area2D

var spawner

var posicao_inicial: Vector2
var tempo := 0.0
var offset := randf() * TAU


func _ready():
	body_entered.connect(_on_body_entered)
	posicao_inicial = global_position

func _process(delta):
	tempo += delta

	global_position.y = posicao_inicial.y + cos(tempo * 2.0 + offset) * 10.0


func _on_body_entered(body):
	if body.name.begins_with("Bone"):
		var character = body.get_parent().get_parent().get_node_or_null("CharacterBody2D")
		if character and character.has_method("add_score"):
			character.add_score(1)
		print("MiniSlime coletado!")
		spawner.slime_coletado()
		queue_free()
		
		
