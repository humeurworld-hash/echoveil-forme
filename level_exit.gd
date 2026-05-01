extends Area2D

## Distance (px) at which the corepath begins to open.
const ACTIVATE_DIST := 320.0

var triggered: bool = false
var _activated: bool = false
var _pulse: float = 0.0

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_anim.animation_finished.connect(_on_open_finished)
	_anim.play("idle")

func _process(delta: float) -> void:
	_pulse += delta * 2.2
	queue_redraw()

	if triggered or _activated:
		return

	# Start opening when the player walks close enough.
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	if global_position.distance_to(players[0].global_position) < ACTIVATE_DIST:
		_activated = true
		_anim.play("open")

func _draw() -> void:
	# Floating text label above the portal — pulses with the animation.
	var a := 0.55 + sin(_pulse) * 0.30
	draw_string(ThemeDB.fallback_font, Vector2(-42, -130), "COREPATH",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.91, 0.79, 0.30, a))
	draw_string(ThemeDB.fallback_font, Vector2(-26, -112), "AHEAD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.68, 0.55, 0.85, a * 0.85))

func _on_open_finished() -> void:
	if _anim.animation == &"open":
		_anim.play("glow")

func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return
	triggered = true
	set_process(false)
	# Force the final frame if the player ran straight into it.
	if not _activated:
		_activated = true
		_anim.play("glow")
	_show_corepath_found()

func _show_corepath_found() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 50
	get_parent().add_child(canvas)

	var lbl := Label.new()
	lbl.text = "COREPATH FOUND"
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
		LevelManager.current_level = 0
		next_scene = "res://main_menu.tscn"
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", next_scene),
		0.5
	)
