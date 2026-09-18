extends Area2D

var spawner

var posicao_inicial: Vector2
var tempo := 0.0
var offset := randf() * TAU

# Pontuação: começa em 1 e ganha +1 a cada INTERVALO_PONTO segundos.
# Encolhe até ESCALA_FINAL ao longo de VIDA_TOTAL segundos e então some.
const INTERVALO_PONTO := 3.0
const VIDA_TOTAL := 30.0
const ESCALA_FINAL := 0.5

var pontos := 1
var idade := 0.0
var escala_inicial := Vector2.ONE

var coletado := false

@onready var anim = $AnimatedSprite2D

var paletas = [
	{
		"claro": Color("#639bff"),
		"escuro": Color("#5b6ee1"),
		"pontos": 1 
	},
	{
		"claro": Color("#fa66fa"),
		"escuro": Color("#cf57cf"),
		"pontos": 8 
	},
	{
		"claro": Color("#8121c7"),
		"escuro": Color("#6707ac"),
		"pontos": 5 
	},
	{
		"claro": Color("#b23434"),
		"escuro": Color("#932c2c"),
		"pontos": 4  
	},
	{
		"claro": Color("#99e550"),
		"escuro": Color("#70c81e"),
		"pontos": 2  
	},
	{
		"claro": Color("#fbf236"),
		"escuro": Color("#deca31"),
		"pontos": 3  
	},
	{
		"claro": Color("#dddddd"),
		"escuro": Color("#afafaf"),
		"pontos": 1
	}
]

var animacoes_aleatorias = [
	"action1",
	"action2",
	"action3"
]


func _ready():
	add_to_group("minislimes")
	body_entered.connect(_on_body_entered)
	posicao_inicial = global_position
	$AnimatedSprite2D.play("spawn")
	$Timer.wait_time = randf_range(4.0, 8.0)

	# Cria uma cópia exclusiva do material para este slime
	$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()

	var material = $AnimatedSprite2D.material

	var paleta = paletas.pick_random()

	material.set_shader_parameter("new_color_1", paleta["claro"])
	material.set_shader_parameter("new_color_2", paleta["escuro"])

	escala_inicial = scale

func _process(delta):
	tempo += delta

	idade += delta
	if idade >= VIDA_TOTAL:
		_expirar()
		return
	pontos = 1 + int(idade / INTERVALO_PONTO)
	scale = escala_inicial * lerpf(1.0, ESCALA_FINAL, idade / VIDA_TOTAL)

	global_position.y = posicao_inicial.y + cos(tempo * 2.0 + offset) * 10.0

func _expirar() -> void:
	if coletado:
		return
	coletado = true
	spawner.slime_coletado()
	queue_free()

func _on_body_entered(body):
	if coletado:
		return
	if body.name.begins_with("Bone"):
		coletado = true
		var character = body.get_parent().get_parent().get_node_or_null("CharacterBody2D")
		if character and character.has_method("add_score"):
			character.add_score(pontos)
		print("MiniSlime coletado! +", pontos, " pontos")
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
