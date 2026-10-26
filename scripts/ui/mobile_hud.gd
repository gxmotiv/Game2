extends CanvasLayer

# Some packed-scene imports on the Android/debug path have produced Control
# nodes without their per-node script instances. Attach the required scripts
# from the HUD root's _enter_tree, before the child controls receive _ready.
func _enter_tree() -> void:
	_attach_control_script("JoystickContainer/VirtualJoystick", "res://scripts/ui/virtual_joystick.gd")
	_attach_control_script("ButtonContainer/InteractButton", "res://scripts/ui/touch_button.gd")
	_attach_control_script("ButtonContainer/SprintButton", "res://scripts/ui/touch_button.gd")
	_attach_control_script("ButtonContainer/CrouchButton", "res://scripts/ui/touch_button.gd")
	_attach_control_script("PauseButton", "res://scripts/ui/touch_button.gd")

func _attach_control_script(node_path: String, script_path: String) -> void:
	var control: Node = get_node_or_null(node_path)
	if control == null:
		push_error("Mobile HUD control is missing: " + node_path)
		return

	var desired_script: Script = load(script_path) as Script
	if desired_script == null:
		push_error("Mobile HUD script failed to load: " + script_path)
		return

	if control.get_script() != desired_script:
		control.set_script(desired_script)

