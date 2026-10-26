extends Control
class_name VirtualJoystick

signal axis_changed(vector: Vector2)

@export var deadzone: float = 0.15
@export var max_radius: float = 80.0
@export var visual_radius: float = 60.0
@export var stick_snap_speed: float = 15.0

var _center_pos: Vector2 = Vector2.ZERO
var _current_vector: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _touch_id: int = -1
var _stick_node: Control
var _base_node: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	_stick_node = get_node("Stick")
	_base_node = get_node("Base")
	_base_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_pos = _base_node.position + _base_node.size * 0.5
	_stick_node.position = _base_node.position + (_base_node.size - _stick_node.size) * 0.5
	_hide_stick()
	
	# Connect to InputManager
	if InputManager:
		pass  # Will call InputManager.set_touch_move_vector in _update_stick_position

func _hide_stick() -> void:
	# Visual-only helper. Do not call _reset_stick_internal() here: reset also
	# hides the stick, so calling it from both functions caused infinite recursion.
	_stick_node.visible = false
	_base_node.modulate = Color(1, 1, 1, 0.3)

func _show_stick() -> void:
	_stick_node.visible = true
	_base_node.modulate = Color(1, 1, 1, 0.6)

func _input(event: InputEvent) -> void:
	# Read screen-space touch events globally so release/drag still works after
	# a finger moves just outside the joystick's Control rectangle.
	if event is InputEventScreenTouch:
		handle_touch_event(event)
	elif event is InputEventScreenDrag:
		handle_drag_event(event)

func handle_touch_event(event: InputEventScreenTouch) -> void:
	_handle_touch(event)

func handle_drag_event(event: InputEventScreenDrag) -> void:
	_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	# Convert the actual touch point into the joystick's local coordinates.
	var local_pos: Vector2 = _base_node.get_global_transform_with_canvas().affine_inverse() * event.position
	var distance = local_pos.distance_to(_base_node.size * 0.5)
	
	if event.pressed and not _dragging and distance <= max_radius:
		_dragging = true
		_touch_id = event.index
		_show_stick()
		_update_stick_position(local_pos)
	elif not event.pressed and event.index == _touch_id:
		_reset_stick()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if _dragging and event.index == _touch_id:
		var local_pos: Vector2 = _base_node.get_global_transform_with_canvas().affine_inverse() * event.position
		_update_stick_position(local_pos)

func _update_stick_position(base_local_pos: Vector2) -> void:
	var relative: Vector2 = base_local_pos - _base_node.size * 0.5
	var distance: float = relative.length()

	if distance > visual_radius:
		relative = relative.normalized() * visual_radius
		distance = visual_radius

	# Stick is a sibling of Base, so convert from Base-local coordinates and
	# subtract half its size to keep its center under the user's finger.
	_stick_node.position = _base_node.position + _base_node.size * 0.5 + relative - _stick_node.size * 0.5
	
	if distance > deadzone * visual_radius:
		var strength = (distance - deadzone * visual_radius) / (visual_radius * (1.0 - deadzone))
		_current_vector = relative.normalized() * strength
	else:
		_current_vector = Vector2.ZERO
	
	if InputManager:
		InputManager.set_touch_move_vector(_current_vector)
	
	axis_changed.emit(_current_vector)

func _reset_stick() -> void:
	_reset_stick_internal()

func _reset_stick_internal() -> void:
	_dragging = false
	_touch_id = -1
	_current_vector = Vector2.ZERO
	_stick_node.position = _base_node.position + (_base_node.size - _stick_node.size) * 0.5
	_hide_stick()
	if InputManager:
		InputManager.set_touch_move_vector(Vector2.ZERO)
	axis_changed.emit(Vector2.ZERO)

func get_vector() -> Vector2:
	return _current_vector

func is_dragging() -> bool:
	return _dragging