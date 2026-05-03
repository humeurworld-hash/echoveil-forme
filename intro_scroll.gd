extends Control

# ── Lore text ─────────────────────────────────────────────────────────────────
const LORE_TEXT := \
"In EchoVeil, emotion is not invisible.\n\n" + \
"It becomes Mourk —\n" + \
"crystal energy formed from feeling.\n\n" + \
"The Canvas calls it a resource.\n\n" + \
"Everyone else just calls it life.\n\n\n" + \
"Forme was not a chosen hero.\n\n" + \
"He was a miner.\n" + \
"Another worker sent below The Verge\n" + \
"to extract what the world had already felt.\n\n\n" + \
"Most Mourks are small.\n\n" + \
"Fragments of grief.\n" + \
"Fear.\n" + \
"Regret.\n" + \
"Overwhelm.\n\n" + \
"The Canvas harvests them all.\n\n\n" + \
"But beneath The Verge,\n" + \
"something older was waiting.\n\n" + \
"Not a shard.\n\n" + \
"Not a resource.\n\n" + \
"A Prime Mourk.\n\n\n" + \
"The Prime Mourk did not give Forme power.\n\n" + \
"It recognized what he had been carrying.\n\n" + \
"Everything he buried.\n\n" + \
"Everything The Canvas tried to keep quiet.\n\n\n" + \
"Fuse was built to monitor emotion.\n\n" + \
"Detect.\n" + \
"Classify.\n" + \
"Report.\n\n" + \
"Then the surge hit him too.\n\n\n" + \
"The Canvas felt the signal.\n\n" + \
"A miner bonded with something\n" + \
"they could not control.\n\n" + \
"An EME drone went rogue.\n\n" + \
"The mine went into lockdown.\n\n\n" + \
"Now the mine is collapsing.\n\n" + \
"Canvas patrols are closing in.\n\n\n" + \
"Break rocks.\n" + \
"Collect Mourks.\n" + \
"Find the Corepath.\n\n\n" + \
"And do not let them curate you."

# ── Timing ────────────────────────────────────────────────────────────────────
const SCROLL_DURATION  := 62.0   # total seconds
const CROSSFADE_TIME   := 2.2    # seconds to blend between panels
const PAN_AMOUNT       := 48.0   # px each panel drifts downward while shown

# ── Panel art paths (in narrative order) ─────────────────────────────────────
const PANEL_PATHS := [
	"res://echoveil/backgrounds/panel_01.png",
	"res://echoveil/backgrounds/panel_02.png",
	"res://echoveil/backgrounds/panel_03.png",
	"res://echoveil/backgrounds/panel_04.png",
	"res://echoveil/backgrounds/panel_05.png",
]

var _done   := false
var _tween  : Tween   # text scroll tween

func _ready() -> void:
	clip_contents = true
	var vp := get_viewport_rect().size
	var per := SCROLL_DURATION / PANEL_PATHS.size()   # seconds per panel

	# ── 1. Black base ─────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── 2. Comic panels — scroll opposite to text (drift DOWN) ────────────────
	for i in range(PANEL_PATHS.size()):
		var panel := TextureRect.new()
		if ResourceLoader.exists(PANEL_PATHS[i]):
			panel.texture = load(PANEL_PATHS[i])
		panel.expand_mode   = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		panel.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		# Make the rect taller than viewport so the downward pan doesn't show a gap
		panel.size          = Vector2(vp.x, vp.y + PAN_AMOUNT)
		panel.position      = Vector2(0.0, -PAN_AMOUNT)   # start panned up
		panel.modulate.a    = 1.0 if i == 0 else 0.0
		add_child(panel)

		var t_start := float(i) * per
		var t_end   := t_start + per

		# Crossfade in (skip for first panel — it starts visible)
		if i > 0:
			var fade_in := create_tween()
			fade_in.tween_interval(t_start - CROSSFADE_TIME)
			fade_in.tween_property(panel, "modulate:a", 1.0, CROSSFADE_TIME) \
				.set_trans(Tween.TRANS_SINE)

		# Crossfade out (skip for last panel — TransitionLayer handles final fade)
		if i < PANEL_PATHS.size() - 1:
			var fade_out := create_tween()
			fade_out.tween_interval(t_end)
			fade_out.tween_property(panel, "modulate:a", 0.0, CROSSFADE_TIME) \
				.set_trans(Tween.TRANS_SINE)

		# Downward parallax pan  (-PAN_AMOUNT → 0 over each panel's slot)
		var pan := create_tween()
		pan.tween_interval(t_start)
		pan.tween_property(panel, "position:y", 0.0, per) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# ── 3. Dark scrim — keeps text legible over bright art ────────────────────
	var scrim := ColorRect.new()
	scrim.color = Color(0.0, 0.0, 0.02, 0.62)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)

	# ── 4. Scrolling lore text (moves UP) ─────────────────────────────────────
	var lbl_w := vp.x * 0.60
	var lbl := Label.new()
	lbl.text = LORE_TEXT
	lbl.add_theme_font_size_override("font_size", 35)
	lbl.add_theme_color_override("font_color", Color(0.93, 0.83, 0.38, 1.0))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2((vp.x - lbl_w) * 0.5, vp.y + 20.0)
	lbl.custom_minimum_size.x = lbl_w
	lbl.size.x = lbl_w
	add_child(lbl)

	_tween = create_tween()
	_tween.tween_property(lbl, "position:y", -2200.0, SCROLL_DURATION) \
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_finish)

	# ── 5. Black edge bars (clean entry/exit for text) ────────────────────────
	var top_bar := ColorRect.new()
	top_bar.color = Color(0, 0, 0, 1)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 52.0
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)

	var bot_bar := ColorRect.new()
	bot_bar.color = Color(0, 0, 0, 0.90)
	bot_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_bar.offset_top = -46.0
	bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bot_bar)

	# ── 6. SKIP button — large touch target, safe-area-aware ────────────────
	var skip_btn := Button.new()
	skip_btn.text = "SKIP  ›"
	skip_btn.add_theme_font_size_override("font_size", 32)
	skip_btn.add_theme_color_override("font_color", Color(0.55, 0.42, 0.70, 0.90))
	skip_btn.custom_minimum_size = Vector2(180, 72)
	skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# offset_bottom = -90 keeps the button above the iOS home indicator bar
	skip_btn.offset_left   = -210.0
	skip_btn.offset_top    = -108.0
	skip_btn.offset_right  = -30.0
	skip_btn.offset_bottom = -36.0
	skip_btn.mouse_filter  = Control.MOUSE_FILTER_STOP
	skip_btn.z_index       = 10
	skip_btn.pressed.connect(func():
		if _tween: _tween.kill()
		_finish()
	)
	add_child(skip_btn)

	TransitionLayer.fade_in(1.6)

# ── Input ──────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	var skip := false
	if event is InputEventKey         and event.pressed and not event.echo: skip = true
	elif event is InputEventMouseButton  and event.pressed:                 skip = true
	elif event is InputEventJoypadButton and event.pressed:                 skip = true
	elif event is InputEventScreenTouch  and event.pressed:                 skip = true
	if skip:
		if _tween: _tween.kill()
		_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://shift_protocol.tscn"),
		0.9
	)
