extends CharacterBody2D

## Top-down Sentinel — patrols in 2D, fires laser at player when in range.
## No gravity; moves freely in any direction.

const WALK_SPEED   := 80.0
const PATROL_RANGE := 200.0
const FIRE_RANGE   := 320.0
const MIN_FIRE_DIST:= 100.0
const FIRE_COOLDOWN:= 5.5
const WARN_TIME    := 0.9

@export var drop_color: int = 2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var hp           := 2
var _patrol_dir  : Vector2 = Vector2.RIGHT
var _start_pos   : Vector2
var _patrol_t    : float = 0.0
var _fire_timer  : float = 5.0
var _warning     : bool  = false
var _stunned     : bool  = false
var _stun_timer  : float = 0.0
var _dead        : bool  = false

func _ready() -> void:
	add_to_group("enemy")
	_start_pos  = global_position
	_patrol_dir = Vector2(1.0 if randf() > 0.5 else -1.0, 0.0)
	_patrol_t   = randf_range(1.8, 3.8)
	sprite.play(&"walk")

func _process(delta: float) -> void:
	if _dead or _stunned: return
	_fire_timer -= delta

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		if not _warning and _fire_timer <= WARN_TIME and dist >= MIN_FIRE_DIST and dist <= FIRE_RANGE:
			_warning = true
			_start_warn(player.global_position)
		if _fire_timer <= 0.0:
			_fire_timer = FIRE_COOLDOWN
			_warning    = false
			if dist >= MIN_FIRE_DIST and dist <= FIRE_RANGE:
				_fire_bolt(player.global_position)

func _physics_process(delta: float) -> void:
	if _dead: return

	if _stunned:
		_stun_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, WALK_SPEED * 4 * delta)
		if _stun_timer <= 0.0:
			_stunned = false
			_warning = false
			sprite.play(&"walk")
		move_and_slide()
		return

	# ── Patrol ────────────────────────────────────────────────────────────────
	_patrol_t -= delta
	if _patrol_t <= 0 or global_position.distance_to(_start_pos) > PATROL_RANGE:
		_patrol_t   = randf_range(1.8, 3.8)
		# Vary direction — sometimes reverse, sometimes pick a new random angle
		if randf() > 0.4:
			_patrol_dir = -_patrol_dir
		else:
			var a : float = randf() * TAU
			_patrol_dir = Vector2(cos(a), sin(a)).normalized()

	velocity       = _patrol_dir * WALK_SPEED
	sprite.flip_h  = velocity.x > 0
	move_and_slide()

	# Contact damage
	for i in get_slide_collision_count():
		var body = get_slide_collision(i).get_collider()
		if body and body.is_in_group("player") and body.has_method("hit_by_drone"):
			body.hit_by_drone()

func _start_warn(target_pos: Vector2) -> void:
	sprite.flip_h = target_pos.x > global_position.x
	if ResourceLoader.exists("res://echoveil/music/animations/beam_warn.mp3"):
		var snd := AudioStreamPlayer.new()
		snd.stream    = load("res://echoveil/music/animations/beam_warn.mp3")
		snd.volume_db = -4.0
		get_parent().add_child(snd)
		snd.play()
		snd.finished.connect(snd.queue_free)
	var tw := create_tween().set_loops(4)
	tw.tween_property(sprite, "modulate", Color(2.5, 0.2, 0.2, 1.0), 0.10)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func _fire_bolt(target_pos: Vector2) -> void:
	var bolt_scene := load("res://laser_bolt.tscn") as PackedScene
	if not bolt_scene: return
	var bolt := bolt_scene.instantiate()
	var dir  := (target_pos - global_position).normalized()
	bolt.global_position = global_position + dir * 55.0
	get_parent().add_child(bolt)
	bolt.launch(target_pos)
	sprite.play(&"attack")
	sprite.flip_h = target_pos.x > global_position.x
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(self) or _dead: return
	if not _stunned: sprite.play(&"walk")

func take_damage(_amount: int) -> void:
	if _dead or _stunned: return
	hp -= 1
	_warning = false
	sprite.modulate = Color.WHITE
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if hp <= 0:
		_die()
	else:
		_stunned    = true
		_stun_timer = 0.85
		sprite.play(&"stun")

func stun(duration: float) -> void:
	_warning    = false
	sprite.modulate = Color.WHITE
	_stunned    = true
	_stun_timer = max(_stun_timer, duration)
	sprite.play(&"stun")

func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	GameState.add_xp(15)
	var sc := load("res://shard.tscn") as PackedScene
	if sc:
		var s := sc.instantiate()
		s.set("shard_type", drop_color)
		s.global_position = global_position + Vector2(0, -30)
		get_parent().add_child(s)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1.4, 0.3, 0.3, 0.0), 0.30)
	tw.tween_callback(queue_free)
