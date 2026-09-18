extends Node

# Coordena todos os spawners da fase: no máximo `max_ativos` minislimes ao mesmo
# tempo, sempre nascendo em um spawner livre escolhido aleatoriamente.

@export var max_ativos := 3
@export var tempo_respawn := 4.0 # espera entre uma vaga abrir e o próximo nascer

var _spawners: Array[Node] = []
var _pendentes := 0 # nascimentos agendados que ainda não aconteceram

func _ready() -> void:
	add_to_group("spawn_manager")
	# Espera um frame para todos os spawners da fase estarem prontos
	await get_tree().process_frame
	var fase := get_parent()
	for spawner in get_tree().get_nodes_in_group("spawners"):
		if fase.is_ancestor_of(spawner):
			_spawners.append(spawner)
	for i in max_ativos:
		_nascer_em_spawner_aleatorio()

func vaga_liberada(spawner: Node) -> void:
	_pendentes += 1
	await get_tree().create_timer(tempo_respawn).timeout
	_pendentes -= 1
	# Evita repetir o spawner que acabou de liberar, se houver outra opção
	_nascer_em_spawner_aleatorio(spawner)

func _ativos() -> int:
	var total := 0
	for spawner in _spawners:
		if is_instance_valid(spawner) and not spawner.esta_livre():
			total += 1
	return total

func _nascer_em_spawner_aleatorio(evitar: Node = null) -> void:
	if _ativos() + _pendentes >= max_ativos:
		return
	var livres: Array = _spawners.filter(func(s): return is_instance_valid(s) and s.esta_livre())
	if livres.size() > 1 and evitar in livres:
		livres.erase(evitar)
	if livres.is_empty():
		return
	livres.pick_random().spawn_slime()
