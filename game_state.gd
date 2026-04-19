extends Node

var shards_collected: int = 0
var health: int = 3
var lives: int = 0
const SAVE_PATH = "user://echoveil_save.json"

func save() -> void:
	var data = {
		"shards": shards_collected,
		"health": health,
		"lives": lives
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary:
			shards_collected = data.get("shards", 0)
			health = data.get("health", 3)
			lives = data.get("lives", 0)

func reset() -> void:
	shards_collected = 0
	health = 3
	lives = 0
