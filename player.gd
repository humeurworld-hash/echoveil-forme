extends CharacterBody2D

const SPEED = 300.0
const JUMP_FORCE = -600.0
const GRAVITY = 980.0
const PICKAXE_RANGE = 80.0
const PICKAXE_DAMAGE = 1
const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12

var can_swing: bool = true
var facing_right: bool = true
var can_break: bool = true
var is_dead: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var is_jumping: bool = false

# Hit system
var hit_state: int = 0
var hit_cooldown: float = 0.0
var stun_move_penalty: float = 0.0

# Fuse shield — activates every 5 Mourks collected
var fuse_shield := false
var _shield_pulse := 0.0
var _next_shield_at := 5

# Orange mourk speed boost
var _speed_boost_timer := 0.0

@onready var body_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fuse_sprite: AnimatedSprite2D = $FuseSprite
@onready var camera: Camera2D = $Camera2D
@onready var swing_sound: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var strike_sound: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var lightning_sound: AudioStreamPlayer = AudioStreamPlayer.new()

var shards_collected: int:
	get: return GameState.shards_collected
	set(v): GameState.shards_collected = v

var health: int:
	get: return GameState.health
	set(v): GameState.health = v

var lives: int:
	get: return GameState.lives
	set(v): GameState.lives = v

func _ready() -> void:
	add_to_group("player")
	TransitionLayer.fade_in(0.4)

	swing_sound.stream = load("res://echoveil/music/animations/axe swing.mp3")
	swing_sound.volume_db = -15.0
	add_child(swing_sound)

	strike_sound.stream = load("res://echoveil/music/animations/axe strike.mp3")
	strike_sound.volume_db = -10.0
	add_child(strike_sound)

	lightning_sound.stream = load("res://echoveil/music/animations/axe strike.mp3")
	lightning_sound.volume_db = -5.0
	add_child(lightning_sound)

	body_sprite.play(&"idle")
	fuse_sprite.play(&"blank")
	fuse_sprite.modulate = Color(0.6, 0.6, 0.6, 1.0)

func _process(delta: float) -> void:
	if is_dead:
		return
	var time = Time.get_ticks_msec() / 1000.0
	# Hover behind Forme — left shoulder when facing right, right shoulder when facing left
	fuse_sprite.position.y = -55 + sin(time * 2.5) * 8
	fuse_sprite.position.x = -50 if facing_right else 50
	fuse_sprite.flip_h = not facing_right

	# Shield charge check — every 5 Mourks earns a fresh shield
	if not fuse_shield and shards_collected >= _next_shield_at:
		_next_shield_at += 5
		_activate_shield()

	# Pulse the shield ring
	if fuse_shield:
		_shield_pulse += delta * 3.2
		queue_redraw()

func _draw() -> void:
	if not fuse_shield:
		return
	var a := 0.22 + sin(_shield_pulse) * 0.12
	var center := Vector2(-62, 10)
	draw_circle(center, 70, Color(0.18, 0.82, 1.0, a * 0.55))
	draw_arc(center, 70, 0, TAU, 40, Color(0.35, 1.0, 1.0, a + 0.18), 3.0)
	draw_arc(center, 62, 0, TAU, 40, Color(0.55, 1.0, 1.0, a * 0.7), 1.5)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if GameState.health <= 0:
		_die()
		return

	if hit_cooldown > 0:
		hit_cooldown -= delta
	if stun_move_penalty > 0:
		stun_move_penalty -= delta

	var on_floor = is_on_floor()
	if on_floor:
		coyote_timer = COYOTE_TIME
		if not was_on_floor:
			_on_land()
	elif coyote_timer > 0:
		coyote_timer -= delta
	was_on_floor = on_floor

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	elif jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	if not on_floor:
		velocity.y += GRAVITY * delta

	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_FORCE
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		is_jumping = true

	if is_jumping and Input.is_action_just_released("jump") and velocity.y < -200:
		velocity.y *= 0.45
		is_jumping = false

	if on_floor:
		is_jumping = false

	if _speed_boost_timer > 0:
		_speed_boost_timer -= delta

	var boost_mult := 1.65 if _speed_boost_timer > 0 else 1.0
	var move_speed = SPEED * boost_mult * (0.45 if stun_move_penalty > 0 else 1.0)
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * move_speed
		facing_right = direction > 0
		body_sprite.flip_h = not facing_right
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 0.3)

	if can_swing:
		if abs(velocity.x) > 10:
			if body_sprite.animation != &"run":
				body_sprite.play(&"run")
		elif on_floor:
			if body_sprite.animation != &"idle":
				body_sprite.play(&"idle")

	if Input.is_action_just_pressed("swing") and can_swing:
		swing_pickaxe()

	if Input.is_action_just_pressed("break_power") and GameState.lives >= 3 and can_break:
		_lightning_strike()

	move_and_slide()

