extends Control

func _ready() -> void:
	clip_contents = true

	# ── Background ────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Centred layout ─────────────────────────────────────────────────────────
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(700, 0)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	add_child(vbox)

	var total_xp := GameState.xp + (GameState.player_level - 1) * 50

	var lines := [
		["THE RIFT IS SEALED",                              72, Color(0.91, 0.79, 0.30, 1.0)],
		["",                                                22, Color(0, 0, 0, 0)],
		["Forme carried the Prime Mourk out.",              34, Color(0.72, 0.62, 0.90, 1.0)],
		["The Echoveil cannot follow.",                     34, Color(0.72, 0.62, 0.90, 1.0)],
		["",                                                22, Color(0, 0, 0, 0)],
		["The signal is lost — for now.",                   34, Color(0.55, 0.88, 0.72, 1.0)],
		["",                                                16, Color(0, 0, 0, 0)],
		["Level %d  ·  %d XP" % [GameState.player_level, total_xp],
		                                                    28, Color(0.45, 0.92, 0.88, 1.0)],
	]

	var labels : Array[Label] = []
	for row in lines:
		var lbl := Label.new()
		lbl.text          = row[0]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", row[1])
		lbl.add_theme_color_override("font_color",    row[2])
		lbl.modulate.a = 0.0
		vbox.add_child(lbl)
		labels.append(lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 48)
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = "RETURN TO SURFACE  ›"
	btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", 36)
	btn.add_theme_color_override("font_color", Color(0.91, 0.79, 0.30, 1.0))
	btn.custom_minimum_size = Vector2(380, 70)
	btn.modulate.a = 0.0
	btn.pressed.connect(_return)
	vbox.add_child(btn)

	TransitionLayer.fade_in(1.2)

	await get_tree().create_timer(0.8).timeout
	var seq := create_tween()
	seq.tween_property(labels[0], "modulate:a", 1.0, 0.7)
	seq.tween_interval(0.3)
	for i in range(1, labels.size()):
		seq.tween_property(labels[i], "modulate:a", 1.0, 0.4)
		seq.tween_interval(0.15)
	seq.tween_interval(0.4)
	seq.tween_property(btn, "modulate:a", 1.0, 0.55)

func _return() -> void:
	GameState.current_level    = 1
	LevelManager.current_level = 1
	GameState.save()
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://main_menu.tscn"),
		0.7
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey          and event.pressed and not event.echo: _return()
	elif event is InputEventScreenTouch and event.pressed:                   _return()
