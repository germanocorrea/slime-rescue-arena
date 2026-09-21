extends RefCounted

# Volume da música (bus "Soundtrack"), de 0.0 (mudo) a 1.0 (volume original do bus).
# O valor é salvo em disco e aplicado ao abrir o jogo.

const SAVE_PATH := "user://settings.cfg"
const SECTION := "settings"
const MUSIC_BUS := &"Soundtrack"

static var _music_volume := -1.0

static func get_music_volume() -> float:
	if _music_volume < 0.0:
		var config := ConfigFile.new()
		config.load(SAVE_PATH) # sem arquivo ainda: volume máximo
		_music_volume = clampf(float(config.get_value(SECTION, "music_volume", 1.0)), 0.0, 1.0)
	return _music_volume

# Aplica na hora (ao arrastar o slider). Use save() para gravar em disco.
static func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	apply()

static func apply() -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus < 0:
		return
	var volume := get_music_volume()
	AudioServer.set_bus_mute(bus, volume <= 0.0)
	if volume > 0.0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(volume))

static func save() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH) # mantém as outras configurações (ex.: skin)
	config.set_value(SECTION, "music_volume", get_music_volume())
	config.save(SAVE_PATH)
