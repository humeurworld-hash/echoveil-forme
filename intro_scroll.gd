extends Control

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

# Total estimated text height ~2000px at font 19.
# We scroll from just below viewport to -2200 over 62 seconds.
const SCROLL_DURATION := 62.0
const SCROLL_END_Y    := -2200.0

var _done  := false
var _tween : Tween

func _ready() -> void:
	var vp := get_viewport_rect().size

	# ── Background ──────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Scrolling label ─────────────────────────────────────────────────────
	var lbl_w := vp.x * 0.60
	var lbl := Label.new()
	lbl.text = LORE_TEXT
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", Color(0.91, 0.79, 0.30, 1.0))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2((vp.x - lbl_w) * 0.5, vp.y + 20.0)
	lbl.custom_minimum_size.x = lbl_w
	lbl.size.x = lbl_w
	add_child(lbl)

	# ── Tween ────────────────────────────────────────────────────────────────
	_tween = create_tween()
	_tween.tween_property(lbl, "position:y", SCROLL_END_Y, SCROLL_DURATION) \
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_finish)

	# ── Top black bar (prevents text hard-appearing at the top edge) ─────────
	var top := ColorRect.new()
	top.color = Color(0, 0, 0, 1)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 52.0
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)

	# ── Bottom strip + skip hint ─────────────────────────────────────────────
	var bot := ColorRect.new()
	bot.color = Color(0, 0, 0, 0.88)
	bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_top = -46.0
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bot)

	var hint := Label.new()
	hint.text = "— press any key to skip —"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.44, 0.34, 0.54, 0.68))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -30.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	TransitionLayer.fade_in(1.4)

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	var skip := false
	if event is InputEventKey       and event.pressed and not event.echo:
		skip = true
	elif event is InputEventMouseButton  and event.pressed:
		skip = true
	elif event is InputEventJoypadButton and event.pressed:
		skip = true
	if skip:
		if _tween:
			_tween.kill()
		_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	TransitionLayer.fade_out(
		func(): get_tree().call_deferred("change_scene_to_file", "res://shift_protocol.tscn"),
		0.9
	)
