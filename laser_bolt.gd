extends Area2D

const SPEED    := 380.0
const MAX_DIST := 650.0

var _velocity := Vector2.ZERO
var _traveled := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func launch(target_pos: Vector2) -> void:
	var dir := (target_pos - global_position).normalized()
	_velocity = dir * SPEED
	rotation = dir.angle()

func _process(delta: float) -> void:
	var step := _velocity * delta
	position += step
	_traveled += step.length()
	if _traveled >= MAX_DIST:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("hit_by_drone"):
		body.hit_by_drone()
	queue_free()
