extends RefCounted

# Guarda em disco a melhor pontuação de cada fase. As estrelas não são salvas:
# são calculadas a partir da pontuação e dos limites da fase.

const SAVE_PATH := "user://progress.cfg"
const SECTION := "best_score"

static func get_best_score(level_id: String) -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return int(config.get_value(SECTION, level_id, 0))

# Só grava se a pontuação for maior que a melhor já conquistada.
static func record_score(level_id: String, score: int) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH) # se o arquivo não existir ainda, começa vazio
	if score <= int(config.get_value(SECTION, level_id, 0)):
		return
	config.set_value(SECTION, level_id, score)
	config.save(SAVE_PATH)

static func count_stars(score: int, thresholds: Array) -> int:
	var stars := 0
	for threshold in thresholds:
		if score >= threshold:
			stars += 1
	return stars
