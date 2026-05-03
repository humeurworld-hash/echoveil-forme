extends Node

var shards_collected : int  = 0   # gold / mourk fragments
var health           : int  = 3
var lives            : int  = 0
var current_level    : int  = 1
var xp               : int  = 0
var player_level     : int  = 1
var gold             : int  = 0

# Abilities (all standard)
var has_double_jump  : bool = true
var has_roll         : bool = false

const SAVE_PATH = "user://echoveil_rift_save.json"

# XP threshold to reach the next level
func xp_to_next() -> int:
	return player_level * 50

func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp          -= xp_to_next()
		player_level += 1
		health        = 3   # full heal on level-up

func save() -> void:
	var data := {
		"shards":          shards_collected,
		"health":          health,
		"lives":           lives,
		"current_level":   current_level,
		"xp":              xp,
		"player_level":    player_level,
		"gold":            gold,
		"has_double_jump": has_double_jump,
		"has_roll":        has_roll,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary:
			shards_collected = data.get("shards",          0)
			health           = data.get("health",          3)
			lives            = data.get("lives",           0)
			current_level    = data.get("current_level",   1)
			xp               = data.get("xp",              0)
			player_level     = data.get("player_level",    1)
			gold             = data.get("gold",            0)
			has_double_jump  = data.get("has_double_jump", true)
			has_roll         = data.get("has_roll",        false)
			LevelManager.current_level = current_level

func reset() -> void:
	shards_collected = 0
	health           = 3
	lives            = 0
	current_level    = 1
	xp               = 0
	player_level     = 1
	gold             = 0
	has_double_jump  = true
	has_roll         = false
