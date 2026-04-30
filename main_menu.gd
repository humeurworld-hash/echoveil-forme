extends Control

func _ready() -> void:
	var vp := get_viewport_rect().size

	# ── Background ────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.06, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Center column ─────────────────────────────────────────────────────
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(340, 0)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "ECHOVEIL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.91, 0.79, 0.30, 1))
	vbox.add_child(title)

	# Subtitle line
	var sub1 := Label.new()
	sub1.text = "; FORME"
	sub1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub1.add_theme_font_size_override("font_size", 32)
	sub1.add_theme_color_override("font_color", Color(0.68, 0.55, 0.90, 1))
	vbox.add_child(sub1)

	# Tagline
	var tag := Label.new()
	tag.text = "do not let them curate you"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color(0.42, 0.32, 0.52, 0.75))
	vbox.add_child(tag)

	_spacer(vbox, 58)

	# ── NEW GAME ──────────────────────────────────────────────────────────
	var new_btn := _make_button("BEGIN SHIFT", Color(0.91, 0.79, 0.30, 1))
	new_btn.pressed.connect(_on_new_game)
	vbox.add_child(new_btn)

	_spacer(vbox, 14)

	# ── CONTINUE ─────────────────────────────────────────────────────────
	var has_save := FileAccess.file_exists("user://echoveil_save.json")
	var con_btn  := _make_button("KEEP MOVING", Color(0.72, 0.62, 0.88, 1))
	con_btn.disabled = not has_save
	con_btn.modulate.a = 1.0 if has_save else 0.36
	con_btn.pressed.connect(_on_continue)
	vbox.add_child(con_btn)

	_spacer(vbox, 14)

	# ── QUIT ─────────────────────────────────────────────────────────────
	var quit_btn := _make_button("QUIT", Color(0.72, 0.26, 0.36, 1))
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)

	# ── Music ─────────────────────────────────────────────────────────────
	var music := AudioStreamPlayer.new()
	music.stream = load("res://echoveil/music/Mist in the Circuit-2.mp3")
	music.volume_db = -12.0
	music.autoplay  = true
	add_child(music)

	# ── Version stamp ──────────────────────────────────────────────────────
	var ver := Label.new()
	ver.text = "v0.1"
	ver.add_theme_font_size_override("font_size", 10)
	ver.add_theme_color_override("font_color", Color(0.3, 0.22, 0.40, 0.5))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -36.0
	ver.offset_top  = -22.0
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)

	TransitionLayer.fade_in(0.7)

# ── helpers ───────────────────────────────────────────────────────────────
func _make_button(label: String, col: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(320, 54)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", col)
	return btn

func _spacer(parent: Control, h: int) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, h)
	parent.add_child(sp)

# ── callbacks ─────────────────────────────────────────────────────────────
func _on_new_game() -> void:
	GameState.reset()
	LevelManager.current_level = 1
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://intro_scroll.tscn"),
		0.45
	)

func _on_continue() -> void:
	GameState.load_data()
	LevelManager.current_level = 1
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://level1.tscn"),
		0.45
	)

func _on_quit() -> void:
	get_tree().quit()
