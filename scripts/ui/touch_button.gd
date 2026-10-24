extends TextureRect
class_name TouchButton

signal pressed
signal released

@export var action_name: String = ""
@export var toggle_mode: bool = false
@export var hold_mode: bool = false

var _pressed: bool = false
var _touch_id: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_visual()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var point = get_local_mouse_position()
	var rect = Rect2(Vector2.ZERO, size)
	
	if event.pressed:
		if rect.has_point(point):
			_touch_id = event.index
			if toggle_mode:
				_pressed = not _pressed
				if _pressed:
					pressed.emit()
					_notify_input_manager(true)
				else:
					released.emit()
					_notify_input_manager(false)
			else:
				_pressed = true
				pressed.emit()
				_notify_input_manager(true)
			_update_visual()
	elif not event.pressed and event.index == _touch_id:
		if not toggle_mode:
			_pressed = false
			released.emit()
			_notify_input_manager(false)
			_update_visual()
		_touch_id = -1

func _notify_input_manager(pressed: bool) -> void:
	if not InputManager or action_name.is_empty():
		return
	match action_name:
		"sprint":
			InputManager.set_touch_sprint(pressed)
		"crouch":
			InputManager.set_touch_crouch(pressed)

func is_pressed() -> bool:
	return _pressed

func set_pressed(value: bool) -> void:
	_pressed = value
	_update_visual()

func _update_visual() -> void:
	if _pressed:
		modulate = Color(0.8, 1.0, 0.8, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 0.7)