extends CanvasLayer

const NUM_REGIONS = [
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

var _digit_textures: Array = []
var _digit_rects: Array = []

func _ready() -> void:
	TransitionLayer.fade_in(0.5)

	for i in range(10):
		var img = load("res://echoveil/UI/mourk counter/numbers/Numbers/" + str(i) + ".png")
		var at = AtlasTexture.new()
		at.atlas = img
		var b = NUM_REGIONS[i]
		at.region = Rect2(b[0], b[1], b[2], b[3])
		_digit_textures.append(at)

	$ShardLabel.visible = false

	var lefts  = [128.0, 163.0, 204.0]
	var rights = [161.0, 202.0, 250.0]
	for i in 3:
		var r = TextureRect.new()
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.offset_left   = lefts[i]
		r.offset_top    = 16.0
		r.offset_right  = rights[i]
		r.offset_bottom = 86.0
		add_child(r)
		_digit_rects.append(r)

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var count = max(0, player.shards_collected)
	var digits = [count / 100, (count / 10) % 10, count % 10]
	var leading := true
	for i in 3:
		var is_leading_zero = leading and digits[i] == 0 and i < 2
		if is_leading_zero:
			_digit_rects[i].visible = false
		else:
			leading = false
			_digit_rects[i].visible = true
			_digit_rects[i].texture = _digit_textures[digits[i]]

	var health = player.health
	$HealthShard1.visible = health >= 1
	$HealthShard2.visible = health >= 2
	$HealthShard3.visible = health >= 3

	var lives = GameState.lives
	if lives >= 3:
		$LivesLabel.text = "♦ BREAK"
		$LivesLabel.add_theme_color_override("font_color", Color(1.0, 0.0, 1.0, 1.0))
	else:
		var lives_str := ""
		for i in range(lives):
			lives_str += "♦ "
		$LivesLabel.text = lives_str.strip_edges()
		$LivesLabel.add_theme_color_override("font_color", Color(0.9, 0.3, 1.0, 1.0))
