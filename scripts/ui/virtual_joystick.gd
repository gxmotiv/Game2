extends Control
class_name VirtualJoystick

signal axis_changed(vector: Vector2)

@export var deadzone: float = 0.15
@export var max_radius: float = 80.0
@export var visual_radius: float = 60.0

var _current_vector: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _touch_id: int = -1
var _stick_node: Control
var _base_node: Control

func _ready() -> void:
	_stick_node = get_node("Stick") as Control
	_base_node = get_node("Base") as Control

	# Let the parent joystick receive touch/mouse input instead of its visual children.
	_base_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_stick_internal()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _dragging and _touch_id == -2:
		_update_stick_position(_event_position_in_base(event.position))

func _event_position_in_base(viewport_position: Vector2) -> Vector2:
	var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * viewport_position
	return local_position - _base_node.position

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _dragging:
			return
		var base_position: Vector2 = _event_position_in_base(event.position)
		if base_position.distance_to(_base_node.size * 0.5) <= min(visual_radius, max_radius):
			_dragging = true
			_touch_id = event.index
			_show_stick()
			_update_stick_position(base_position)
	elif _dragging and event.index == _touch_id:
		_reset_stick_internal()

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if _dragging and event.index == _touch_id:
		_update_stick_position(_event_position_in_base(event.position))

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		if _dragging:
			return
		var base_position: Vector2 = _event_position_in_base(event.position)
		if base_position.distance_to(_base_node.size * 0.5) <= min(visual_radius, max_radius):
			_dragging = true
			_touch_id = -2
			_show_stick()
			_update_stick_position(base_position)
	elif _dragging and _touch_id == -2:
		_reset_stick_internal()

func _update_stick_position(base_local_position: Vector2) -> void:
	var relative: Vector2 = base_local_position - _base_node.size * 0.5
	var radius: float = min(visual_radius, max_radius)
	if relative.length() > radius:
		relative = relative.normalized() * radius

	_stick_node.position = _base_node.position + (_base_node.size - _stick_node.size) * 0.5 + relative

	var distance: float = relative.length()
	if distance > deadzone * radius and radius > 0.0:
		var strength: float = (distance - deadzone * radius) / (radius * (1.0 - deadzone))
		_current_vector = relative.normalized() * clampf(strength, 0.0, 1.0)
	else:
		_current_vector = Vector2.ZERO

	if InputManager:
		InputManager.set_touch_move_vector(_current_vector)
	axis_changed.emit(_current_vector)

func _show_stick() -> void:
	_stick_node.visible = true
	_base_node.modulate = Color(1.0, 1.0, 1.0, 0.6)

func _hide_stick() -> void:
	_stick_node.visible = false
	_base_node.modulate = Color(1.0, 1.0, 1.0, 0.3)

func _reset_stick_internal() -> void:
	# Do not call _hide_stick() from here: _ready() previously caused infinite recursion.
	_dragging = false
	_touch_id = -1
	_current_vector = Vector2.ZERO
	if _stick_node and _base_node:
		_stick_node.position = _base_node.position + (_base_node.size - _stick_node.size) * 0.5
		_hide_stick()
	if InputManager:
		InputManager.set_touch_move_vector(Vector2.ZERO)
	axis_changed.emit(Vector2.ZERO)

func get_vector() -> Vector2:
	return _current_vector

func is_dragging() -> bool:
	return _dragging
