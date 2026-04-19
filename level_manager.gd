extends Node

var current_level: int = 1
var shard_count: int = 0
var player_health: int = 3
var prime_mourk_broken: bool = false

func go_to_level(level_number: int) -> void:
	current_level = level_number
	match level_number:
		1: get_tree().change_scene_to_file("res://level1.tscn")
		2: get_tree().change_scene_to_file("res://level2.tscn")
		3: get_tree().change_scene_to_file("res://level3.tscn")
		4: get_tree().change_scene_to_file("res://level4.tscn")

func trigger_boss_event() -> void:
	prime_mourk_broken = true
	var drones = get_tree().get_nodes_in_group("drone")
	for drone in drones:
		if drone.has_method("activate_chase"):
			drone.activate_chase()

func add_shards(amount: int) -> void:
	shard_count += amount

func take_damage() -> int:
	player_health -= 1
	return player_health
