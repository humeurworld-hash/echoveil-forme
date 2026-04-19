extends CanvasLayer

func _on_left_down(): Input.action_press("move_left")
func _on_left_up(): Input.action_release("move_left")
func _on_right_down(): Input.action_press("move_right")
func _on_right_up(): Input.action_release("move_right")
func _on_jump_down(): Input.action_press("jump")
func _on_jump_up(): Input.action_release("jump")
func _on_swing_down(): Input.action_press("swing")
func _on_swing_up(): Input.action_release("swing")
func _on_break_down(): Input.action_press("break_power")
func _on_break_up(): Input.action_release("break_power")