func hit_by_drone() -> void:
	if hit_cooldown > 0 or is_dead:
		return

	# Fuse shield absorbs the hit
	if fuse_shield:
		_break_shield()
		return

	if hit_state == 0:
		hit_state = 1
		hit_cooldown = 1.8
		stun_move_penalty = 0.65
		shake_camera(4.0, 0.25)
		_stun_flash()
		fuse_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		fuse_sprite.play(&"panic")
		await get_tree().create_timer(0.6).timeout
		if not is_dead:
			fuse_sprite.play(&"blank")
			fuse_sprite.modulate = Color(0.6, 0.6, 0.6, 1.0)
	else:
		hit_state = 0
		hit_cooldown = 1.5
		GameState.health = max(0, GameState.health - 1)
		shake_camera(7.0, 0.35)
		_damage_flash()

func _stun_flash() -> void:
	var tween = create_tween()
	tween.tween_property(body_sprite, "modulate", Color(1.3, 0.65, 0.05, 1.0), 0.07)
	tween.tween_property(body_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)

func _damage_flash() -> void:
	var tween = create_tween()
	tween.tween_property(body_sprite, "modulate", Color(1.0, 0.15, 0.15, 1.0), 0.07)
	tween.tween_property(body_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)
	_screen_flash(Color(1, 0, 0, 0.32))

func _on_land() -> void:
	var tween = create_tween()
	tween.tween_property(body_sprite, "scale", Vector2(0.64, 0.41), 0.06)
	tween.tween_property(body_sprite, "scale", Vector2(0.48, 0.57), 0.05)
	tween.tween_property(body_sprite, "scale", Vector2(0.52, 0.52), 0.09)

func shake_camera(intensity: float = 8.0, duration: float = 0.35) -> void:
	var steps := 8
	var tween = create_tween()
	for i in range(steps):
		tween.tween_property(camera, "offset",
			Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)),
			duration / steps)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func _die() -> void:
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO

	fuse_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	fuse_sprite.play(&"panic")
	body_sprite.play(&"idle")

	_screen_flash(Color(1, 0, 0, 0.58))

	if GameState.lives > 0:
		GameState.lives -= 1
		GameState.health = 3
		var scene_path = get_tree().current_scene.scene_file_path
		await get_tree().create_timer(1.5).timeout
		TransitionLayer.fade_out(
			func(): get_tree().call_deferred("change_scene_to_file", scene_path),
			0.4
		)
	else:
		await get_tree().create_timer(1.8).timeout
		TransitionLayer.fade_out(
			func(): get_tree().call_deferred("change_scene_to_file", "res://game_over.tscn"),
			0.5
		)

func _screen_flash(color: Color) -> void:
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 30
	get_parent().add_child(flash_layer)

	var flash = ColorRect.new()
	flash.color = Color(color.r, color.g, color.b, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)

	var tween = create_tween()
	tween.tween_property(flash, "color", color, 0.25)
	tween.tween_property(flash, "color", Color(color.r, color.g, color.b, color.a * 0.45), 1.2)
	tween.tween_callback(flash_layer.queue_free)

