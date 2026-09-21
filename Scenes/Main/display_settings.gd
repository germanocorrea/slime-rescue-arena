extends RefCounted

# Tela cheia: começa ligada, pode ser alternada nas configurações ou com F11, e a escolha é salva.

const SAVE_PATH := "user://settings.cfg"
const SECTION := "settings"

static var _fullscreen := true
static var _loaded := false

static func is_fullscreen() -> bool:
	if not _loaded:
		_loaded = true
		var config := ConfigFile.new()
		config.load(SAVE_PATH) # sem arquivo ainda: tela cheia
		_fullscreen = bool(config.get_value(SECTION, "fullscreen", true))
	return _fullscreen

static func set_fullscreen(enabled: bool) -> void:
	is_fullscreen() # garante que o valor salvo foi lido antes de sobrescrever
	_fullscreen = enabled
	apply()
	var config := ConfigFile.new()
	config.load(SAVE_PATH) # mantém as outras configurações
	config.set_value(SECTION, "fullscreen", _fullscreen)
	config.save(SAVE_PATH)

static func toggle() -> void:
	set_fullscreen(not is_fullscreen())

static func apply() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen() else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
