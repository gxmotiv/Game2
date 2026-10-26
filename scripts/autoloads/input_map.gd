extends Node

class_name InputManagerClass

signal action_added(action_name: String)
signal action_removed(action_name: String)

const ACTION_TYPE_BUTTON = 0
const ACTION_TYPE_AXIS = 1
const ACTION_TYPE_AXIS_2D = 2

const KEY_A = 65
const KEY_D = 68
const KEY_W = 87
const KEY_S = 83
const KEY_E = 69
const KEY_SPACE = 32
const KEY_SHIFT = 340
const KEY_CTRL = 341
const KEY_ESCAPE = 256
const KEY_ENTER = 36
const KEY_Q = 81
const KEY_UNKNOWN = 0

const JOY_A = 0
const JOY_B = 1
const JOY_START = 9
const JOY_R2 = 11
const JOY_L2 = 12
const JOY_DPAD_UP = 12
const JOY_DPAD_DOWN = 13
const JOY_DPAD_LEFT = 14
const JOY_DPAD_RIGHT = 15

const JOY_AXIS_0 = 0
const JOY_AXIS_1 = 1
const JOY_AXIS_2 = 2
const JOY_AXIS_3 = 3
const JOY_AXIS_4 = 4

const MOUSE_BUTTON_LEFT = 0
const MOUSE_BUTTON_WHEEL_UP = 4
const MOUSE_BUTTON_WHEEL_DOWN = 5

var _action_definitions: Dictionary = {
	"move_left": {
		"type": ACTION_TYPE_AXIS,
		"deadzone": 0.15,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_A},
			{"type": "InputEventJoypadMotion", "axis": JOY_AXIS_0}
		]
	},
	"move_right": {
		"type": ACTION_TYPE_AXIS,
		"deadzone": 0.15,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_D},
			{"type": "InputEventJoypadMotion", "axis": JOY_AXIS_0}
		]
	},
	"move_forward": {
		"type": ACTION_TYPE_AXIS,
		"deadzone": 0.15,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_W},
			{"type": "InputEventJoypadMotion", "axis": JOY_AXIS_1}
		]
	},
	"move_backward": {
		"type": ACTION_TYPE_AXIS,
		"deadzone": 0.15,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_S},
			{"type": "InputEventJoypadMotion", "axis": JOY_AXIS_1}
		]
	},
	"sprint": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_SHIFT},
			{"type": "InputEventJoypadButton", "button_index": JOY_R2}
		]
	},
	"crouch": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_CTRL},
			{"type": "InputEventJoypadButton", "button_index": JOY_L2}
		]
	},
	"interact": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_E},
			{"type": "InputEventKey", "physical_keycode": KEY_SPACE},
			{"type": "InputEventJoypadButton", "button_index": JOY_A}
		]
	},
	"camera_orbit": {
		"type": ACTION_TYPE_AXIS_2D,
		"deadzone": 0.15,
		"events": [
			{"type": "InputEventMouseMotion"},
			{"type": "InputEventJoypadMotion", "axis": JOY_AXIS_2},
			{"type": "InputEventJoypadMotion", "axis": JOY_AXIS_3}
		]
	},
	"camera_zoom": {
		"type": ACTION_TYPE_AXIS,
		"deadzone": 0.15,
		"events": [
			{"type": "InputEventMouseButton", "button_index": MOUSE_BUTTON_WHEEL_UP},
			{"type": "InputEventMouseButton", "button_index": MOUSE_BUTTON_WHEEL_DOWN},
			{"type": "InputEventJoypadMotion", "axis": JOY_AXIS_4}
		]
	},
	"pause": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_ESCAPE},
			{"type": "InputEventJoypadButton", "button_index": JOY_START}
		]
	},
	"hack_up": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_W},
			{"type": "InputEventJoypadButton", "button_index": JOY_DPAD_UP}
		]
	},
	"hack_down": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_S},
			{"type": "InputEventJoypadButton", "button_index": JOY_DPAD_DOWN}
		]
	},
	"hack_left": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_A},
			{"type": "InputEventJoypadButton", "button_index": JOY_DPAD_LEFT}
		]
	},
	"hack_right": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_D},
			{"type": "InputEventJoypadButton", "button_index": JOY_DPAD_RIGHT}
		]
	},
	"hack_confirm": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_ENTER},
			{"type": "InputEventKey", "physical_keycode": KEY_SPACE},
			{"type": "InputEventJoypadButton", "button_index": JOY_A}
		]
	},
	"hack_cancel": {
		"type": ACTION_TYPE_BUTTON,
		"deadzone": 0.5,
		"events": [
			{"type": "InputEventKey", "physical_keycode": KEY_ESCAPE},
			{"type": "InputEventKey", "physical_keycode": KEY_Q},
			{"type": "InputEventJoypadButton", "button_index": JOY_B}
		]
	}
}

