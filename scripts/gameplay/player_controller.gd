extends CharacterBody3D
class_name Player

@export_group("Movement")
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 6.0
@export var crouch_speed: float = 1.5
@export var acceleration: float = 20.0
@export var deceleration: float = 25.0
@export var air_acceleration: float = 5.0
@export var air_deceleration: float = 2.0
@export var gravity: float = 9.8

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

signal died()
signal interaction_available(interactable: Node3D)
signal interaction_unavailable()

var camera_pivot: Node3D
var camera: Camera3D
var collision_shape: CollisionShape3D
var mesh: MeshInstance3D

var _target_velocity: Vector3 = Vector3.ZERO
var _is_sprinting: bool = false
var _is_crouching: bool = false
var _keyboard_crouching: bool = false
var _target_camera_pos: Vector3 = Vector3.ZERO
var _current_interactable: Node3D = null
var _in_puzzle: bool = false
var _hacking_puzzle: CanvasLayer
var _capsule_shape: CapsuleShape3D
var _mesh_height: float = 1.8

func _ready() -> void:
	camera_pivot = $CameraPivot
	camera = $CameraPivot/Camera3D
	collision_shape = $CollisionShape3D
	mesh = $MeshInstance3D
	_capsule_shape = collision_shape.shape as CapsuleShape3D
	_mesh_height = 1.8
	
	_setup_camera()
	
	# Find hacking puzzle in scene tree
	_hacking_puzzle = get_tree().root.find_child("HackingPuzzle", true, false)
	if not _hacking_puzzle:
		_hacking_puzzle = preload("res://scenes/ui/hacking_puzzle.tscn").instantiate()
		get_tree().root.add_child(_hacking_puzzle)

func _setup_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.0
	camera.near = 0.1
	camera.far = 100.0
	
	var angle_rad = deg_to_rad(camera_angle)
	camera_pivot.rotation = Vector3(-angle_rad, 0, 0)
	camera_pivot.position = Vector3(0, camera_height, camera_distance)

func _physics_process(delta: float) -> void:
	if _in_puzzle:
		return

	# Read one-shot input every physics frame so touch taps cannot get stuck.
	var interaction_pressed: bool = InputManager.is_interacting()
	_handle_movement(delta)
	_handle_stance(delta)
	_update_camera(delta)
	_check_interaction(interaction_pressed)
	move_and_slide()
	# Keep our velocity in sync with slide/collision response.
	_target_velocity = velocity

func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = InputManager.get_movement_vector()
	var touch_input: Vector2 = InputManager.get_touch_move_vector()

	# Touch stick takes priority while it is being pushed.
	var final_input: Vector2 = touch_input if touch_input.length() > 0.05 else input_dir
	if final_input.length() > 1.0:
		final_input = final_input.normalized()

	var current_speed: float = walk_speed
	var is_sprint: bool = InputManager.is_sprinting() or InputManager.is_touch_sprinting()
	var is_crouch: bool = _is_crouching
	if is_sprint and not is_crouch:
		current_speed = sprint_speed
	elif is_crouch:
		current_speed = crouch_speed

	var target_speed: Vector2 = final_input * current_speed
	var blend: float = acceleration if is_on_floor() else air_acceleration
	_target_velocity.x = move_toward(_target_velocity.x, target_speed.x, blend * delta * max(current_speed, 1.0))
	_target_velocity.z = move_toward(_target_velocity.z, target_speed.y, blend * delta * max(current_speed, 1.0))

	if is_on_floor():
		if _target_velocity.y < 0.0:
			_target_velocity.y = 0.0
	else:
		_target_velocity.y -= gravity * delta

	velocity = _target_velocity

func _handle_stance(delta: float) -> void:
	_is_sprinting = InputManager.is_sprinting() or InputManager.is_touch_sprinting()

	# Keyboard crouch toggles; the mobile crouch button keeps its own toggle state.
	if InputManager.is_action_just_pressed("crouch"):
		_keyboard_crouching = not _keyboard_crouching
	_is_crouching = _keyboard_crouching or InputManager.is_touch_crouching()

	var target_height: float = crouch_height if _is_crouching else standing_height
	if _capsule_shape:
		var height_diff: float = _capsule_shape.height - target_height
		if not is_zero_approx(height_diff):
			_capsule_shape.height = target_height
			# Move the capsule centre by half the height change so its feet stay planted.
			position.y -= height_diff * 0.5

	var scale_target: float = target_height / _mesh_height
	var mesh_scale: Vector3 = mesh.scale
	mesh_scale.y = lerp(mesh_scale.y, scale_target, stance_change_speed * delta)
	mesh.scale = mesh_scale
	mesh.position.y = target_height * 0.5

func _update_camera(delta: float) -> void:
	_target_camera_pos = global_position + Vector3(0, camera_height, camera_distance)
	camera_pivot.global_position = camera_pivot.global_position.lerp(_target_camera_pos, camera_smooth_speed * delta)

func _check_interaction(interaction_pressed: bool) -> void:
	# Terminal InteractionArea nodes own range detection. Avoid a short camera ray
	# that starts above the player's head and misses the terminal entirely.
	var nearest: Node3D = null
	var nearest_distance_sq: float = interaction_range * interaction_range
	for candidate in get_tree().get_nodes_in_group("hackable"):
		if not is_instance_valid(candidate) or not (candidate is Node3D):
			continue
		var interactable: Node3D = candidate as Node3D
		if not interactable.has_method("get_player_in_range"):
			continue
		if not bool(interactable.call("get_player_in_range")):
			continue
		var distance_sq: float = global_position.distance_squared_to(interactable.global_position)
		if distance_sq <= nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = interactable

	if nearest != _current_interactable:
		_current_interactable = nearest
		if _current_interactable:
			interaction_available.emit(_current_interactable)
		else:
			interaction_unavailable.emit()

	if interaction_pressed and is_instance_valid(_current_interactable):
		_try_interact(_current_interactable)

func _try_interact(interactable: Node3D) -> void:
	if _in_puzzle or not is_instance_valid(interactable):
		return
	if interactable.has_method("try_start_hack") and bool(interactable.call("try_start_hack")):
		_enter_puzzle(interactable)

func _enter_puzzle(terminal: Node3D) -> void:
	if _in_puzzle:
		return
	_in_puzzle = true

	if _hacking_puzzle and _hacking_puzzle.has_method("start_puzzle"):
		if _hacking_puzzle.has_signal("puzzle_completed") and not _hacking_puzzle.is_connected("puzzle_completed", _on_puzzle_completed):
			_hacking_puzzle.connect("puzzle_completed", _on_puzzle_completed)
		_hacking_puzzle.call("start_puzzle", terminal)
	else:
		_in_puzzle = false
		push_warning("Hacking puzzle is unavailable; player controls were not locked.")

	# Disable player movement during puzzle.
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)

func _on_puzzle_completed(success: bool) -> void:
	_in_puzzle = false
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)

	if _hacking_puzzle and _hacking_puzzle.has_signal("puzzle_completed") and _hacking_puzzle.is_connected("puzzle_completed", _on_puzzle_completed):
		_hacking_puzzle.disconnect("puzzle_completed", _on_puzzle_completed)

	if success:
		print("Hack successful!")
	else:
		print("Hack failed!")