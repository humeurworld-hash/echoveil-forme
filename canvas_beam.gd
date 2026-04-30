extends Area2D

## Horizontal Canvas scan beam — fires right-to-left at a fixed y height.
## Place this node in the level at the y-position you want the beam to fire at.
## The beam spans the full level width (centered on the node's x position).

@export var warn_duration  : float = 1.8    # seconds the aim-line is visible before firing
@export var fire_duration  : float = 0.45   # seconds the full beam is active
@export var cooldown       : float = 8.0    # seconds between beam cycles
@export var initial_delay  : float = 3.0    # delay before the very first warn
@export var level_span     : float = 2000.0 # full width the beam covers
@export var beam_half_h    : float = 40.0   # half-height of the beam rect (collision + visual)

enum State { IDLE, WARN, FIRE }
var _state : State = State.IDLE
var _timer : float = 0.0
var _pulse : float = 0.0        # drives warning animation

var _warn_snd : AudioStreamPlayer
var _fire_snd : AudioStreamPlayer

@onready var _shape : CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("beam")
	# Keep monitoring so get_overlapping_bodies() works at fire time
	monitoring = true
	_shape.disabled = true
	_timer = initial_delay
	body_entered.connect(_on_body_entered)

	_warn_snd = AudioStreamPlayer.new()
	_warn_snd.stream = load("res://echoveil/music/animations/beam_warn.mp3")
	_warn_snd.volume_db = -6.0
	add_child(_warn_snd)

	_fire_snd = AudioStreamPlayer.new()
	_fire_snd.stream = load("res://echoveil/music/animations/beam_fire.mp3")
	_fire_snd.volume_db = -3.0
	add_child(_fire_snd)

func _process(delta: float) -> void:
	_timer -= delta
	match _state:
		State.IDLE:
			if _timer <= 0.0:
				_begin_warn()
		State.WARN:
			_pulse += delta * 5.0
			queue_redraw()
			if _timer <= 0.0:
				_begin_fire()
		State.FIRE:
			if _timer <= 0.0:
				_end_fire()
			queue_redraw()

func _draw() -> void:
	var hw := level_span * 0.5
	match _state:
		State.WARN:
			var a := 0.22 + sin(_pulse) * 0.22
			# Warning line across full width
			draw_line(Vector2(-hw, 0), Vector2(hw, 0),
				Color(1.0, 0.20, 0.05, a + 0.12), 4.0)
			# Left-pointing chevrons — show beam will travel right→left
			var step := level_span / 10.0
			for i in range(10):
				var cx := hw - step * 0.5 - step * float(i)
				draw_line(Vector2(cx + 14, -8), Vector2(cx, 0),
					Color(1.0, 0.35, 0.10, a * 0.85), 2.0)
				draw_line(Vector2(cx + 14,  8), Vector2(cx, 0),
					Color(1.0, 0.35, 0.10, a * 0.85), 2.0)

		State.FIRE:
			var progress := 1.0 - (_timer / fire_duration)
			# Fade out in the final 25 % of fire duration
			var a := clampf(1.0 - maxf(0.0, (progress - 0.75) * 4.0), 0.0, 1.0)
			# Outer glow
			draw_rect(Rect2(-hw, -(beam_half_h + 14), level_span, (beam_half_h + 14) * 2),
				Color(1.0, 0.08, 0.03, 0.22 * a))
			# Main beam body
			draw_rect(Rect2(-hw, -beam_half_h, level_span, beam_half_h * 2),
				Color(1.0, 0.12, 0.05, 0.80 * a))
			# Bright white-orange core
			draw_rect(Rect2(-hw, -10, level_span, 20),
				Color(1.0, 0.62, 0.45, 0.95 * a))

func _begin_warn() -> void:
	_state = State.WARN
	_timer = warn_duration
	_pulse = 0.0
	_warn_snd.play()
	queue_redraw()

func _begin_fire() -> void:
	_state          = State.FIRE
	_timer          = fire_duration
	_shape.disabled = false
	_fire_snd.play()
	queue_redraw()
	# Hit players already inside the beam zone at the moment of fire
	for body in get_overlapping_bodies():
		_try_hit(body)

func _end_fire() -> void:
	_shape.disabled = true
	_state = State.IDLE
	_timer = cooldown
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	# Catches players who run/jump INTO the beam while it's firing
	if _state == State.FIRE:
		_try_hit(body)

func _try_hit(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("hit_by_drone"):
		body.hit_by_drone()
