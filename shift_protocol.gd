extends Control

# Lines: [text, font_size, color_r, color_g, color_b]
const LINES := [
	["SHIFT PROTOCOL",                           30, 0.91, 0.79, 0.30],
	["",                                         10, 0.0,  0.0,  0.0 ],
	["Move through the mine.",                   18, 0.78, 0.68, 0.90],
	["Break unstable rock.",                     18, 0.78, 0.68, 0.90],
	["Collect Mourk shards.",                    18, 0.78, 0.68, 0.90],
	["Avoid Canvas drones.",                     18, 0.78, 0.68, 0.90],
	["Follow Fuse's signal.",                    18, 0.78, 0.68, 0.90],
	["",                                         10, 0.0,  0.0,  0.0 ],
	["Find the Corepath before lockdown completes.", 18, 0.91, 0.79, 0.30],
]

var _done := false

func _ready() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered column
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(520, 0)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	add_child(vbox)

	var labels: Array[Label] = []
	for row in LINES:
		var lbl := Label.new()
		lbl.text = row[0]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", row[1])
		lbl.add_theme_color_override("font_color", Color(row[2], row[3], row[4], 1.0))
		lbl.modulate.a = 0.0
		vbox.add_child(lbl)
		labels.append(lbl)

	# Spacer
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(sp)

	# BEGIN button — hidden until lines finish revealing
	var begin_btn := Button.new()
	begin_btn.text = "ENTER THE MINE  ›"
	begin_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	begin_btn.add_theme_font_size_override("font_size", 20)
	begin_btn.add_theme_color_override("font_color", Color(0.91, 0.79, 0.30, 1.0))
	begin_btn.custom_minimum_size = Vector2(300, 62)
	begin_btn.modulate.a = 0.0
	begin_btn.pressed.connect(_begin)
	vbox.add_child(begin_btn)

	TransitionLayer.fade_in(0.5)

	# Stagger lines in, then reveal button
	await get_tree().create_timer(0.6).timeout
	var seq := create_tween()
	seq.tween_property(labels[0], "modulate:a", 1.0, 0.55)
	seq.tween_interval(0.25)
	for i in range(1, labels.size()):
		seq.tween_property(labels[i], "modulate:a", 1.0, 0.35)
		seq.tween_interval(0.12)
	seq.tween_property(begin_btn, "modulate:a", 1.0, 0.6)

func _begin() -> void:
	if _done:
		return
	_done = true
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://level1.tscn"),
		0.6
	)
