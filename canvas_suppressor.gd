extends Area2D

const DIVE_SPEED   := 600.0
const RISE_SPEED   := 220.0
const DETECT_RANGE := 240.0
const DIVE_DIST    := 420.0

enum Phase { HOVER, WARN, DIVE, RISE }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _phase    := Phase.HOVER
var _target_x := 0.0
var _home_y   := 0.0
var _pulse    := 0.0
var _warn_t   := 0.0

func _ready() -> void:
	add_to_group("drone")
	_home_y = position.y
	monitoring = true
	body_entered.connect(_on_body_entered)
	sprite.play(&"hover")

func _process(delta: float) -> void:
	_pulse += delta * 3.5

	match _phase:
		Phase.HOVER:
			position.y = _home_y + sin(_pulse) * 10.0
			if sprite.animation != &"hover":
				sprite.play(&"hover")
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if player and is_instance_valid(player):
				if abs(player.global_position.x - global_position.x) < DETECT_RANGE:
					_target_x = player.global_position.x
					_phase = Phase.WARN
					_warn_t = 0.55
					sprite.play(&"warn")
					sprite.flip_h = _target_x < global_position.x

		Phase.WARN:
			_warn_t -= delta
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
				sprite.play(&"hover")

func _on_body_entered(body: Node2D) -> void:
	if _phase != Phase.DIVE:
		return
	if body.is_in_group("player") and body.has_method("hit_by_drone"):
		body.hit_by_drone()

func take_damage(_amount: int) -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1.8, 1.8, 1.8, 0.0), 0.22)
	tw.tween_callback(queue_free)

func stun(_duration: float) -> void:
	take_damage(1)
