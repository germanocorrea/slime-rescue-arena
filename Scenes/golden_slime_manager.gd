extends Node

# Faz nascer o slime dourado uma única vez por partida. Ele só nasce se:
#  - já passou da metade do tempo da fase, e
#  - existe algum ponto do GoldenPath bem longe do player (para o player ter que ir atrás).
# Os pontos do caminho são os filhos (Marker2D) do nó GoldenPath da fase, na ordem
# em que aparecem; o slime dourado anda por eles em loop.

const GOLDEN_SCENE = preload("res://Scenes/GoldenMiniSlime.tscn")

@export var min_player_distance := 1100.0 # distância mínima player → ponto de nascimento
@export var spawn_time_ratio := 0.5 # fração do tempo da fase que precisa ter passado
@export var check_interval := 0.5

var _nasceu := false
var _check_timer := 0.0

@onready var _hud := get_parent().get_node_or_null("HUD")
@onready var _path_root := get_parent().get_node_or_null("GoldenPath")

func _ready() -> void:
	add_to_group("golden_slime_manager")

func _process(delta: float) -> void:
	if _nasceu:
		return
	_check_timer += delta
	if _check_timer < check_interval:
		return
	_check_timer = 0.0
	_tentar_nascer()

func _tentar_nascer() -> void:
	if _hud == null or _path_root == null or not _hud.has_method("elapsed_ratio"):
		return
	if _hud.elapsed_ratio() < spawn_time_ratio:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return

	var pontos := _pontos_do_caminho()
	if pontos.size() < 2:
		push_warning("GoldenPath precisa de pelo menos 2 pontos (Marker2D).")
		return

	var candidatos: Array[int] = []
	for i in pontos.size():
		if pontos[i].distance_to(player.global_position) >= min_player_distance:
			candidatos.append(i)
	if candidatos.is_empty():
		return

	_nasceu = true
	var dourado := GOLDEN_SCENE.instantiate()
	get_parent().add_child(dourado)
	dourado.iniciar(pontos, candidatos.pick_random())

func _pontos_do_caminho() -> Array[Vector2]:
	var pontos: Array[Vector2] = []
	for child in _path_root.get_children():
		if child is Node2D:
			pontos.append(child.global_position)
	return pontos

# Só existe para o dourado avisar que acabou; hoje nada precisa reagir.
func dourado_finalizado() -> void:
	pass
