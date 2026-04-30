extends Area2D

enum ShardType { TEAL, GREEN, ORANGE, PURPLE, GOLD }

@export var shard_type: ShardType = ShardType.TEAL

const SHARD_DATA := {
	ShardType.TEAL:   {"tint": Color(0.30, 0.90, 0.85, 1.0), "tex": "res://echoveil/shards/shard_teal.png"},
	ShardType.GREEN:  {"tint": Color(0.40, 1.00, 0.55, 1.0), "tex": "res://echoveil/shards/shard_green.png"},
	ShardType.ORANGE: {"tint": Color(1.00, 0.60, 0.15, 1.0), "tex": "res://echoveil/shards/shard_orange.png"},
	ShardType.PURPLE: {"tint": Color(0.80, 0.35, 1.00, 1.0), "tex": "res://echoveil/shards/shard_purple.png"},
	ShardType.GOLD:   {"tint": Color(1.00, 0.85, 0.15, 1.0), "tex": "res://echoveil/shards/shard_gold.png"},
}

var bob_offset: float = 0.0
var start_y: float = 0.0

func _ready() -> void:
	start_y = position.y
	bob_offset = randf() * TAU
	_apply_color()
	body_entered.connect(_on_body_entered)

func _apply_color() -> void:
	var data: Dictionary = SHARD_DATA[shard_type]
	var spr: Sprite2D = $Sprite2D
	var tex_path: String = str(data.get("tex", ""))
	if ResourceLoader.exists(tex_path):
		spr.texture = load(tex_path)
		spr.modulate = Color(1, 1, 1, 1)
	else:
		spr.modulate = data.get("tint", Color.WHITE)

func _process(delta: float) -> void:
	bob_offset += delta * 3.0
	position.y = start_y + sin(bob_offset) * 4.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)

func _collect(player: Node2D) -> void:
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * global_position
	var spr: Sprite2D = $Sprite2D
	var tex: Texture2D = spr.texture
	var data: Dictionary = SHARD_DATA[shard_type]
	var col: Color = data.get("tint", Color.WHITE)
	var parent: Node = get_parent()

	var sound := AudioStreamPlayer.new()
	sound.stream = load("res://echoveil/music/animations/shard revel.mp3")
	parent.add_child(sound)
	sound.play()
	sound.finished.connect(sound.queue_free)

	# Capture before queue_free — lambda must never touch self
	var st: int = shard_type
	queue_free()

	var anim_layer := CanvasLayer.new()
	anim_layer.layer = 20
	parent.add_child(anim_layer)

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.modulate = col
	sprite.scale = Vector2(0.035, 0.035)
	sprite.position = screen_pos
	anim_layer.add_child(sprite)

	var tween := anim_layer.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(0.055, 0.055), 0.08)
	tween.chain().set_parallel(true)
	tween.tween_property(sprite, "position", Vector2(31, 26), 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale", Vector2(0.008, 0.008), 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		GameState.shards_collected += 1
		match st:
			ShardType.GREEN:
				if GameState.health < 3:
					GameState.health = min(3, GameState.health + 1)
			ShardType.ORANGE:
				if is_instance_valid(player) and player.has_method("boost_speed"):
					player.boost_speed(3.5)
			ShardType.PURPLE:
				if is_instance_valid(player) and player.has_method("add_shield_progress"):
					player.add_shield_progress(3)
			ShardType.GOLD:
				GameState.health = 3
				if is_instance_valid(player) and player.has_method("force_shield"):
					player.force_shield()
		anim_layer.queue_free()
	)
