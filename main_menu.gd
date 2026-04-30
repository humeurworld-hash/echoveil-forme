extends Control

func _ready() -> void:
	# Dark cave background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.01, 0.07, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered VBox
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(320, 0)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "ECHOVEIL\n; FORME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.91, 0.79, 0.30, 1))
	vbox.add_child(title)

	# Subtitle
	var sub = Label.new()
	sub.text = "enter the veil"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.55, 0.40, 0.70, 1))
	vbox.add_child(sub)

	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(0, 52)
	vbox.add_child(sp1)

	# Play button
	var play_btn = Button.new()
	play_btn.text = "PLAY"
	play_btn.custom_minimum_size = Vector2(300, 56)
	play_btn.add_theme_font_size_override("font_size", 26)
	play_btn.add_theme_color_override("font_color", Color(0.91, 0.79, 0.30, 1))
	play_btn.pressed.connect(_on_play_pressed)
	vbox.add_child(play_btn)

	var sp2 = Control.new()
	sp2.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(sp2)

	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "QUIT"
	quit_btn.custom_minimum_size = Vector2(300, 56)
	quit_btn.add_theme_font_size_override("font_size", 26)
	quit_btn.add_theme_color_override("font_color", Color(0.75, 0.28, 0.38, 1))
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

	# Music
	var music = AudioStreamPlayer.new()
	music.stream = load("res://echoveil/music/Mist in the Circuit-2.mp3")
	music.volume_db = -12.0
	music.autoplay = true
	add_child(music)

	GameState.reset()
	TransitionLayer.fade_in(0.6)

func _on_play_pressed() -> void:
	LevelManager.current_level = 1
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://level1.tscn"),
		0.4
	)

func _on_quit_pressed() -> void:
	get_tree().quit()
