extends RefCounted

# Skins do player: cada skin é uma célula da spritesheet SlimeSkins (corpo, 230x230, 3 colunas)
# e da ArrowSheet (seta, 15x15). A skin dourada usa a Arrow_gold.png. O índice da skin é o
# índice da célula. A skin escolhida é salva em disco e vale para todas as fases.
# Cada skin exige uma quantidade mínima de estrelas (somadas em todas as fases) para ser usada.

const SAVE_PATH := "user://settings.cfg"
const SECTION := "settings"

const SLIME_SHEET = preload("res://assets/Skins/SlimeSkins.png")
const ARROW_SHEET = preload("res://assets/Skins/ArrowSheet.png")
const GOLD_ARROW = preload("res://assets/Skins/Arrow_gold.png")
const SLIME_CELL := 230
const ARROW_CELL := 15
const COLUMNS := 3
const SKIN_NAMES: Array[String] = ["Ciano", "Roxo", "Laranja", "Vermelho", "Verde", "Amarelo", "Dourado"]
const GOLDEN_SKIN := 6 # deixa um rastro de partículas douradas
# Estrelas necessárias para cada skin (na ordem de SKIN_NAMES)
const STARS_REQUIRED: Array[int] = [0, 5, 2, 5, 2, 2, 8]
# Andares da torre de skins, de baixo para cima (cada número é o índice de uma skin)
const TOWER: Array = [[0], [5, 2, 4], [3, 1], [6]]

static var _selected := -1
static var _slime_textures := {}

static func get_selected() -> int:
	if _selected < 0:
		var config := ConfigFile.new()
		config.load(SAVE_PATH) # sem arquivo ainda: usa a skin padrão (0)
		_selected = clampi(int(config.get_value(SECTION, "skin", 0)), 0, SKIN_NAMES.size() - 1)
	return _selected

static func set_selected(index: int) -> void:
	_selected = clampi(index, 0, SKIN_NAMES.size() - 1)
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION, "skin", _selected)
	config.save(SAVE_PATH)

static func _cell_rect(index: int, cell: int) -> Rect2i:
	return Rect2i((index % COLUMNS) * cell, floori(index / float(COLUMNS)) * cell, cell, cell)

# Textura própria de 230x230 (recortada da sheet), no formato que o SoftBody2D espera.
static func slime_texture(index: int) -> Texture2D:
	if not _slime_textures.has(index):
		var image := SLIME_SHEET.get_image().get_region(_cell_rect(index, SLIME_CELL))
		_slime_textures[index] = ImageTexture.create_from_image(image)
	return _slime_textures[index]

static func arrow_texture(index: int) -> Texture2D:
	if index == GOLDEN_SKIN:
		return GOLD_ARROW
	var atlas := AtlasTexture.new()
	atlas.atlas = ARROW_SHEET
	atlas.region = Rect2(_cell_rect(index, ARROW_CELL))
	return atlas