func swing_pickaxe() -> void:
	can_swing = false

	var swing_dir = 1.0 if facing_right else -1.0

	swing_sound.play()
	body_sprite.play(&"swing")
	fuse_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	fuse_sprite.play(&"react")

	# -62 is the x-offset of the player's collision shape from origin
	var hit_pos = global_position + Vector2(-62.0 + PICKAXE_RANGE * swing_dir, 22.5)

	var space = get_world_2d().direct_space_state
	var hit_shape := CircleShape2D.new()
	hit_shape.radius = 22.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hit_shape
	query.transform = Transform2D(0.0, hit_pos)
	query.collision_mask = 2
	query.collide_with_bodies = true
	query.collide_with_areas = true
	var results = space.intersect_shape(query)

	if results.size() > 0:
		strike_sound.play()

	for result in results:
		var body = result.collider
		if body.has_method("take_damage"):
			body.take_damage(PICKAXE_DAMAGE)

	await get_tree().create_timer(0.3).timeout
	can_swing = true
	fuse_sprite.play(&"blank")
	fuse_sprite.modulate = Color(0.6, 0.6, 0.6, 1.0)
	var resume = &"run" if abs(velocity.x) > 10 else &"idle"
	body_sprite.play(resume)

# ── Mourk ability hooks called by shard.gd ────────────────────────────────────
func boost_speed(duration: float) -> void:
	_speed_boost_timer = duration
	# Orange glow
	var tw := create_tween()
	tw.tween_property(body_sprite, "modulate", Color(1.4, 0.65, 0.15, 1.0), 0.08)
	tw.tween_property(body_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), duration - 0.1)

func add_shield_progress(extra: int) -> void:
	_next_shield_at = max(shards_collected + 1, _next_shield_at - extra)

func force_shield() -> void:
	if not fuse_shield:
		_next_shield_at = shards_collected + 999  # prevent double-trigger
		_activate_shield()

func _activate_shield() -> void:
	fuse_shield = true
	_shield_pulse = 0.0
	queue_redraw()
	fuse_sprite.modulate = Color(0.25, 0.92, 1.0, 1.0)
	fuse_sprite.play(&"react")
	_screen_flash(Color(0.18, 0.82, 1.0, 0.22))
	await get_tree().create_timer(0.45).timeout
	if not is_dead and fuse_shield:
		fuse_sprite.play(&"blank")
		fuse_sprite.modulate = Color(0.25, 0.92, 1.0, 1.0)   # stay cyan while shielded

func _break_shield() -> void:
	fuse_shield = false
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

func _lightning_strike() -> void:
	can_break = false
	GameState.lives = 0

	lightning_sound.play()
	fuse_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	fuse_sprite.play(&"react")

	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 30
	get_parent().add_child(flash_layer)

	var flash = ColorRect.new()
	flash.color = Color(0.9, 0.0, 1.0, 0.45)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_layer.add_child(flash)

	var bolt = Sprite2D.new()
	bolt.texture = load("res://echoveil/Animations/axe lightning.png")
	bolt.position = flash_layer.get_viewport().get_visible_rect().size * 0.5
	bolt.scale = Vector2(0.6, 0.6)
	bolt.modulate = Color(1.0, 0.5, 1.0, 1.0)
	flash_layer.add_child(bolt)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "color", Color(0.9, 0.0, 1.0, 0.0), 0.6)
	tween.tween_property(bolt, "modulate", Color(1.0, 0.5, 1.0, 0.0), 0.6)
	tween.chain().tween_callback(flash_layer.queue_free)

	for drone in get_tree().get_nodes_in_group("drone"):
		if drone.has_method("stun"):
			drone.stun(4.0)

	await get_tree().create_timer(1.0).timeout
	fuse_sprite.play(&"blank")
	fuse_sprite.modulate = Color(0.6, 0.6, 0.6, 1.0)
	can_break = true
