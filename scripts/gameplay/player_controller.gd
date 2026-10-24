extends CharacterBody3D
class_name PlayerController

@export_group("Movement")
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 6.0
@export var crouch_speed: float = 1.5
@export var acceleration: float = 20.0
@export var deceleration: float = 25.0
@export var air_acceleration: float = 5.0
@export var air_deceleration: float = 2.0
@export var gravity: float = 9.8
@export var jump_velocity: float = 5.0

@export_group("Camera")
@export var camera_distance: float = 8.0
@export var camera_height: float = 5.0
@export var camera_angle: float = 45.0
@export var camera_smooth_speed: float = 10.0

@export_group("Stance")
@export var crouch_height: float = 1.0
@export var standing_height: float = 1.8
@export var stance_change_speed: float = 10.0

@export_group("Interaction")
@export var interaction_range: float = 2.5
@export var interaction_check_interval: float = 0.1

var _target_velocity: Vector3 = Vector3.ZERO
var _is_sprinting: bool = false
var _is_crouching: bool = false
var _target_camera_pos: Vector3 = Vector3.ZERO
var _camera_pivot: Node3D
var _camera: Camera3D
var _collision_shape: CollisionShape3D
var _mesh: MeshInstance3D
var _capsule_shape: CapsuleShape3D
var _mesh_height: float = 1.8

# Interaction
var _interaction_timer: float = 0.0
var _current_interactable: Node3D
var _interaction_prompt: Label3D
var _in_puzzle: bool = false
var _hacking_puzzle: CanvasLayer

func _ready() -> void:
	_camera_pivot = get_node("CameraPivot")
	_camera = _camera_pivot.get_node("Camera3D")
	_collision_shape = get_node("CollisionShape3D")
	_mesh = get_node("MeshInstance3D")
	_capsule_shape = _collision_shape.shape as CapsuleShape3D
	_mesh_height = 1.8
	
	_setup_camera()
	_setup_input()
	
	# Find hacking puzzle in scene tree
	_hacking_puzzle = get_tree().root.find_child("HackingPuzzle", true, false)
	if not _hacking_puzzle:
		_hacking_puzzle = preload("res://scenes/ui/hacking_puzzle.tscn").instantiate()
		get_tree().root.add_child(_hacking_puzzle)

func _setup_camera() -> void:
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 5.0
	_camera.near = 0.1
	_camera.far = 100.0
	
	var angle_rad = deg_to_rad(camera_angle)
	_camera_pivot.rotation = Vector3(-angle_rad, 0, 0)
	_camera_pivot.position = Vector3(0, camera_height, camera_distance)

func _setup_input() -> void:
	InputManager.register_custom_action("move_left", InputManager.ACTION_TYPE_AXIS, 0.15, [
		{"type": "InputEventKey", "physical_keycode": 65}
	])
	InputManager.register_custom_action("move_right", InputManager.ACTION_TYPE_AXIS, 0.15, [
		{"type": "InputEventKey", "physical_keycode": 68}
	])
	InputManager.register_custom_action("move_forward", InputManager.ACTION_TYPE_AXIS, 0.15, [
		{"type": "InputEventKey", "physical_keycode": 87}
	])
	InputManager.register_custom_action("move_backward", InputManager.ACTION_TYPE_AXIS, 0.15, [
		{"type": "InputEventKey", "physical_keycode": 83}
	])
	InputManager.register_custom_action("sprint", InputManager.ACTION_TYPE_BUTTON, 0.5, [
		{"type": "InputEventKey", "physical_keycode": 340}
	])
	InputManager.register_custom_action("crouch", InputManager.ACTION_TYPE_BUTTON, 0.5, [
		{"type": "InputEventKey", "physical_keycode": 341}
	])
	InputManager.register_custom_action("interact", InputManager.ACTION_TYPE_BUTTON, 0.5, [
		{"type": "InputEventKey", "physical_keycode": 69},
		{"type": "InputEventKey", "physical_keycode": 32},
		{"type": "InputEventJoypadButton", "button_index": 0}
	])

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_stance(delta)
	_update_camera(delta)
	_check_interaction(delta)
	move_and_slide()

