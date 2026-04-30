extends Area2D

const SPEED    := 380.0
const MAX_DIST := 600.0

var _velocity := Vector2.ZERO
var _traveled := 0.0
var _active   := false   # grace period prevents hitting guard or nearby player on spawn

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Short delay before collision activates so bolt clears the guard's hitbox
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self):
		_active = true

func launch(target_pos: Vector2) -> void:
	var dir := (target_pos - global_position).normalized()
	_velocity = dir * SPEED
	rotation = dir.angle()

func _process(delta: float) -> void:
	if _velocity == Vector2.ZERO:
		return
	var step := _velocity * delta
	position += step
	_traveled += step.length()
	if _traveled >= MAX_DIST:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body.is_in_group("player") and body.has_method("hit_by_drone"):
		body.hit_by_drone()
	queue_free()
