extends Area2D

@export var drops_shard: bool = false

var patrol_speed: float = 80.0
var patrol_range: float = 180.0
var start_x: float = 0.0
var start_y: float = 0.0
var direction: float = 1.0
var hover_time: float = 0.0
var damage_cooldown: float = 0.0
var stunned: bool = false
var stun_timer: float = 0.0
var stun_tween: Tween = null

var chasing: bool = false
var chase_speed: float = 200.0

# Stomp / glitch state
var glitching: bool = false
var glitch_timer: float = 0.0
var glitch_tick: float = 0.0
var stomp_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("drone")
	start_x = position.x
	start_y = position.y
	hover_time = randf() * TAU

func _process(delta: float) -> void:
	if damage_cooldown > 0:
		damage_cooldown -= delta
	if stomp_cooldown > 0:
		stomp_cooldown -= delta

	if glitching:
		glitch_timer -= delta
		glitch_tick -= delta
		if glitch_tick <= 0:
			glitch_tick = 0.055
			position = Vector2(
				start_x + randf_range(-9, 9),
				start_y + sin(hover_time) * 12.0 + randf_range(-7, 7)
			)
			modulate = Color(randf_range(0.1, 1.0), randf_range(0.1, 1.0), randf_range(0.1, 1.0), 0.8)
		if glitch_timer <= 0:
			glitching = false
			modulate = Color(1, 1, 1, 1)
			position.y = start_y + sin(hover_time) * 12.0
		return

	if stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			_end_stun()
		return

	hover_time += delta * 2.5

	if chasing:
		var player = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var dx = player.global_position.x - global_position.x
			position.x += sign(dx) * chase_speed * delta
			$Sprite2D.flip_h = dx < 0
		position.y = start_y + sin(hover_time) * 12.0
	else:
		position.x += patrol_speed * direction * delta
		if abs(position.x - start_x) >= patrol_range:
			direction *= -1
			$Sprite2D.flip_h = direction < 0
		position.y = start_y + sin(hover_time) * 12.0

	if damage_cooldown <= 0:
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				var stomping = body.velocity.y > 80 and body.global_position.y < global_position.y
				if stomping and stomp_cooldown <= 0:
					_on_stomp(body)
					stomp_cooldown = 1.2
				elif not stomping:
					if body.has_method("hit_by_drone"):
						body.hit_by_drone()
					damage_cooldown = 0.2
				break

func _on_stomp(player) -> void:
	player.velocity.y = -420.0
	glitching = true
	glitch_timer = 0.8
	glitch_tick = 0.0
	if drops_shard:
		_drop_shard()

func _drop_shard() -> void:
	var shard_scene = load("res://shard.tscn")
	if shard_scene:
		var shard = shard_scene.instantiate()
		shard.global_position = global_position + Vector2(0, 20)
		get_parent().add_child(shard)

func activate_chase() -> void:
	chasing = true

func stun(duration: float) -> void:
	if stun_tween:
		stun_tween.kill()
	stunned = true
	stun_timer = duration
	var loops = max(1, int(duration / 0.3))
	stun_tween = create_tween().set_loops(loops)
	stun_tween.tween_property(self, "modulate", Color(0.4, 0.6, 1.0, 0.6), 0.15)
	stun_tween.tween_property(self, "modulate", Color(0.6, 0.8, 1.0, 0.4), 0.15)

func _end_stun() -> void:
	stunned = false
	stun_timer = 0.0
	if stun_tween:
		stun_tween.kill()
		stun_tween = null
	modulate = Color(1, 1, 1, 1)

func take_damage(_amount: int) -> void:
	if not stunned:
		stun(1.5)
