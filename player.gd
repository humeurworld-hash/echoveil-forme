extends CharacterBody2D

## Top-down 8-directional player — Echoveil: Rift

const SPEED          := 280.0
const DASH_SPEED     := 540.0
const DASH_DURATION  := 0.18
const DASH_COOLDOWN  := 0.65
const ATTACK_RANGE   := 80.0
const ATTACK_DAMAGE  := 1

var facing_dir   : Vector2 = Vector2.DOWN
var can_attack   : bool = true
var is_dead      : bool = false

# Dash
var _dashing       : bool    = false
var _dash_timer    : float   = 0.0
var _dash_cooldown : float   = 0.0
var _dash_dir      : Vector2 = Vector2.RIGHT
var _last_ghost    : float   = 0.0

# Hit state (two-hit system)
var hit_state    : int   = 0
var hit_cooldown : float = 0.0

# Shield
var fuse_shield      := false
var _shield_pulse    := 0.0
var _next_shield_at  := 5

# Speed boost
var _speed_boost_timer := 0.0

# Visual glow
var _glow_pulse     : float = 0.0
var _glow_particles : CPUParticles2D

@onready var body_sprite  : AnimatedSprite2D  = $AnimatedSprite2D
@onready var fuse_sprite  : AnimatedSprite2D  = $FuseSprite
@onready var camera       : Camera2D          = $Camera2D
@onready var swing_sound  : AudioStreamPlayer = AudioStreamPlayer.new()
@onready var strike_sound : AudioStreamPlayer = AudioStreamPlayer.new()
@onready var dash_sound   : AudioStreamPlayer = AudioStreamPlayer.new()

var shards_collected: int:
	get: return GameState.shards_collected
	set(v): GameState.shards_collected = v

var health: int:
	get: return GameState.health
	set(v): GameState.health = v

var lives: int:
	get: return GameState.lives
	set(v): GameState.lives = v

# ── Setup ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	TransitionLayer.fade_in(0.4)

	swing_sound.stream    = load("res://echoveil/music/animations/axe swing.mp3")
	swing_sound.volume_db = -15.0
	add_child(swing_sound)

	strike_sound.stream    = load("res://echoveil/music/animations/axe strike.mp3")
	strike_sound.volume_db = -10.0
	add_child(strike_sound)

	dash_sound.stream      = load("res://echoveil/music/animations/axe swing.mp3")
	dash_sound.volume_db   = -8.0
	dash_sound.pitch_scale = 1.8
	add_child(dash_sound)

	_set_idle_pose()
	fuse_sprite.play(&"blank")
	fuse_sprite.modulate = Color(0.6, 0.6, 0.6, 1.0)

	# ── Idle mourk-crack glow particles ──────────────────────────────────────
	_glow_particles                      = CPUParticles2D.new()
	_glow_particles.position             = Vector2(-62, 0)
	_glow_particles.emitting             = true
	_glow_particles.one_shot             = false
	_glow_particles.amount               = 6
	_glow_particles.lifetime             = 1.4
	_glow_particles.direction            = Vector2(0.0, -1.0)
	_glow_particles.spread               = 145.0
	_glow_particles.initial_velocity_min = 12.0
	_glow_particles.initial_velocity_max = 30.0
	_glow_particles.gravity              = Vector2(0.0, -30.0)
	_glow_particles.scale_amount_min     = 1.5
	_glow_particles.scale_amount_max     = 3.2
	_glow_particles.color                = Color(0.18, 0.95, 0.88, 0.7)
	add_child(_glow_particles)

# ── Per-frame ─────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if is_dead: return
	_glow_pulse += delta * 2.1
	queue_redraw()

	var t := Time.get_ticks_msec() / 1000.0
	fuse_sprite.position.y = -75.0 + sin(t * 2.5) * 8.0
	fuse_sprite.position.x = -50.0 if facing_dir.x >= 0.0 else 50.0
	fuse_sprite.flip_h     = facing_dir.x < 0.0

	if not fuse_shield and shards_collected >= _next_shield_at:
		_next_shield_at += 5
		_activate_shield()
	if fuse_shield:
		_shield_pulse += delta * 3.2

