extends RefCounted

# Volumes da música (bus "Soundtrack") e dos sons (bus "SFX"), de 0.0 (mudo) a 1.0
# (volume original do bus). Os valores são salvos em disco e aplicados ao abrir o jogo.

const SAVE_PATH := "user://settings.cfg"
const SECTION := "settings"
const MUSIC_BUS := &"Soundtrack"
const SFX_BUS := &"SFX"

static var _music_volume := -1.0
static var _sfx_volume := -1.0
static var _base_db := {} # volume original de cada bus, definido no layout de áudio

static func _load(key: String) -> float:
	var config := ConfigFile.new()
	config.load(SAVE_PATH) # sem arquivo ainda: volume máximo
	return clampf(float(config.get_value(SECTION, key, 1.0)), 0.0, 1.0)

static func get_music_volume() -> float:
	if _music_volume < 0.0:
		_music_volume = _load("music_volume")
	return _music_volume

static func get_sfx_volume() -> float:
	if _sfx_volume < 0.0:
		_sfx_volume = _load("sfx_volume")
	return _sfx_volume

# Aplica na hora (ao arrastar o slider). Use save() para gravar em disco.
static func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	apply()

static func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	apply()

static func apply() -> void:
	_apply_bus(MUSIC_BUS, get_music_volume())
	_apply_bus(SFX_BUS, get_sfx_volume())

static func _apply_bus(bus_name: StringName, volume: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	if not _base_db.has(bus_name):
		_base_db[bus_name] = AudioServer.get_bus_volume_db(bus)
	AudioServer.set_bus_mute(bus, volume <= 0.0)
	if volume > 0.0:
		AudioServer.set_bus_volume_db(bus, _base_db[bus_name] + linear_to_db(volume))

static func save() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH) # mantém as outras configurações (ex.: skin)
	config.set_value(SECTION, "music_volume", get_music_volume())
	config.set_value(SECTION, "sfx_volume", get_sfx_volume())
	config.save(SAVE_PATH)
