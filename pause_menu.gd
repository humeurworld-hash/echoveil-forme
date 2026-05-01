extends CanvasLayer

## Pause overlay — spawned by HUD when the pause button is pressed.
## The CanvasLayer itself runs at PROCESS_MODE_ALWAYS so buttons
## respond while the tree is paused.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	# ── Dark overlay ─────────────────────────────────────────────────────────
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.05, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# ── Centred card ─────────────────────────────────────────────────────────
	var card := ColorRect.new()
	card.color = Color(0.04, 0.04, 0.12, 0.92)
	card.custom_minimum_size = Vector2(380, 320)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical   = Control.GROW_DIRECTION_BOTH
	card.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	add_child(card)

	# ── Vertical layout inside card ───────────────────────────────────────────
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(300, 0)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	add_child(vbox)

	_make_title(vbox, "— PAUSED —")

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	vbox.add_child(spacer)

	_make_btn(vbox, "RESUME",     Color(0.45, 0.90, 0.60, 1.0), _resume)
	_make_btn(vbox, "RESTART",    Color(0.70, 0.60, 1.00, 1.0), _restart)
	_make_btn(vbox, "MAIN MENU",  Color(0.70, 0.35, 0.35, 1.0), _quit_to_menu)

# ── helpers ──────────────────────────────────────────────────────────────────

func _make_title(parent: Control, txt: String) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 46)
	lbl.add_theme_color_override("font_color", Color(0.91, 0.79, 0.30, 1.0))
	parent.add_child(lbl)

func _make_btn(parent: Control, txt: String, clr: Color, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = txt
	btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", 32)
	btn.add_theme_color_override("font_color", clr)
	btn.custom_minimum_size = Vector2(280, 64)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(cb)
	parent.add_child(btn)

# ── actions ──────────────────────────────────────────────────────────────────

func _resume() -> void:
	get_tree().paused = false
	queue_free()

func _restart() -> void:
	get_tree().paused = false
	var lvl := "res://level%d.tscn" % GameState.current_level
	if not ResourceLoader.exists(lvl):
		lvl = "res://level1.tscn"
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", lvl), 0.4)
	queue_free()

func _quit_to_menu() -> void:
	get_tree().paused = false
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://main_menu.tscn"), 0.5)
	queue_free()
