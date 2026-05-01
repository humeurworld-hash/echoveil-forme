extends StaticBody2D

# -1 = plain rock (drops 2 random teal shards)
# 0=TEAL  1=GREEN  2=ORANGE  3=PURPLE  4=GOLD
@export var hidden_shard: int = -1

var health: int = 2
var shard_scene: PackedScene = null

func _ready() -> void:
	shard_scene = load("res://shard.tscn")
	# Give a subtle visual hint that this rock has something inside
	if hidden_shard >= 0:
		_apply_gem_glow()

func _apply_gem_glow() -> void:
	# Faint pulsing tint so players notice special rocks
	const TINTS := [
		Color(0.55, 1.10, 1.05),   # TEAL
		Color(0.55, 1.15, 0.65),   # GREEN
		Color(1.15, 0.80, 0.45),   # ORANGE
		Color(0.95, 0.60, 1.20),   # PURPLE
		Color(1.20, 1.10, 0.40),   # GOLD
	]
	var col: Color = TINTS[hidden_shard]
	var spr: Node = get_node_or_null("Sprite2D")
	if not spr:
		return
	var tw := create_tween().set_loops(-1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(spr, "modulate", col, 1.1)
	tw.tween_property(spr, "modulate", Color.WHITE, 1.1)

func take_damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		spawn_shards()
		queue_free()
		return

	# Shake on hit
	var tween = create_tween()
	tween.tween_property(self, "position",
		position + Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.05)
	tween.tween_property(self, "position",
		position, 0.05)

func spawn_shards() -> void:
	var break_sound = AudioStreamPlayer.new()
	break_sound.stream = load("res://echoveil/music/animations/Rock break.mp3")
	get_parent().add_child(break_sound)
	break_sound.play()
	break_sound.finished.connect(break_sound.queue_free)

	if hidden_shard >= 0:
		# Drop the specific hidden gem — single, centered
		if shard_scene:
			var shard = shard_scene.instantiate()
			shard.position = global_position + Vector2(0, -24)
			shard.set("shard_type", hidden_shard)
			get_parent().add_child(shard)
	else:
		# Plain rock — drop 2 random teal shards
		for i in range(2):
			if shard_scene:
				var shard = shard_scene.instantiate()
				shard.position = global_position + Vector2(
					randf_range(-15, 15), randf_range(-10, 0))
				get_parent().add_child(shard)
