extends Button
class_name TouchButton

signal released

@export var action_name: String = ""
@export var hold_mode: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	toggled.connect(_on_toggled)
	pressed.connect(_on_pressed)
	_update_visual()

func _on_button_down() -> void:
	if action_name == "sprint" and InputManager:
		InputManager.set_touch_sprint(true)
	_update_visual()

func _on_button_up() -> void:
	if action_name == "sprint" and InputManager:
		InputManager.set_touch_sprint(false)
	released.emit()
	_update_visual()

func _on_toggled(is_on: bool) -> void:
	if action_name == "crouch" and InputManager:
		InputManager.set_touch_crouch(is_on)
	_update_visual()

func _on_pressed() -> void:
	if not InputManager:
		return
	match action_name:
		"interact":
			InputManager.set_touch_interact(true)
		"pause":
			InputManager.set_touch_pause(true)

func _update_visual() -> void:
	if button_pressed:
		modulate = Color(0.8, 1.0, 0.8, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 0.85)
