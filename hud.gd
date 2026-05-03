extends CanvasLayer

const NUM_REGIONS : Array = [
	[183, 206, 163, 186],  # 0
	[454, 207, 124, 185],  # 1
	[689, 207, 159, 185],  # 2
	[944, 207, 162, 185],  # 3
	[1193, 207, 174, 185], # 4
	[168, 553, 167, 180],  # 5
	[425, 553, 166, 180],  # 6
	[684, 553, 147, 180],  # 7
	[1201, 552, 166, 181], # 8
	[944, 555, 199, 177],  # 9
]

var _digit_textures : Array        = []
var _digit_rects    : Array        = []
var _xp_bar_fill    : ColorRect    = null
var _xp_label       : Label       = null

const PAUSE_MENU_SCENE := preload("res://pause_menu.tscn")

func _ready() -> void:
	TransitionLayer.fade_in(0.5)

	# ── Pause button ─────────────────────────────────────────────────────────
	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.add_theme_font_size_override("font_size", 28)
	pause_btn.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80, 0.80))
	pause_btn.custom_minimum_size = Vector2(80, 64)
	pause_btn.anchor_left   = 0.5
	pause_btn.anchor_top    = 0.0
	pause_btn.anchor_right  = 0.5
	pause_btn.anchor_bottom = 0.0
	pause_btn.offset_left   = -40.0
	pause_btn.offset_top    = 10.0
	pause_btn.offset_right  = 40.0
	pause_btn.offset_bottom = 74.0
	pause_btn.pressed.connect(_open_pause)
	add_child(pause_btn)

	# ── Digit textures for shard counter ─────────────────────────────────────
	for i in range(10):
		var img : Texture2D = load(
			"res://echoveil/UI/mourk counter/numbers/Numbers/" + str(i) + ".png")
		var at := AtlasTexture.new()
		at.atlas  = img
		var b : Array = NUM_REGIONS[i]
		at.region = Rect2(int(b[0]), int(b[1]), int(b[2]), int(b[3]))
		_digit_textures.append(at)

	$ShardLabel.visible = false

	var lefts  : Array[float] = [128.0, 163.0, 204.0]
	var rights : Array[float] = [161.0, 202.0, 250.0]
	for i in 3:
		var rct := TextureRect.new()
		rct.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		rct.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rct.offset_left   = lefts[i]
		rct.offset_top    = 16.0
		rct.offset_right  = rights[i]
		rct.offset_bottom = 86.0
		add_child(rct)
		_digit_rects.append(rct)

	# ── XP bar — bottom of screen ─────────────────────────────────────────────
	var xp_bg := ColorRect.new()
	xp_bg.color    = Color(0.07, 0.08, 0.13, 0.82)
	xp_bg.position = Vector2(0.0, 1058.0)
	xp_bg.size     = Vector2(1920.0, 22.0)
	add_child(xp_bg)

	_xp_bar_fill          = ColorRect.new()
	_xp_bar_fill.color    = Color(0.15, 0.90, 0.85, 0.92)
	_xp_bar_fill.position = Vector2(0.0, 1058.0)
	_xp_bar_fill.size     = Vector2(0.0, 22.0)
	add_child(_xp_bar_fill)

	_xp_label          = Label.new()
	_xp_label.position = Vector2(760.0, 1057.0)
	_xp_label.size     = Vector2(400.0, 22.0)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.add_theme_font_size_override("font_size", 13)
	_xp_label.add_theme_color_override("font_color", Color(0.88, 0.96, 0.94, 0.88))
	add_child(_xp_label)

func _open_pause() -> void:
	var menu := PAUSE_MENU_SCENE.instantiate()
	get_parent().add_child(menu)

func _process(_delta: float) -> void:
	# Read directly from GameState — player properties are just proxies to it anyway.
	var count   : int  = max(0, GameState.shards_collected)
	var d0      : int  = count / 100
	var d1      : int  = (count / 10) % 10
	var d2      : int  = count % 10
	var digs    : Array[int] = [d0, d1, d2]
	var leading : bool = true
	for i in 3:
		var is_zero : bool = leading and digs[i] == 0 and i < 2
		if is_zero:
			_digit_rects[i].visible = false
		else:
			leading = false
			_digit_rects[i].visible = true
			_digit_rects[i].texture = _digit_textures[digs[i]]

	# ── Health hearts ─────────────────────────────────────────────────────────
	var hp : int = GameState.health
	$HealthShard1.visible = hp >= 1
	$HealthShard2.visible = hp >= 2
	$HealthShard3.visible = hp >= 3

	# ── Player level ──────────────────────────────────────────────────────────
	$LivesLabel.text = "LV  %d" % GameState.player_level
	$LivesLabel.add_theme_color_override("font_color", Color(0.15, 0.95, 0.85, 1.0))

	# ── XP bar ────────────────────────────────────────────────────────────────
	var ratio : float = clampf(
		float(GameState.xp) / float(GameState.xp_to_next()), 0.0, 1.0)
	if _xp_bar_fill:
		_xp_bar_fill.size.x = 1920.0 * ratio
	if _xp_label:
		_xp_label.text = "XP  %d / %d" % [GameState.xp, GameState.xp_to_next()]