# ── Physics ───────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if is_dead: return
	if GameState.health <= 0:
		_die()
		return

	if hit_cooldown       > 0: hit_cooldown       -= delta
	if _dash_cooldown     > 0: _dash_cooldown     -= delta
	if _speed_boost_timer > 0: _speed_boost_timer -= delta

	# ── Dash override ─────────────────────────────────────────────────────────
	if _dashing:
		_dash_timer -= delta
		velocity = _dash_dir * DASH_SPEED
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_ghost >= 0.04:
			_last_ghost = now
			_spawn_ghost()
		if _dash_timer <= 0.0:
			_dashing = false
			velocity *= 0.3
		move_and_slide()
		return

	# ── Input ─────────────────────────────────────────────────────────────────
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		facing_dir = dir.normalized()

	if Input.is_action_just_pressed("dash") and _dash_cooldown <= 0:
		_start_dash(dir if dir != Vector2.ZERO else facing_dir)

	if Input.is_action_just_pressed("swing") and can_attack:
		_swing_attack()

	# ── Movement ──────────────────────────────────────────────────────────────
	var boost := 1.65 if _speed_boost_timer > 0 else 1.0
	if dir != Vector2.ZERO:
		velocity = dir.normalized() * SPEED * boost
		var anim : StringName = _dir_anim(dir)
		body_sprite.flip_h = (anim == &"run" and dir.x < 0)
		if body_sprite.animation != anim:
			body_sprite.play(anim)
			_apply_sprite_scale(anim)
		elif not body_sprite.is_playing():
			body_sprite.play(body_sprite.animation)   # resume after idle-pause
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * 4.0 * delta)
		if velocity.length() < 10.0:
			_set_idle_pose()

	move_and_slide()

# ── Dash ──────────────────────────────────────────────────────────────────────
func _start_dash(dir: Vector2) -> void:
	if _dashing: return
	_dashing       = true
	_dash_timer    = DASH_DURATION
	_dash_cooldown = DASH_COOLDOWN
	_dash_dir      = dir.normalized() if dir != Vector2.ZERO else facing_dir
	body_sprite.flip_h = _dash_dir.x < 0
	dash_sound.play()
	shake_camera(2.5, 0.12)
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color(0.5, 1.0, 1.3, 1.0), 0.04)
	tw.tween_property(body_sprite, "modulate", Color.WHITE, DASH_DURATION)

func _spawn_ghost() -> void:
	var frames := body_sprite.sprite_frames
	if not frames: return
	var tex := frames.get_frame_texture(body_sprite.animation, body_sprite.frame)
	if not tex: return
	var ghost          := Sprite2D.new()
	ghost.texture         = tex
	ghost.flip_h          = body_sprite.flip_h
	ghost.scale           = body_sprite.scale
	ghost.global_position = body_sprite.global_position
	ghost.modulate        = Color(0.25, 0.80, 1.0, 0.48)
	ghost.z_index         = -1
	get_parent().add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_callback(ghost.queue_free)

# ── Attack ────────────────────────────────────────────────────────────────────
func _swing_attack() -> void:
	can_attack = false
	swing_sound.play()
	body_sprite.play(&"swing")
	_apply_sprite_scale(&"swing")
	fuse_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	fuse_sprite.play(&"react")

	var swing_dir := facing_dir if facing_dir != Vector2.ZERO else Vector2.RIGHT
	var hit_pos   := global_position + Vector2(-62.0, 0.0) + swing_dir * ATTACK_RANGE
	var space     := get_world_2d().direct_space_state
	var shape     := CircleShape2D.new()
	shape.radius  = 28.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape               = shape
	query.transform           = Transform2D(0.0, hit_pos)
	query.collision_mask      = 2
	query.collide_with_bodies = true
	query.collide_with_areas  = true
	var results := space.intersect_shape(query)

	if results.size() > 0:
		strike_sound.play()
		shake_camera(3.5, 0.15)
		_burst(hit_pos, Color(1.0, 0.88, 0.3, 1.0), 10, 260.0, 0.28, 55.0, swing_dir)

	for r in results:
		var body = r.collider
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)

	await get_tree().create_timer(0.3).timeout
	can_attack = true
	fuse_sprite.play(&"blank")
	fuse_sprite.modulate = Color(0.6, 0.6, 0.6, 1.0)
	_set_idle_pose()

