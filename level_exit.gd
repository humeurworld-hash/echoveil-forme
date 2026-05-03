extends Area2D

## Top-down chamber door — arched portal.
## "NEXT CHAMBER" label pulses when player is near.
## "CHAMBER CLEARED" banner on entry, then fades to next scene.

const ACTIVATE_DIST := 280.0

var triggered  : bool  = false
var _activated : bool  = false
var _pulse     : float = 0.0
var _open_prog : float = 0.0  # 0 = sealed  →  1 = open
var _state     : int   = 0    # 0=idle  1=opening  2=open

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_pulse += delta * 2.0
	queue_redraw()

	if triggered or _activated:
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	if global_position.distance_to(players[0].global_position) < ACTIVATE_DIST:
		_activated = true
		_state = 1
		var tw := create_tween()
		tw.tween_property(self, "_open_prog", 1.0, 1.2) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): _state = 2)

func _draw() -> void:
	var p       := _open_prog
	var sp      := sin(_pulse)
	var breathe := 1.0 + sp * 0.035 * (0.3 + p * 0.7)

	# Door geometry
	var dw := (30.0 + p * 24.0) * breathe   # half-width
	var dh := (50.0 + p * 32.0) * breathe   # rect half-height (below arch)
	var ar := dw                              # arch radius = half-width

	# ── Outer glow aura ──────────────────────────────────────────────────────
	if p > 0.1:
		var ga   := (p - 0.1) * 0.25 + sp * 0.05
		var gcol := Color(0.0, 0.65, 0.85, clampf(ga, 0.0, 0.30))
		draw_rect(Rect2(-dw * 1.5, -(dh + ar * 1.4), dw * 3.0, (dh + ar) * 2.8), gcol)

	# ── Door fill ─────────────────────────────────────────────────────────────
	var fill_a   := clampf(0.08 + p * 0.55 + sp * 0.08, 0.0, 0.82)
	var fill_col := Color(0.04, 0.68, 0.82, fill_a)
	draw_rect(Rect2(-dw, -dh, dw * 2.0, dh + ar), fill_col)
	draw_arc(Vector2(0, -dh), ar, PI, TAU, 24, fill_col, ar * 2.1)

	# ── Inner bright core (when mostly open) ──────────────────────────────────
	if p > 0.6:
		var cp := (p - 0.6) / 0.4
		draw_rect(Rect2(-dw * 0.62, -dh * 0.72, dw * 1.24, dh * 0.9),
			Color(0.60, 1.0, 1.0, cp * 0.45))

	# ── Rim outline ───────────────────────────────────────────────────────────
	var rim_a   := clampf(0.30 + p * 0.65 + sp * 0.12, 0.0, 1.0)
	var rim_col := Color(0.45, 1.00, 1.00, rim_a)
	draw_line(Vector2(-dw, ar), Vector2(-dw, -dh), rim_col, 2.5)
	draw_line(Vector2(dw, -dh), Vector2(dw, ar),   rim_col, 2.5)
	draw_line(Vector2(-dw, ar), Vector2(dw, ar),    rim_col, 2.5)
	draw_arc(Vector2(0, -dh), ar, PI, TAU, 24, rim_col, 2.5)

	# ── Vertical rift line ────────────────────────────────────────────────────
	var rift_a := clampf(0.20 + p * 0.70, 0.0, 1.0)
	draw_line(Vector2(0, -dh - ar * 0.88), Vector2(0, ar),
		Color(0.85, 1.0, 1.0, rift_a), maxf(p * 5.0, 0.5))

	# ── Energy sparks (fully open) ────────────────────────────────────────────
	if p > 0.75:
		var sb := (p - 0.75) / 0.25
		for i in 5:
			var angle := (i / 5.0) * TAU + _pulse * 0.35
			var r0    := dw * 0.55
			var r1    := dw * (0.88 + sin(_pulse * 1.8 + i * 1.2) * 0.18)
			var sa    := clampf(sb * 0.55 + sp * 0.15, 0.0, 0.75)
			draw_line(
				Vector2(cos(angle) * r0, sin(angle) * r0 - dh * 0.2),
				Vector2(cos(angle) * r1, sin(angle) * r1 - dh * 0.2),
				Color(0.45, 1.0, 1.0, sa), 1.8)

	# ── "NEXT CHAMBER" label ─────────────────────────────────────────────────
	var text_a := 0.45 + sp * 0.35
	var lbl_y  := -dh - ar - 28.0
	draw_string(ThemeDB.fallback_font, Vector2(-42, lbl_y),
		"NEXT",    HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
		Color(0.91, 0.79, 0.30, text_a))
	draw_string(ThemeDB.fallback_font, Vector2(-48, lbl_y + 18.0),
		"CHAMBER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Color(0.68, 0.55, 0.85, text_a * 0.85))

func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	set_process(false)
	if not _activated:
		_activated = true
		_open_prog = 1.0
		_state     = 2
	_show_chamber_cleared()

func _show_chamber_cleared() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 50
	get_parent().add_child(canvas)

	var lbl := Label.new()
	lbl.text = "CHAMBER CLEARED"
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lbl.grow_vertical   = Control.GROW_DIRECTION_BOTH
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 81)
	lbl.add_theme_color_override("font_color", Color(0.91, 0.79, 0.30, 1.0))
	lbl.modulate.a = 0.0
	canvas.add_child(lbl)

	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.35)
	tween.tween_interval(0.9)
	tween.tween_callback(_do_transition)

func _do_transition() -> void:
	LevelManager.current_level += 1
	GameState.current_level = LevelManager.current_level
	GameState.save()
	var next_scene := "res://level%d.tscn" % LevelManager.current_level
	if not ResourceLoader.exists(next_scene):
		next_scene = "res://win_screen.tscn"
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", next_scene),
		0.5
	)
