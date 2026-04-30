extends Control

func _ready() -> void:
	var vp := get_viewport_rect().size

	# ── Background art ────────────────────────────────────────────────────────
	var bg_tex := TextureRect.new()
	if ResourceLoader.exists("res://echoveil/backgrounds/menu_bg.png"):
		bg_tex.texture = load("res://echoveil/backgrounds/menu_bg.png")
	bg_tex.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_tex)

	# ── Dark scrim — bottom-heavy gradient via two rects ──────────────────────
	var scrim_top := ColorRect.new()
	scrim_top.color = Color(0.0, 0.0, 0.04, 0.38)
	scrim_top.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim_top)

	var scrim_bot := ColorRect.new()
	scrim_bot.color = Color(0.0, 0.0, 0.04, 0.72)
	scrim_bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	scrim_bot.offset_top = -vp.y * 0.52
	scrim_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim_bot)

	# ── "; FORME" sub-title (image already shows ECHOVEIL) ───────────────────
	var sub := Label.new()
	sub.text = "; FORME"
	sub.add_theme_font_size_override("font_size", 70)
	sub.add_theme_color_override("font_color", Color(0.68, 0.52, 0.95, 0.95))
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top  = vp.y * 0.155
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	# ── Tagline ───────────────────────────────────────────────────────────────
	var tag := Label.new()
	tag.text = "do not let them curate you"
	tag.add_theme_font_size_override("font_size", 20)
	tag.add_theme_color_override("font_color", Color(0.44, 0.34, 0.54, 0.72))
	tag.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tag.offset_top = vp.y * 0.215
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)

	# ── Button panel (subtle dark box behind buttons) ─────────────────────────
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.01, 0.06, 0.60)
	panel.custom_minimum_size = Vector2(340, 220)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	panel.offset_left  = -170.0
	panel.offset_right =  170.0
	panel.offset_top   =  vp.y * 0.08
	panel.offset_bottom = vp.y * 0.08 + 220.0
	add_child(panel)

	# ── Center button column ──────────────────────────────────────────────────
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(300, 0)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	vbox.offset_top   = vp.y * 0.08 + 18.0
	vbox.offset_bottom = vp.y * 0.08 + 220.0
	vbox.offset_left  = -150.0
	vbox.offset_right =  150.0
	add_child(vbox)

	# BEGIN SHIFT
	var new_btn := _make_button("BEGIN SHIFT", Color(0.91, 0.79, 0.30, 1))
	new_btn.pressed.connect(_on_new_game)
	vbox.add_child(new_btn)

	_spacer(vbox, 10)

	# KEEP MOVING
	var has_save := FileAccess.file_exists("user://echoveil_save.json")
	var con_btn  := _make_button("KEEP MOVING", Color(0.72, 0.62, 0.88, 1))
	con_btn.disabled  = not has_save
	con_btn.modulate.a = 1.0 if has_save else 0.36
	con_btn.pressed.connect(_on_continue)
	vbox.add_child(con_btn)

	_spacer(vbox, 10)

	# QUIT
	var quit_btn := _make_button("QUIT", Color(0.72, 0.26, 0.36, 1))
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)

	# ── Music ─────────────────────────────────────────────────────────────────
	var music := AudioStreamPlayer.new()
	music.stream = load("res://echoveil/music/Mist in the Circuit-2.mp3")
	music.volume_db = -12.0
	music.autoplay  = true
	add_child(music)

	# ── Version stamp ─────────────────────────────────────────────────────────
	var ver := Label.new()
	ver.text = "v0.1"
	ver.add_theme_font_size_override("font_size", 18)
	ver.add_theme_color_override("font_color", Color(0.3, 0.22, 0.40, 0.5))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -36.0
	ver.offset_top  = -22.0
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)

	TransitionLayer.fade_in(0.9)

# ── helpers ───────────────────────────────────────────────────────────────────
func _make_button(label: String, col: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(300, 50)
	btn.add_theme_font_size_override("font_size", 41)
	btn.add_theme_color_override("font_color", col)
	return btn

func _spacer(parent: Control, h: int) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, h)
	parent.add_child(sp)

# ── callbacks ─────────────────────────────────────────────────────────────────
func _on_new_game() -> void:
	GameState.reset()
	LevelManager.current_level = 1
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://intro_scroll.tscn"),
		0.45
	)

func _on_continue() -> void:
	GameState.load_data()
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred(
			"change_scene_to_file",
			"res://level%d.tscn" % LevelManager.current_level
		),
		0.45
	)

func _on_quit() -> void:
	get_tree().quit()
