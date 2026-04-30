extends Area2D

## Canvas Corp Suppressor — hovers near the ceiling and dives at the player
## when they pass within range. Only damages on the downward dive.

const DIVE_SPEED   := 600.0
const RISE_SPEED   := 220.0
const DETECT_RANGE := 240.0   # horizontal pixel range to trigger dive
const DIVE_DIST    := 420.0   # how far down it dives from home position

enum Phase { HOVER, WARN, DIVE, RISE }
var _phase     := Phase.HOVER
var _target_x  := 0.0
var _home_y    := 0.0
var _pulse     := 0.0
var _warn_t    := 0.0

func _ready() -> void:
	add_to_group("drone")
	_home_y = position.y
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_pulse += delta * 3.5

	match _phase:
		Phase.HOVER:
			position.y = _home_y + sin(_pulse) * 10.0
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if player and is_instance_valid(player):
				if abs(player.global_position.x - global_position.x) < DETECT_RANGE:
					_target_x = player.global_position.x
					_phase = Phase.WARN
					_warn_t = 0.55

		Phase.WARN:
			_warn_t -= delta
			# Lock x to target during warn
			position.x = lerpf(position.x, _target_x, delta * 5.0)
			position.y = _home_y + sin(_pulse * 6.0) * 5.0
			if _warn_t <= 0.0:
				_phase = Phase.DIVE

		Phase.DIVE:
			position.y += DIVE_SPEED * delta
			if position.y >= _home_y + DIVE_DIST:
				_phase = Phase.RISE

		Phase.RISE:
			position.y -= RISE_SPEED * delta
			if position.y <= _home_y:
				position.y = _home_y
				_phase = Phase.HOVER

	queue_redraw()

func _draw() -> void:
	var base_c := Color(0.85, 0.08, 0.12, 1.0)
	match _phase:
		Phase.WARN:
			var t := clampf(1.0 - _warn_t / 0.55, 0.0, 1.0)
			base_c = base_c.lerp(Color(1.0, 0.88, 0.08, 1.0), t)
		Phase.DIVE:
			base_c = Color(1.0, 0.28, 0.05, 1.0)
		Phase.RISE:
			base_c = Color(0.65, 0.08, 0.10, 0.8)

	# Body — angular triangle pointing downward
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 30), Vector2(-20, -18), Vector2(20, -18)
	]), base_c)
	# Wings
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, -8), Vector2(-40, -20), Vector2(-20, -18)
	]), base_c)
	draw_colored_polygon(PackedVector2Array([
		Vector2(20, -8), Vector2(40, -20), Vector2(20, -18)
	]), base_c)
	# Core glow
	draw_circle(Vector2(0, 2), 7, Color(1.0, 0.65, 0.12, 0.9))
	# Exhaust trail when diving
	if _phase == Phase.DIVE:
		var a := 0.55 + sin(_pulse * 9.0) * 0.28
		draw_circle(Vector2(0, 40), 8, Color(1.0, 0.42, 0.08, a))
		draw_circle(Vector2(0, 56), 5, Color(1.0, 0.18, 0.04, a * 0.5))

func _on_body_entered(body: Node2D) -> void:
	if _phase != Phase.DIVE:
		return
	if body.is_in_group("player") and body.has_method("hit_by_drone"):
		body.hit_by_drone()

func take_damage(_amount: int) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.8, 1.8, 1.8, 0.0), 0.22)
	tw.tween_callback(queue_free)

func stun(duration: float) -> void:
	take_damage(1)
