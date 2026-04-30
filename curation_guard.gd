extends CharacterBody2D

## Ground-patrol Canvas Corp enforcer. Walks back and forth on platforms.
## Takes 2 pickaxe hits to destroy; drops a Mourk shard on death.

const WALK_SPEED   := 85.0
const GRAVITY      := 980.0
const PATROL_RANGE := 160.0

@export var drop_color: int = 2  # 0=TEAL 1=GREEN 2=ORANGE 3=PURPLE 4=GOLD

var hp           := 2
var _dir         := 1.0
var _start_x     := 0.0
var _stunned     := false
var _stun_timer  := 0.0
var _dead        := false
var _pulse       := 0.0
var _hit_flash   := 0.0

func _ready() -> void:
	add_to_group("enemy")
	_start_x = position.x
	_dir = 1.0 if randf() > 0.5 else -1.0

func _physics_process(delta: float) -> void:
	if _dead:
		return
	velocity.y = 0.0 if is_on_floor() else velocity.y + GRAVITY * delta

	if _stunned:
		_stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED * 4)
		if _stun_timer <= 0.0:
			_stunned = false
	else:
		if abs(position.x - _start_x) >= PATROL_RANGE or is_on_wall():
			_dir *= -1.0
		velocity.x = WALK_SPEED * _dir

	move_and_slide()

	# Contact damage — CharacterBody2D slide collisions include the player
	for i in get_slide_collision_count():
		var body = get_slide_collision(i).get_collider()
		if body and body.is_in_group("player") and body.has_method("hit_by_drone"):
			body.hit_by_drone()

func _process(delta: float) -> void:
	if _dead:
		return
	_pulse += delta * 4.0
	if _hit_flash > 0:
		_hit_flash -= delta
	queue_redraw()

func _draw() -> void:
	if _dead:
		return
	var c := Color(0.72, 0.22, 0.38, 1.0)
	if _stunned:
		c = Color(1.0, 0.55, 0.15, 1.0)
	if _hit_flash > 0:
		c = Color(1.0, 1.0, 1.0, 1.0)
	# Body
	draw_rect(Rect2(-16, -70, 32, 50), c)
	# Head
	draw_rect(Rect2(-11, -88, 22, 20), c)
	# Red visor
	draw_rect(Rect2(-9, -85, 18, 7), Color(1.0, 0.12, 0.12, 0.92))
	# Canvas Corp badge
	draw_rect(Rect2(-5, -55, 10, 8), Color(0.08, 0.08, 0.18, 0.88))
	# Walking legs
	var lg := sin(_pulse) * 6.0 if not _stunned else 0.0
	draw_rect(Rect2(-13, -20, 10, 22), c)
	draw_rect(Rect2(3, -20 + lg, 10, 22), c)

func take_damage(_amount: int) -> void:
	if _dead or _stunned:
		return
	hp -= 1
	_hit_flash = 0.15
	if hp <= 0:
		_die()
	else:
		_stunned = true
		_stun_timer = 0.85

func stun(duration: float) -> void:
	_stunned = true
	_stun_timer = max(_stun_timer, duration)

func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	var shard_scene := load("res://shard.tscn") as PackedScene
	if shard_scene:
		var s := shard_scene.instantiate()
		s.set("shard_type", drop_color)
		s.position = global_position + Vector2(0, -30)
		get_parent().add_child(s)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.4, 0.3, 0.3, 0.0), 0.30)
	tw.tween_callback(queue_free)
