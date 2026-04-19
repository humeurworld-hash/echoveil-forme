extends CanvasLayer

var overlay: ColorRect

func _ready() -> void:
	layer = 100
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func fade_in(duration: float = 0.4) -> void:
	overlay.color = Color(0, 0, 0, 1)
	await get_tree().process_frame
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), duration)

func fade_out(callback: Callable, duration: float = 0.4) -> void:
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), duration)
	tween.tween_callback(callback)
