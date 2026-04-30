extends CharacterBody2D

const WALK_SPEED    := 85.0
const GRAVITY       := 980.0
const PATROL_RANGE  := 160.0
const FIRE_RANGE    := 420.0
const FIRE_COOLDOWN := 3.5

@export var drop_color: int = 2  # 0=TEAL 1=GREEN 2=ORANGE 3=PURPLE 4=GOLD

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var hp          := 2
var _dir        := 1.0
var _start_x    := 0.0
var _stunned    := false
var _stun_timer := 0.0
var _dead       := false
var _fire_timer := 1.5

func _ready() -> void:
	add_to_group("enemy")
	_start_x = position.x
	_dir = 1.0 if randf() > 0.5 else -1.0
	sprite.play(&"walk")

func _process(delta: float) -> void:
	if _dead or _stunned:
		return
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player and is_instance_valid(player):
			if abs(player.global_position.x - global_position.x) < FIRE_RANGE:
				_fire_bolt(player.global_position)
		_fire_timer = FIRE_COOLDOWN

func _fire_bolt(target_pos: Vector2) -> void:
	var bolt_scene := load("res://laser_bolt.tscn") as PackedScene
	if not bolt_scene:
		return
	var bolt := bolt_scene.instantiate()
	bolt.global_position = global_position + Vector2(0, -44)
	get_parent().add_child(bolt)
	bolt.launch(target_pos)
	sprite.play(&"attack")
	sprite.flip_h = target_pos.x < global_position.x
	await get_tree().create_timer(0.5).timeout
	if not _dead and not _stunned:
		sprite.play(&"walk")

func _physics_process(delta: float) -> void:
	if _dead:
		return
	velocity.y = 0.0 if is_on_floor() else velocity.y + GRAVITY * delta

	if _stunned:
		_stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED * 4)
		if _stun_timer <= 0.0:
			_stunned = false
			sprite.play(&"walk")
	else:
		if abs(position.x - _start_x) >= PATROL_RANGE or is_on_wall():
			_dir *= -1.0
		velocity.x = WALK_SPEED * _dir
		sprite.flip_h = _dir < 0

	move_and_slide()

	for i in get_slide_collision_count():
		var body = get_slide_collision(i).get_collider()
		if body and body.is_in_group("player") and body.has_method("hit_by_drone"):
			sprite.play(&"attack")
			body.hit_by_drone()

func take_damage(_amount: int) -> void:
	if _dead or _stunned:
		return
	hp -= 1
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if hp <= 0:
		_die()
	else:
		_stunned = true
		_stun_timer = 0.85
		sprite.play(&"stun")

func stun(duration: float) -> void:
	_stunned = true
	_stun_timer = max(_stun_timer, duration)
	sprite.play(&"stun")

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
	tw.tween_property(sprite, "modulate", Color(1.4, 0.3, 0.3, 0.0), 0.30)
	tw.tween_callback(queue_free)