func _handle_movement(delta: float) -> void:
	# Combine keyboard/joypad input with touch input
	var kb_input = InputManager.get_movement_vector()
	var touch_input = InputManager.get_touch_move_vector()
	
	# Touch input takes priority when active (non-zero)
	var input_dir = touch_input if touch_input.length() > 0 else kb_input
	
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	var current_speed = walk_speed
	# Sprint: keyboard/joypad OR touch
	var is_sprint = InputManager.is_sprinting() or InputManager.is_touch_sprinting()
	# Crouch: keyboard/joypad OR touch
	var is_crouch = InputManager.is_crouching() or InputManager.is_touch_crouching()
	
	if is_sprint and not is_crouch:
		current_speed = sprint_speed
	elif is_crouch:
		current_speed = crouch_speed
	
	var target_speed = input_dir * current_speed
	
	if is_on_floor():
		_target_velocity.x = lerp(_target_velocity.x, target_speed.x, acceleration * delta)
		_target_velocity.z = lerp(_target_velocity.z, target_speed.z, acceleration * delta)
	else:
		_target_velocity.x = lerp(_target_velocity.x, target_speed.x, air_acceleration * delta)
		_target_velocity.z = lerp(_target_velocity.z, target_speed.z, air_acceleration * delta)
	
	if not is_on_floor():
		_target_velocity.y -= gravity * delta
	
	velocity = _target_velocity

func _handle_stance(delta: float) -> void:
	_is_sprinting = InputManager.is_sprinting() or InputManager.is_touch_sprinting()
	
	var was_crouching = _is_crouching
	# Check keyboard/joypad crouch press
	if InputManager.is_action_just_pressed("crouch"):
		_is_crouching = not _is_crouching
	# Touch crouch is toggle-based, sync with touch button state
	var touch_crouch = InputManager.is_touch_crouching()
	if touch_crouch != _is_crouching:
		_is_crouching = touch_crouch
	
	var target_height = crouch_height if _is_crouching else standing_height
	
	if _capsule_shape:
		var height_diff = _capsule_shape.height - target_height
		_capsule_shape.height = target_height
		
		if _is_crouching and not was_crouching:
			position.y -= height_diff * 0.5
		elif not _is_crouching and was_crouching:
			position.y += height_diff * 0.5
	
	var scale_target = target_height / _mesh_height
	var mesh_scale = _mesh.scale
	mesh_scale.y = lerp(mesh_scale.y, scale_target, stance_change_speed * delta)
	_mesh.scale = mesh_scale

func _update_camera(delta: float) -> void:
	_target_camera_pos = global_position + Vector3(0, camera_height, 0)
	_camera_pivot.global_position = _camera_pivot.global_position.lerp(_target_camera_pos, camera_smooth_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_tree().paused = not get_tree().paused

func _check_interaction(delta: float) -> void:
	_interaction_timer += delta
	if _interaction_timer < interaction_check_interval:
		return
	_interaction_timer = 0.0
	
	if _in_puzzle:
		return
	
	# Raycast forward to find interactables
	var camera = _camera
	if not camera:
		return
	
	var from = camera.global_position
	var to = from + -camera.global_transform.basis.z * interaction_range
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [get_instance_id()]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.get_collider()
		if collider and collider.is_in_group("hackable"):
			_current_interactable = collider
			if collider.has_method("get_player_in_range") and not collider.get_player_in_range():
				collider.call("try_start_hack")  # This will trigger the prompt
			_try_interact(collider)
			return
	
	_current_interactable = null

func _try_interact(interactable: Node3D) -> void:
	if InputManager.is_interacting():
		if interactable.has_method("try_start_hack"):
			var success = interactable.try_start_hack()
			if success:
				_enter_puzzle(interactable)

func _enter_puzzle(terminal: Node3D) -> void:
	if _in_puzzle:
		return
	
	_in_puzzle = true
	
	if _hacking_puzzle and _hacking_puzzle.has_method("start_puzzle"):
		_hacking_puzzle.start_puzzle(terminal)
		_hacking_puzzle.puzzle_completed.connect(_on_puzzle_completed)
	
	# Disable player movement during puzzle
	set_process(false)
	set_physics_process(false)
	set_process_input(false)

func _on_puzzle_completed(success: bool) -> void:
	_in_puzzle = false
	
	# Re-enable player
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	
	if _hacking_puzzle:
		_hacking_puzzle.puzzle_completed.disconnect(_on_puzzle_completed)
	
	if success:
		print("Hack successful!")
	else:
		print("Hack failed!")