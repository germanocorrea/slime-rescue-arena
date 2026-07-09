extends Area2D

var spawner

var posicao_inicial: Vector2
var tempo := 0.0
var offset := randf() * TAU

@onready var anim = $AnimatedSprite2D

var paletas = [
	{
	"claro": Color("#639bff"),
	"escuro": Color("#5b6ee1")
	},
	{
		"claro": Color("#fa66fa"),
		"escuro": Color("#cf57cf")
	},
	{
		"claro": Color("#8121c7"),
		"escuro": Color("#6707ac")
	},
	{
		"claro": Color("#b23434"),
		"escuro": Color("#932c2c")
	},
	{
		"claro": Color("#99e550"),
		"escuro": Color("#70c81e")
	},
	{
		"claro": Color("#fbf236"),
		"escuro": Color("#deca31")
	},
	{
		"claro": Color("#dddddd"),
		"escuro": Color("#afafaf")
	}
]

var animacoes_aleatorias = [
	"action1",
	"action2",
	"action3"
]


func _ready():
	body_entered.connect(_on_body_entered)
	posicao_inicial = global_position
	$AnimatedSprite2D.play("spawn")
	$Timer.wait_time = randf_range(4.0, 8.0)

	# Cria uma cópia exclusiva do material para este slime
	$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()

	var spriteMaterial = $AnimatedSprite2D.material

	var paleta = paletas.pick_random()

	spriteMaterial.set_shader_parameter("new_color_1", paleta["claro"])
	spriteMaterial.set_shader_parameter("new_color_2", paleta["escuro"])

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

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "spawn":
		anim.play("idle")
		return

	if anim.animation in animacoes_aleatorias:
		anim.play("idle")
	
	if anim.animation == "idle":
		anim.play("idle")
		anim.frame = 0
		return

func _on_timer_timeout() -> void:
	if anim.animation == "idle":
		var escolhida = animacoes_aleatorias.pick_random()
		anim.play(escolhida)
