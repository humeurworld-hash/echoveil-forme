extends Area2D

var triggered: bool = false
var pulse: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	pulse += delta * 2.2
	queue_redraw()

func _draw() -> void:
	var alpha = 0.38 + sin(pulse) * 0.22
	# Portal glow fill
	draw_rect(Rect2(-32, -100, 64, 200), Color(0.45, 0.08, 0.95, alpha))
	# Portal border
	draw_rect(Rect2(-32, -100, 64, 200), Color(0.80, 0.45, 1.0, 0.55), false, 2.5)
	# Inner shimmer line
	var shimmer_x = sin(pulse * 1.3) * 10.0
	draw_line(Vector2(shimmer_x, -90), Vector2(shimmer_x, 90), Color(1.0, 0.8, 1.0, 0.35), 4.0)
	# "EXIT" label above portal
	draw_string(ThemeDB.fallback_font, Vector2(-26, -112), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.91, 0.79, 0.30, 0.90))

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	if not body.is_in_group("player"):
		return
	triggered = true
	LevelManager.current_level += 1
	GameState.current_level = LevelManager.current_level
	GameState.save()
	var next_scene := "res://level%d.tscn" % LevelManager.current_level
	if not ResourceLoader.exists(next_scene):
		# Level doesn't exist yet — return to main menu
		LevelManager.current_level = 0
		next_scene = "res://main_menu.tscn"
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", next_scene),
		0.5
	)
