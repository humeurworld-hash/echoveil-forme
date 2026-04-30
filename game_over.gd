extends Control

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.0, 0.04, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(380, 0)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	add_child(vbox)

	# CURATION
	var line1 := Label.new()
	line1.text = "CURATION"
	line1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line1.add_theme_font_size_override("font_size", 96)
	line1.add_theme_color_override("font_color", Color(0.85, 0.12, 0.22, 1))
	vbox.add_child(line1)

	# COMPLETE
	var line2 := Label.new()
	line2.text = "COMPLETE"
	line2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line2.add_theme_font_size_override("font_size", 96)
	line2.add_theme_color_override("font_color", Color(0.85, 0.12, 0.22, 1))
	vbox.add_child(line2)

	# Tagline
	var sub := Label.new()
	sub.text = "they curated you"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.50, 0.18, 0.28, 0.80))
	vbox.add_child(sub)

	# Shard count
	var score_lbl := Label.new()
	score_lbl.text = "mourks collected: %d" % GameState.shards_collected
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_size_override("font_size", 28)
	score_lbl.add_theme_color_override("font_color", Color(0.60, 0.50, 0.72, 0.80))
	vbox.add_child(score_lbl)

	_spacer(vbox, 52)

	# RUN IT BACK
	var run_btn := _make_button("RUN IT BACK", Color(0.91, 0.79, 0.30, 1))
	run_btn.pressed.connect(_on_run_it_back)
	vbox.add_child(run_btn)

	_spacer(vbox, 14)

	# MAIN MENU
	var menu_btn := _make_button("MAIN MENU", Color(0.55, 0.44, 0.68, 1))
	menu_btn.pressed.connect(_on_main_menu)
	vbox.add_child(menu_btn)

	TransitionLayer.fade_in(0.7)

func _make_button(label: String, col: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(320, 54)
	btn.add_theme_font_size_override("font_size", 44)
	btn.add_theme_color_override("font_color", col)
	return btn

func _spacer(parent: Control, h: int) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, h)
	parent.add_child(sp)

func _on_run_it_back() -> void:
	GameState.reset()
	LevelManager.current_level = 1
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://level1.tscn"),
		0.45
	)

func _on_main_menu() -> void:
	GameState.reset()
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://main_menu.tscn"),
		0.45
	)