func _ready() -> void:
	_register_all_actions()

func _register_all_actions() -> void:
	for action_name in _action_definitions:
		_register_action(action_name, _action_definitions[action_name])

func _register_action(action_name: String, definition: Dictionary) -> void:
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	
	var action_type: int = definition.get("type", ACTION_TYPE_BUTTON)
	var deadzone: float = definition.get("deadzone", 0.5)
	var events: Array = definition.get("events", [])
	
	InputMap.add_action(action_name, action_type)
	InputMap.action_set_deadzone(action_name, deadzone)
	
	for event_def in events:
		var event = _create_event_from_def(event_def)
		if event:
			InputMap.action_add_event(action_name, event)
	
	action_added.emit(action_name)

func _create_event_from_def(def: Dictionary) -> InputEvent:
	var event_type: String = def.get("type", "")
	
	match event_type:
		"InputEventKey":
			var event = InputEventKey.new()
			event.physical_keycode = def.get("physical_keycode", KEY_UNKNOWN)
			return event
		"InputEventJoypadButton":
			var event = InputEventJoypadButton.new()
			event.button_index = def.get("button_index", JOY_A)
			return event
		"InputEventJoypadMotion":
			var event = InputEventJoypadMotion.new()
			event.axis = def.get("axis", JOY_AXIS_0)
			return event
		"InputEventMouseMotion":
			return InputEventMouseMotion.new()
		"InputEventMouseButton":
			var event = InputEventMouseButton.new()
			event.button_index = def.get("button_index", MOUSE_BUTTON_LEFT)
			return event
		_:
			return null

func get_action_strength(action_name: String, exact_match: bool = false) -> float:
	return Input.get_action_strength(action_name, exact_match)

func get_action_raw_strength(action_name: String, exact_match: bool = false) -> float:
	return Input.get_action_raw_strength(action_name, exact_match)

func is_action_pressed(action_name: String, exact_match: bool = false) -> bool:
	return Input.is_action_pressed(action_name, exact_match)

func is_action_just_pressed(action_name: String, exact_match: bool = false) -> bool:
	return Input.is_action_just_pressed(action_name, exact_match)

func is_action_just_released(action_name: String, exact_match: bool = false) -> bool:
	return Input.is_action_just_released(action_name, exact_match)

func get_vector(action_neg_x: String, action_pos_x: String, action_neg_y: String, action_pos_y: String, deadzone: float = -1.0) -> Vector2:
	return Input.get_vector(action_neg_x, action_pos_x, action_neg_y, action_pos_y, deadzone)

func get_movement_vector() -> Vector2:
	var deadzone = 0.15
	return Input.get_vector("move_left", "move_right", "move_forward", "move_backward", deadzone)

func get_camera_orbit_vector() -> Vector2:
	var deadzone = 0.15
	return Input.get_vector("camera_orbit", "camera_orbit", "camera_orbit", "camera_orbit", deadzone)

func is_sprinting() -> bool:
	return Input.is_action_pressed("sprint")

func is_crouching() -> bool:
	return Input.is_action_pressed("crouch")

func set_touch_interact(pressed: bool) -> void:
	if pressed:
		_virtual_actions["touch_interact_just_pressed"] = true

func set_touch_pause(pressed: bool) -> void:
	if pressed:
		_virtual_actions["touch_pause_just_pressed"] = true

func is_interacting() -> bool:
	var touch_pressed: bool = bool(_virtual_actions["touch_interact_just_pressed"])
	_virtual_actions["touch_interact_just_pressed"] = false
	return touch_pressed or Input.is_action_just_pressed("interact")