# ── Drawing ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	if is_dead: return
	var center := Vector2(-62.0, 10.0)
	var g := 0.14 + sin(_glow_pulse) * 0.06
	draw_arc(center, 60, 0, TAU, 32, Color(0.08, 0.78, 0.72, g * 0.55), 9.0)
	draw_arc(center, 50, 0, TAU, 32, Color(0.22, 0.96, 0.90, g * 1.1),  2.5)
	draw_circle(Vector2(-62.0, 18.0), 20.0, Color(0.0, 0.0, 0.0, 0.22))
	if fuse_shield:
		var a := 0.22 + sin(_shield_pulse) * 0.12
		draw_circle(center, 70, Color(0.18, 0.82, 1.0, a * 0.55))
		draw_arc(center, 70, 0, TAU, 40, Color(0.35, 1.0, 1.0, a + 0.18), 3.0)
		draw_arc(center, 62, 0, TAU, 40, Color(0.55, 1.0, 1.0, a * 0.7),  1.5)

func _burst(pos: Vector2, color: Color, count: int, spd: float, life: float,
			spread_deg: float = 180.0, dir: Vector2 = Vector2(0, -1)) -> void:
	var p := CPUParticles2D.new()
	p.global_position      = pos
	p.one_shot             = true
	p.explosiveness        = 1.0
	p.emitting             = true
	p.amount               = count
	p.lifetime             = life
	p.direction            = dir
	p.spread               = spread_deg
	p.initial_velocity_min = spd * 0.4
	p.initial_velocity_max = spd
	p.gravity              = Vector2.ZERO
	p.scale_amount_min     = 2.5
	p.scale_amount_max     = 5.5
	p.color                = color
	get_parent().add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(life + 0.15)
	tw.tween_callback(p.queue_free)

# ── Hit / damage ──────────────────────────────────────────────────────────────
func hit_by_drone() -> void:
	if hit_cooldown > 0 or is_dead or _dashing: return
	if fuse_shield:
		_break_shield()
		return
	if hit_state == 0:
		hit_state    = 1
		hit_cooldown = 1.8
		shake_camera(4.0, 0.25)
		_stun_flash()
		fuse_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		fuse_sprite.play(&"panic")
		await get_tree().create_timer(0.6).timeout
		if not is_dead:
			fuse_sprite.play(&"blank")
			fuse_sprite.modulate = Color(0.6, 0.6, 0.6, 1.0)
	else:
		hit_state    = 0
		hit_cooldown = 1.5
		GameState.health = max(0, GameState.health - 1)
		shake_camera(7.0, 0.35)
		_damage_flash()

func _stun_flash() -> void:
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color(1.3, 0.65, 0.05, 1.0), 0.07)
	tw.tween_property(body_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)

func _damage_flash() -> void:
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color(1.0, 0.15, 0.15, 1.0), 0.07)
	tw.tween_property(body_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)
	_screen_flash(Color(1, 0, 0, 0.32))

# ── Shard ability hooks ───────────────────────────────────────────────────────
func boost_speed(duration: float) -> void:
	_speed_boost_timer = duration
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color(1.4, 0.65, 0.15, 1.0), 0.08)
	tw.tween_property(body_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), duration - 0.1)

func add_shield_progress(extra: int) -> void:
	_next_shield_at = max(shards_collected + 1, _next_shield_at - extra)

func force_shield() -> void:
	if not fuse_shield:
		_next_shield_at = shards_collected + 999
		_activate_shield()

func _activate_shield() -> void:
	fuse_shield   = true
	_shield_pulse = 0.0
	queue_redraw()
	fuse_sprite.modulate = Color(0.25, 0.92, 1.0, 1.0)
	fuse_sprite.play(&"react")
	_screen_flash(Color(0.18, 0.82, 1.0, 0.22))
	await get_tree().create_timer(0.45).timeout
	if not is_dead and fuse_shield:
		fuse_sprite.play(&"blank")
		fuse_sprite.modulate = Color(0.25, 0.92, 1.0, 1.0)

