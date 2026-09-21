extends Area2D

# Minislime dourado: nasce uma vez por partida, anda em loop pelos pontos do
# caminho (GoldenPath), deixa uma trilha de partículas e some sozinho depois de
# VIDA_TOTAL segundos.
# Funciona por conta própria, sem passar pelos spawners dos minislimes normais.

const COLLECT_SOUND = preload("res://audio/sfx/golden/golden_collect.wav")

const PONTOS := 15
const VIDA_TOTAL := 20.0
const INTERVALO_ANIMACAO := 3.0 # de quanto em quanto tempo toca a animação (fora isso fica em idle)
const TEMPO_PISCANDO := 3.0 # nos últimos segundos ele pisca para avisar que vai sumir

@export var velocidade := 182.0 # 70% dos 260 originais

var coletado := false

var _caminho: Array[Vector2] = []
var _indice_alvo := 0
var _idade := 0.0
var _tempo := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# Chamado pelo GoldenSlimeManager logo depois de adicionar o slime à cena.
func iniciar(caminho: Array[Vector2], indice_inicial: int) -> void:
	_caminho = caminho
	global_position = _caminho[indice_inicial]
	_indice_alvo = (indice_inicial + 1) % _caminho.size()

func _ready() -> void:
	add_to_group("golden_minislime")
	body_entered.connect(_on_body_entered)
	anim.play("idle")
	$SpawnSound.play()
	$Timer.wait_time = INTERVALO_ANIMACAO
	$Timer.timeout.connect(_on_timer_timeout)
	anim.animation_finished.connect(_on_animation_finished)

	# Surge com um "pop"
	var final_scale := scale
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", final_scale, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if coletado:
		return

	_idade += delta
	_tempo += delta
	if _idade >= VIDA_TOTAL:
		_expirar()
		return

	_mover(delta)
	anim.position.y = sin(_tempo * 6.0) * 6.0 # flutua

	if VIDA_TOTAL - _idade <= TEMPO_PISCANDO:
		anim.visible = int(_tempo * 10.0) % 2 == 0

func _mover(delta: float) -> void:
	if _caminho.size() < 2:
		return
	var alvo := _caminho[_indice_alvo]
	var direcao := alvo - global_position
	if abs(direcao.x) > 1.0:
		anim.flip_h = direcao.x < 0.0
	global_position = global_position.move_toward(alvo, velocidade * delta)
	if global_position.distance_to(alvo) < 1.0:
		_indice_alvo = (_indice_alvo + 1) % _caminho.size()

func _expirar() -> void:
	coletado = true
	get_tree().call_group("golden_slime_manager", "dourado_finalizado")
	queue_free()

func _on_body_entered(body: Node) -> void:
	if coletado:
		return
	if body.name.begins_with("Bone"):
		coletado = true
		var character = body.get_parent().get_parent().get_node_or_null("CharacterBody2D")
		if character and character.has_method("collect"):
			character.collect(PONTOS, global_position)
		_tocar_som_de_coleta()
		get_tree().call_group("golden_slime_manager", "dourado_finalizado")
		queue_free()

# O slime é removido logo após a coleta, então o som toca em um player próprio
# que fica na fase e se apaga sozinho quando termina.
func _tocar_som_de_coleta() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = COLLECT_SOUND
	player.bus = &"SFX"
	player.volume_db = -3.0
	get_parent().add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _on_timer_timeout() -> void:
	if anim.animation == "idle":
		anim.play("action")
		$TwinkleSound.play()

func _on_animation_finished() -> void:
	anim.play("idle")
