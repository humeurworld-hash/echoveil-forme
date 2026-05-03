extends StaticBody2D

# -1 = plain rock (drops 2 random teal shards)
# 0=TEAL  1=GREEN  2=ORANGE  3=PURPLE  4=GOLD
@export var hidden_shard: int = -1

var health: int = 2
var shard_scene: PackedScene = null

func _ready() -> void:
	shard_scene = load("res://shard.tscn")
	if hidden_shard >= 0:
		_apply_gem_glow()

func _apply_gem_glow() -> void:
	const TINTS := [
		Color(0.55, 1.10, 1.05),  # TEAL
		Color(0.55, 1.15, 0.65),  # GREEN
		Color(1.15, 0.80, 0.45),  # ORANGE
		Color(1.30, 0.15, 1.50),  # PURPLE — Prime Mourk: vivid magenta, unmissably distinct
		Color(1.20, 1.10, 0.40),  # GOLD
	]
	var spr: Node = get_node_or_null("Sprite2D")
	if not spr:
		return
	var tw := create_tween().set_loops(-1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(spr, "modulate", TINTS[hidden_shard], 1.1)
	tw.tween_property(spr, "modulate", Color.WHITE, 1.1)

func take_damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		spawn_shards()
		queue_free()
		return

	# Shake + small chip particles on partial hit
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("shake_camera"):
		player.shake_camera(1.5, 0.08)
	_chip_particles(4)

	var tween = create_tween()
	tween.tween_property(self, "position",
		position + Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.05)
	tween.tween_property(self, "position", position, 0.05)

func spawn_shards() -> void:
	# ── Sound ─────────────────────────────────────────────────────────────────
	var break_sound = AudioStreamPlayer.new()
	break_sound.stream = load("res://echoveil/music/animations/Rock break.mp3")
	get_parent().add_child(break_sound)
	break_sound.play()
	break_sound.finished.connect(break_sound.queue_free)

	# ── Camera shake ──────────────────────────────────────────────────────────
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("shake_camera"):
		player.shake_camera(5.5, 0.28)

	# ── Explosion particles ───────────────────────────────────────────────────
	_chip_particles(22)

	# ── Gem drop ──────────────────────────────────────────────────────────────
	if hidden_shard >= 0:
		const GEM_COLORS := [
			Color(0.15, 0.90, 0.92),  # TEAL
			Color(0.35, 0.95, 0.50),  # GREEN
			Color(1.00, 0.60, 0.15),  # ORANGE
			Color(0.92, 0.12, 1.00),  # PURPLE — Prime Mourk vivid magenta
			Color(1.00, 0.85, 0.15),  # GOLD
		]
		# Gem sparkle burst in the gem's color
		_gem_burst(GEM_COLORS[hidden_shard])
		if shard_scene:
			var shard = shard_scene.instantiate()
			shard.position = global_position + Vector2(0, -24)
			shard.set("shard_type", hidden_shard)
			get_parent().add_child(shard)
	else:
		for i in range(2):
			if shard_scene:
				var shard = shard_scene.instantiate()
				shard.position = global_position + Vector2(
					randf_range(-15, 15), randf_range(-10, 0))
				get_parent().add_child(shard)

func _chip_particles(count: int) -> void:
	var p := CPUParticles2D.new()
	p.global_position      = global_position
	p.one_shot             = true
	p.explosiveness        = 1.0
	p.emitting             = true
	p.amount               = count
	p.lifetime             = 0.55
	p.direction            = Vector2(0.0, -1.0)
	p.spread               = 140.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 280.0
	p.gravity              = Vector2(0.0, 600.0)
	p.scale_amount_min     = 2.0
	p.scale_amount_max     = 6.0
	p.color                = Color(0.52, 0.42, 0.32, 1.0)
	get_parent().add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(0.75)
	tw.tween_callback(p.queue_free)

func _gem_burst(color: Color) -> void:
	var p := CPUParticles2D.new()
	p.global_position      = global_position + Vector2(0, -20)
	p.one_shot             = true
	p.explosiveness        = 1.0
	p.emitting             = true
	p.amount               = 18
	p.lifetime             = 0.65
	p.direction            = Vector2(0.0, -1.0)
	p.spread               = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 200.0
	p.gravity              = Vector2(0.0, 320.0)
	p.scale_amount_min     = 3.0
	p.scale_amount_max     = 7.0
	p.color                = color
	get_parent().add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(0.85)
	tw.tween_callback(p.queue_free)