func _break_shield() -> void:
	fuse_shield  = false
	hit_cooldown = 0.7
	queue_redraw()
	shake_camera(3.5, 0.2)
	_screen_flash(Color(0.18, 0.82, 1.0, 0.45))
	fuse_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	fuse_sprite.play(&"react")
	await get_tree().create_timer(0.5).timeout
	if not is_dead:
		fuse_sprite.play(&"blank")
		fuse_sprite.modulate = Color(0.6, 0.6, 0.6, 1.0)

func shake_camera(intensity: float = 8.0, duration: float = 0.35) -> void:
	var steps := 8
	var tw    := create_tween()
	for i in range(steps):
		tw.tween_property(camera, "offset",
			Vector2(randf_range(-intensity, intensity),
					randf_range(-intensity, intensity)),
			duration / steps)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func _die() -> void:
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	fuse_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	fuse_sprite.play(&"panic")
	_set_idle_pose()
	shake_camera(10.0, 0.5)
	_screen_flash(Color(1, 0, 0, 0.58))
	if GameState.lives > 0:
		GameState.lives  -= 1
		GameState.health  = 3
		var scene_path := get_tree().current_scene.scene_file_path
		await get_tree().create_timer(1.5).timeout
		TransitionLayer.fade_out(
			func(): get_tree().call_deferred("change_scene_to_file", scene_path), 0.4)
	else:
		await get_tree().create_timer(1.8).timeout
		TransitionLayer.fade_out(
			func(): get_tree().call_deferred("change_scene_to_file", "res://game_over.tscn"), 0.5)

## Swap body_sprite scale to match the source image dimensions.
## Atlas frames are cropped to ~220×210 px; the new walk PNGs are 1122×1402.
## Scale factor: 220/1122 × 0.60 (original atlas scale) ≈ 0.118
const SCALE_ATLAS : Vector2 = Vector2(0.60,  0.60)
# New walk PNGs are 1122×1402.  Target display ~264×252 px (2× the atlas size).
# 264/1122 ≈ 0.235 wide,  252/1402 ≈ 0.180 tall.
const SCALE_WALK  : Vector2 = Vector2(0.235, 0.180)

func _apply_sprite_scale(anim: StringName) -> void:
	var new_anims := [&"walk_down", &"walk_up", &"walk_left", &"walk_right", &"idle"]
	body_sprite.scale = SCALE_WALK if anim in new_anims else SCALE_ATLAS

## Freeze the walk animation for the current facing direction as a static idle pose.
func _set_idle_pose() -> void:
	var anim : StringName = _dir_anim(facing_dir)
	if body_sprite.animation != anim:
		body_sprite.play(anim)
		_apply_sprite_scale(anim)
	if body_sprite.is_playing():
		body_sprite.pause()
		body_sprite.frame = 0

## Returns the best directional animation for the given movement vector.
## Falls back to "run" if the walk_* animations aren't loaded yet.
func _dir_anim(dir: Vector2) -> StringName:
	var sf := body_sprite.sprite_frames
	if abs(dir.y) >= abs(dir.x):
		var anim : StringName = &"walk_down" if dir.y > 0 else &"walk_up"
		if sf != null and sf.has_animation(anim): return anim
	else:
		var anim : StringName = &"walk_right" if dir.x > 0 else &"walk_left"
		if sf != null and sf.has_animation(anim): return anim
	return &"run"

func _screen_flash(color: Color) -> void:
	var fl := CanvasLayer.new()
	fl.layer = 30
	get_parent().add_child(fl)
	var rect := ColorRect.new()
	rect.color = Color(color.r, color.g, color.b, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(rect)
	var tw := create_tween()
	tw.tween_property(rect, "color", color, 0.25)
	tw.tween_property(rect, "color", Color(color.r, color.g, color.b, color.a * 0.45), 1.2)
	tw.tween_callback(fl.queue_free)
