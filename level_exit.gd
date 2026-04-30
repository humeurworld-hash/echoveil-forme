extends Area2D

var triggered: bool = false
var pulse: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	pulse += delta * 2.2
	queue_redraw()

func _draw() -> void:
	var alpha := 0.38 + sin(pulse) * 0.22
	draw_rect(Rect2(-32, -100, 64, 200), Color(0.45, 0.08, 0.95, alpha))
	draw_rect(Rect2(-32, -100, 64, 200), Color(0.80, 0.45, 1.0, 0.55), false, 2.5)
	var shimmer_x := sin(pulse * 1.3) * 10.0
	draw_line(Vector2(shimmer_x, -90), Vector2(shimmer_x, 90), Color(1.0, 0.8, 1.0, 0.35), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(-42, -112), "COREPATH", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.91, 0.79, 0.30, 0.85))
	draw_string(ThemeDB.fallback_font, Vector2(-26, -97),  "AHEAD",    HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.68, 0.55, 0.85, 0.70))

func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	set_process(false)   # stop pulse animation
	_show_corepath_found()

func _show_corepath_found() -> void:
	# Overlay canvas
	var canvas := CanvasLayer.new()
	canvas.layer = 50
	get_parent().add_child(canvas)

	var lbl := Label.new()
	lbl.text = "COREPATH FOUND"
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lbl.grow_vertical   = Control.GROW_DIRECTION_BOTH
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 44)
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
		LevelManager.current_level = 0
		next_scene = "res://main_menu.tscn"
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", next_scene),
		0.5
	)
