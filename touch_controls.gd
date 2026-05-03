extends CanvasLayer

# Movement is handled entirely by joystick.gd (child node "Joystick").

func _on_jump_down():   Input.action_press("jump")
func _on_jump_up():     Input.action_release("jump")
func _on_swing_down():  Input.action_press("swing")
func _on_swing_up():    Input.action_release("swing")
func _on_break_down():  Input.action_press("break_power")
func _on_break_up():    Input.action_release("break_power")
func _on_roll_down():   Input.action_press("roll")
func _on_roll_up():     Input.action_release("roll")
