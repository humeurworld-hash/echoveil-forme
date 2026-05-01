extends Area2D

# "double_jump" or "roll"
@export var ability: String = "double_jump"

var _triggered := false
var _pulse     := 0.0
var _orbit     := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _triggered:
		return
	_pulse += delta * 2.6
	_orbit += delta * 1.5
	queue_redraw()

func _draw() -> void:
	if _triggered:
		return
	var a   := 0.65 + sin(_pulse) * 0.35
	var r   := 22.0 + sin(_pulse * 1.4) * 3.5
	var bob := sin(_pulse * 0.75) * 6.0
	var c   := Vector2(0.0, bob)

	# Outer pulse glow
	draw_circle(c, r + 18, Color(0.55, 0.25, 1.0, a * 0.15))
	draw_circle(c, r + 9,  Color(0.70, 0.40, 1.0, a * 0.28))
	# Core orb
	draw_circle(c, r,       Color(0.82, 0.60, 1.0, a * 0.82))
	draw_circle(c, r * 0.5, Color(0.96, 0.90, 1.0, a))
	# Orbit rings
	draw_arc(c, r + 6, _orbit,          _orbit + TAU * 0.6,  28, Color(1.0, 0.85, 1.0, a * 0.75), 2.5)
	draw_arc(c, r + 6, _orbit + PI,     _orbit + PI + TAU * 0.28, 14, Color(0.6, 0.4, 1.0, a * 0.5), 1.5)

func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	_unlock()

func _unlock() -> void:
	match ability:
		"double_jump": GameState.has_double_jump = true
		"roll":        GameState.has_roll        = true
	GameState.save()

	var vp_size := get_viewport().get_visible_rect().size
	var cx      := vp_size.x * 0.1   # left margin for labels (they span 80% width)
	var cy      := vp_size.y * 0.5

	var canvas := CanvasLayer.new()
	canvas.layer = 60
	get_parent().add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.0, 0.06, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	const NAMES := {"double_jump": "DOUBLE JUMP", "roll": "DODGE ROLL"}
	const HINTS := {
		"double_jump": "Press JUMP again while airborne",
		"roll":        "Press  C  or tap ROLL to dodge",
	}

	var title    := _make_lbl(canvas, "ABILITY  ABSORBED",
		vp_size.x * 0.8, cx, cy - 80.0, 68, Color(0.92, 0.75, 1.0, 0.0))
	var name_lbl := _make_lbl(canvas,
		"◆   %s   ◆" % NAMES.get(ability, ability.to_upper()),
		vp_size.x * 0.8, cx, cy - 5.0,  50, Color(0.55, 0.92, 1.0, 0.0))
	var hint_lbl := _make_lbl(canvas, HINTS.get(ability, ""),
		vp_size.x * 0.8, cx, cy + 68.0, 28, Color(0.75, 0.75, 0.88, 0.0))

	var tw := canvas.create_tween()
	tw.set_parallel(true)
	tw.tween_property(bg,       "color",      Color(0.01, 0.0, 0.06, 0.86), 0.40)
	tw.tween_property(title,    "modulate:a", 1.0, 0.35).set_delay(0.10)
	tw.tween_property(name_lbl, "modulate:a", 1.0, 0.35).set_delay(0.25)
	tw.tween_property(hint_lbl, "modulate:a", 1.0, 0.35).set_delay(0.42)
	tw.chain().tween_interval(2.2)
	tw.chain().set_parallel(true)
	tw.tween_property(bg,       "color",      Color(0, 0, 0, 0), 0.55)
	tw.tween_property(title,    "modulate:a", 0.0, 0.40)
	tw.tween_property(name_lbl, "modulate:a", 0.0, 0.40)
	tw.tween_property(hint_lbl, "modulate:a", 0.0, 0.40)
	tw.chain().tween_callback(func(): canvas.queue_free(); queue_free())

func _make_lbl(parent: Node, txt: String, w: float,
			   x: float, y: float, sz: int, col: Color) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", sz)
	lbl.add_theme_color_override("font_color", col)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size  = Vector2(w, 60)
	lbl.position             = Vector2(x, y)
	parent.add_child(lbl)
	return lbl