func is_paused() -> bool:
	var touch_pressed: bool = bool(_virtual_actions["touch_pause_just_pressed"])
	_virtual_actions["touch_pause_just_pressed"] = false
	return touch_pressed or Input.is_action_just_pressed("pause")

func get_hack_direction() -> Vector2:
	return Input.get_vector("hack_left", "hack_right", "hack_up", "hack_down", 0.5)

func is_hack_confirm() -> bool:
	return Input.is_action_just_pressed("hack_confirm")

func is_hack_cancel() -> bool:
	return Input.is_action_just_pressed("hack_cancel")

# Virtual action state for touch controls
var _virtual_actions: Dictionary = {
	"touch_move_vector": Vector2.ZERO,
	"touch_sprint": false,
	"touch_crouch": false,
	"touch_interact_just_pressed": false,
	"touch_pause_just_pressed": false
}

func set_touch_move_vector(vector: Vector2) -> void:
	_virtual_actions["touch_move_vector"] = vector

func set_touch_sprint(pressed: bool) -> void:
	_virtual_actions["touch_sprint"] = pressed

func set_touch_crouch(pressed: bool) -> void:
	_virtual_actions["touch_crouch"] = pressed

func get_touch_move_vector() -> Vector2:
	return _virtual_actions["touch_move_vector"]

func is_touch_sprinting() -> bool:
	return _virtual_actions["touch_sprint"]

func is_touch_crouching() -> bool:
	return _virtual_actions["touch_crouch"]

func register_custom_action(action_name: String, action_type: int = ACTION_TYPE_BUTTON, deadzone: float = 0.5, events: Array = []) -> void:
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	
	InputMap.add_action(action_name, action_type)
	InputMap.action_set_deadzone(action_name, deadzone)
	for event in events:
		InputMap.action_add_event(action_name, event)
	
	_action_definitions[action_name] = {
		"type": action_type,
		"deadzone": deadzone,
		"events": events
	}
	action_added.emit(action_name)

func unregister_action(action_name: String) -> void:
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
		_action_definitions.erase(action_name)
		action_removed.emit(action_name)

func get_all_actions() -> Array[String]:
	return _action_definitions.keys()

func has_action(action_name: String) -> bool:
	return InputMap.has_action(action_name)

func save_action_map() -> void:
	var config = ConfigFile.new()
	for action_name in _action_definitions:
		var events = InputMap.action_get_events(action_name)
		var event_data = []
		for event in events:
			event_data.append(_event_to_dict(event))
		config.set_value("input_map", action_name, {
			"type": _action_definitions[action_name]["type"],
			"deadzone": _action_definitions[action_name]["deadzone"],
			"events": event_data
		})
	config.save("user://input_map.cfg")

func load_action_map() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://input_map.cfg")
	if err != OK:
		return
	
	for action_name in config.get_section_keys("input_map"):
		var data = config.get_value("input_map", action_name)
		var events = []
		for event_dict in data["events"]:
			events.append(_dict_to_event(event_dict))
		_register_action(action_name, {
			"type": data["type"],
			"deadzone": data["deadzone"],
			"events": events
		})

func _event_to_dict(event: InputEvent) -> Dictionary:
	var dict = {"type": event.get_class()}
	match event:
		InputEventKey:
			dict["physical_keycode"] = event.physical_keycode
		InputEventJoypadButton:
			dict["button_index"] = event.button_index
		InputEventJoypadMotion:
			dict["axis"] = event.axis
		InputEventMouseButton:
			dict["button_index"] = event.button_index
	return dict

func _dict_to_event(dict: Dictionary) -> InputEvent:
	var event_type: String = dict.get("type", "")
	match event_type:
		"InputEventKey":
			var event = InputEventKey.new()
			event.physical_keycode = dict.get("physical_keycode", KEY_UNKNOWN)
			return event
		"InputEventJoypadButton":
			var event = InputEventJoypadButton.new()
			event.button_index = dict.get("button_index", JOY_A)
			return event
		"InputEventJoypadMotion":
			var event = InputEventJoypadMotion.new()
			event.axis = dict.get("axis", JOY_AXIS_0)
			return event
		"InputEventMouseButton":
			var event = InputEventMouseButton.new()
			event.button_index = dict.get("button_index", MOUSE_BUTTON_LEFT)
			return event
	return null