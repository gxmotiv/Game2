extends Button
class_name TouchButton

@export var action_name: String = ""
@export var hold_mode: bool = false

func _ready() -> void:
	# Use Godot's native Button input handling for Android touch and mouse.
	mouse_filter = Control.MOUSE_FILTER_STOP
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	toggled.connect(_on_toggled)

func _on_button_down() -> void:
	if not InputManager or action_name.is_empty():
		return

	match action_name:
		"interact":
			Input.action_press("interact")
		"sprint":
			InputManager.set_touch_sprint(true)

func _on_button_up() -> void:
	if not InputManager or action_name.is_empty():
		return

	match action_name:
		"interact":
			Input.action_release("interact")
		"sprint":
			InputManager.set_touch_sprint(false)

func _on_toggled(button_pressed: bool) -> void:
	if action_name == "crouch" and InputManager:
		InputManager.set_touch_crouch(button_pressed)
