extends Control

## Floating virtual joystick for top-down 8-directional movement.
##
## • Snaps the base to wherever the thumb first lands (left-half of screen).
## • Knob follows the drag up to TRAVEL px from the base.
## • Pushes analog strength into the four move_* input actions so
##   Input.get_vector() returns smooth diagonal values.
## • Draws itself — no texture dependencies.

const DEAD_ZONE : float = 0.12   ## normalised deflection below which = no input
const TRAVEL    : float = 88.0   ## px — max knob offset from base centre
const BASE_R    : float = 108.0  ## outer guide ring radius (px)
const KNOB_R    : float = 42.0   ## knob visual radius (px)

var _tid    : int     = -1
var _base   : Vector2 = Vector2.ZERO
var _knob   : Vector2 = Vector2.ZERO   # offset vector from base (clamped to TRAVEL)
var _active : bool    = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Ignore mouse so only touch events reach _input()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if not _active:
		return
	var b : Vector2 = _base
	var k : Vector2 = b + _knob
	# Filled base disc
	draw_circle(b, BASE_R,  Color(0.12, 0.50, 0.72, 0.22))
	# Outer guide ring
	draw_arc(b,   BASE_R,  0.0, TAU, 64, Color(0.55, 0.90, 1.00, 0.40), 2.5)
	# Travel ring (shows max reach)
	draw_arc(b,   TRAVEL,  0.0, TAU, 48, Color(1.00, 1.00, 1.00, 0.14), 1.5)
	# Knob shadow
	draw_circle(k, KNOB_R + 4.0, Color(0.0, 0.0, 0.0, 0.28))
	# Knob fill
	draw_circle(k, KNOB_R,       Color(0.28, 0.82, 1.00, 0.72))
	# Knob rim
	draw_arc(k,   KNOB_R,  0.0, TAU, 32, Color(0.60, 1.00, 1.00, 0.95), 3.0)

func _input(event: InputEvent) -> void:
	var vp_w : float = get_viewport_rect().size.x

	if event is InputEventScreenTouch:
		var te : InputEventScreenTouch = event as InputEventScreenTouch
		if te.pressed:
			# Only claim touches on the LEFT 45 % of the screen
			if _tid == -1 and te.position.x < vp_w * 0.45:
				_tid    = te.index
				_base   = te.position
				_knob   = Vector2.ZERO
				_active = true
				queue_redraw()
				get_viewport().set_input_as_handled()
		else:
			if te.index == _tid:
				_tid    = -1
				_active = false
				_knob   = Vector2.ZERO
				_release_all()
				queue_redraw()

	elif event is InputEventScreenDrag:
		var de : InputEventScreenDrag = event as InputEventScreenDrag
		if de.index == _tid:
			var delta : Vector2 = de.position - _base
			if delta.length() > TRAVEL:
				delta = delta.normalized() * TRAVEL
			_knob = delta
			_push_actions(delta / TRAVEL)
			queue_redraw()
			get_viewport().set_input_as_handled()

# ── Input action helpers ──────────────────────────────────────────────────────

func _push_actions(dir: Vector2) -> void:
	_axis(&"move_left",  &"move_right", dir.x)
	_axis(&"move_up",    &"move_down",  dir.y)

func _axis(neg: StringName, pos: StringName, v: float) -> void:
	if v < -DEAD_ZONE:
		Input.action_press(neg,  -v)
		Input.action_release(pos)
	elif v > DEAD_ZONE:
		Input.action_press(pos,   v)
		Input.action_release(neg)
	else:
		Input.action_release(neg)
		Input.action_release(pos)

func _release_all() -> void:
	for a : StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(a)
