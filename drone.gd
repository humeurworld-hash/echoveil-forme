extends Area2D

## Top-down Stalker — patrols in 8 directions, chases player when in range.

@export var drops_shard  : bool  = false
@export var chase_radius : float = 260.0

var patrol_speed : float = 75.0
var chase_speed  : float = 165.0

var _patrol_dir  : Vector2 = Vector2.RIGHT
var _patrol_time : float   = 0.0
var _hover_t     : float   = 0.0

var damage_cooldown : float = 0.0
var stunned         : bool  = false
var stun_timer      : float = 0.0
var stun_tween      : Tween = null

var glitching    : bool  = false
var glitch_timer : float = 0.0
var glitch_tick  : float = 0.0

func _ready() -> void:
	add_to_group("drone")
	_patrol_dir  = Vector2(cos(randf() * TAU), sin(randf() * TAU)).normalized()
	_hover_t     = randf() * TAU
	_patrol_time = randf_range(1.5, 3.2)

func _process(delta: float) -> void:
	if damage_cooldown > 0: damage_cooldown -= delta
	_hover_t += delta * 2.5

	# ── Glitch ────────────────────────────────────────────────────────────────
	if glitching:
		glitch_timer -= delta
		glitch_tick  -= delta
		if glitch_tick <= 0:
			glitch_tick = 0.055
			position   += Vector2(randf_range(-7, 7), randf_range(-6, 6))
			modulate    = Color(randf_range(0.1, 1.0), randf_range(0.1, 1.0), randf_range(0.1, 1.0), 0.8)
		if glitch_timer <= 0:
			glitching = false
			modulate  = Color.WHITE
		return

	if stunned:
		stun_timer -= delta
		if stun_timer <= 0: _end_stun()
		return

	# ── Determine if chasing ──────────────────────────────────────────────────
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var chasing := false
	if player and is_instance_valid(player):
		chasing = global_position.distance_to(player.global_position) < chase_radius

	if chasing and player and is_instance_valid(player):
		var to_pl := (player.global_position - global_position).normalized()
		global_position  += to_pl * chase_speed * delta
		$Sprite2D.flip_h  = to_pl.x < 0
	else:
		_patrol_time -= delta
		if _patrol_time <= 0:
			_patrol_time = randf_range(1.5, 3.2)
			_patrol_dir  = Vector2(cos(randf() * TAU), sin(randf() * TAU)).normalized()
		global_position  += _patrol_dir * patrol_speed * delta
		$Sprite2D.flip_h  = _patrol_dir.x < 0

	# Gentle vertical bob
	global_position.y += sin(_hover_t) * 0.5

	# ── Contact damage ────────────────────────────────────────────────────────
	if damage_cooldown <= 0:
		for body in get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("hit_by_drone"):
				body.hit_by_drone()
				damage_cooldown = 0.25
				break

func activate_chase() -> void:
	pass  # proximity-based now; kept for compatibility

func stun(duration: float) -> void:
	if stun_tween: stun_tween.kill()
	stunned    = true
	stun_timer = duration
	var loops  : int = max(1, int(duration / 0.3))
	stun_tween = create_tween().set_loops(loops)
	stun_tween.tween_property(self, "modulate", Color(0.4, 0.6, 1.0, 0.6), 0.15)
	stun_tween.tween_property(self, "modulate", Color(0.6, 0.8, 1.0, 0.4), 0.15)

func _end_stun() -> void:
	stunned    = false
	stun_timer = 0.0
	if stun_tween: stun_tween.kill(); stun_tween = null
	modulate = Color.WHITE

func take_damage(_amount: int) -> void:
	if stunned: return
	glitching    = true
	glitch_timer = 0.7
	glitch_tick  = 0.0
	if drops_shard: _drop_shard()
	GameState.add_xp(8)
	await get_tree().create_timer(0.78).timeout
	if is_instance_valid(self):
		queue_free()

func _drop_shard() -> void:
	var sc := load("res://shard.tscn") as PackedScene
	if sc:
		var s := sc.instantiate()
		s.global_position = global_position
		get_parent().add_child(s)
