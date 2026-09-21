extends Node

# Coordena todos os spawners da fase: no máximo `max_ativos` minislimes ao mesmo
# tempo, sempre nascendo em um spawner livre escolhido aleatoriamente.
# No modo `independente` não há limite: cada spawner mantém o seu próprio minislime e
# faz nascer outro `tempo_respawn_independente` segundos depois de o anterior sumir.

@export var max_ativos := 3
@export var tempo_respawn := 1.0 # espera entre uma vaga abrir e o próximo nascer

@export var independente := false
@export var tempo_respawn_independente := 4.0

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
	if independente:
		for spawner in _spawners:
			spawner.spawn_slime()
		return
	for i in max_ativos:
		_nascer_em_spawner_aleatorio()

func vaga_liberada(spawner: Node) -> void:
	if independente:
		await get_tree().create_timer(tempo_respawn_independente).timeout
		if is_instance_valid(spawner) and spawner.esta_livre():
			spawner.spawn_slime()
		return
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
