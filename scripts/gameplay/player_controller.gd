extends CharacterBody3D
class_name Player

@export_group("Movement")
@export var walk_speed: float = 3.2
@export var sprint_speed: float = 5.5
@export var crouch_speed: float = 1.6
@export var acceleration: float = 18.0
@export var air_acceleration: float = 5.0
@export var gravity: float = 9.8

@export_group("Camera")
@export var camera_distance: float = 7.0
@export var camera_shoulder_offset: float = 1.0
@export var camera_height: float = 3.4
@export var camera_angle: float = 15.0
@export var camera_smooth_speed: float = 12.0
@export var look_sensitivity: float = 0.004

@export_group("Stance")
@export var crouch_height: float = 1.0
@export var standing_height: float = 1.8
@export var stance_change_speed: float = 10.0

@export_group("Interaction")
@export var interaction_range: float = 3.0
@export var interaction_check_interval: float = 0.08

signal died()
signal interaction_available(interactable: Node3D)
signal interaction_unavailable()

var camera_pivot: Node3D
var camera: Camera3D
var collision_shape: CollisionShape3D
var mesh: MeshInstance3D

var _target_velocity: Vector3 = Vector3.ZERO
var _is_crouching: bool = false
var _last_touch_crouch: bool = false
var _interaction_timer: float = 0.0
var _current_interactable: Node3D = null
var _in_puzzle: bool = false
var _hacking_puzzle: Node
var _capsule_shape: CapsuleShape3D
var _mesh_height: float = 1.8
var _look_touch_id: int = -1

func _ready() -> void:
	add_to_group("player")
	camera_pivot = $CameraPivot
	camera = $CameraPivot/Camera3D
	collision_shape = $CollisionShape3D
	mesh = $MeshInstance3D
	_capsule_shape = collision_shape.shape as CapsuleShape3D
	_mesh_height = 1.8

	_setup_camera()

	# The puzzle is already instanced by the main scene; only create a fallback
	# if this player is used in another test scene.
	_hacking_puzzle = get_tree().root.find_child("HackingPuzzle", true, false)
	if not _hacking_puzzle:
		_hacking_puzzle = preload("res://scenes/ui/hacking_puzzle.tscn").instantiate()
		get_tree().root.add_child(_hacking_puzzle)

func _setup_camera() -> void:
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 70.0
	camera.near = 0.1
	camera.far = 100.0
	camera_pivot.rotation = Vector3(-deg_to_rad(camera_angle), 0.0, 0.0)
	camera_pivot.position = Vector3(0.0, camera_height, camera_distance)
	camera.make_current()

func _physics_process(delta: float) -> void:
	if _in_puzzle:
		return

	_handle_movement(delta)
	_handle_stance(delta)
	_update_camera(delta)
	_check_interaction(delta)
	move_and_slide()

func _handle_movement(delta: float) -> void:
	var keyboard_input: Vector2 = InputManager.get_movement_vector()
	var touch_input: Vector2 = InputManager.get_touch_move_vector()
	var final_input: Vector2 = touch_input if touch_input.length() > 0.05 else keyboard_input

	if final_input.length() > 1.0:
		final_input = final_input.normalized()

	var is_sprinting: bool = InputManager.is_sprinting() or InputManager.is_touch_sprinting()
	var is_crouching: bool = _is_crouching or InputManager.is_crouching()
	var current_speed: float = walk_speed
	if is_sprinting and not is_crouching:
		current_speed = sprint_speed
	elif is_crouching:
		current_speed = crouch_speed

	# Movement follows the camera's yaw, so swiping to look also changes
	# the direction in which the left joystick moves the character.
	var local_direction := Vector3(final_input.x, 0.0, final_input.y)
	var world_direction := local_direction.rotated(Vector3.UP, camera_pivot.global_rotation.y)
	var target_velocity: Vector3 = world_direction * current_speed

	if is_on_floor():
		_target_velocity.x = move_toward(_target_velocity.x, target_velocity.x, acceleration * delta)
		_target_velocity.z = move_toward(_target_velocity.z, target_velocity.z, acceleration * delta)
		if _target_velocity.y < 0.0:
			_target_velocity.y = 0.0
	else:
		_target_velocity.x = move_toward(_target_velocity.x, target_velocity.x, air_acceleration * delta)
		_target_velocity.z = move_toward(_target_velocity.z, target_velocity.z, air_acceleration * delta)
		_target_velocity.y -= gravity * delta

	velocity = _target_velocity

func _handle_stance(delta: float) -> void:
	var touch_crouch: bool = InputManager.is_touch_crouching()
	if touch_crouch != _last_touch_crouch:
		_is_crouching = touch_crouch
		_last_touch_crouch = touch_crouch
	if InputManager.is_action_just_pressed("crouch"):
		_is_crouching = not _is_crouching

	var target_height: float = crouch_height if _is_crouching else standing_height
	if _capsule_shape:
		var height_diff: float = _capsule_shape.height - target_height
		_capsule_shape.height = target_height
		if _is_crouching and height_diff > 0.0:
			position.y -= height_diff * 0.5
		elif not _is_crouching and height_diff < 0.0:
			position.y -= height_diff * 0.5

	var scale_target: float = target_height / _mesh_height
	var mesh_scale: Vector3 = mesh.scale
	mesh_scale.y = lerp(mesh_scale.y, scale_target, stance_change_speed * delta)
	mesh.scale = mesh_scale
	mesh.position.y = target_height * 0.5

func _update_camera(delta: float) -> void:
	var yaw: float = camera_pivot.global_rotation.y
	var behind_player: Vector3 = Vector3(0.0, 0.0, camera_distance).rotated(Vector3.UP, yaw)
	var shoulder_offset: Vector3 = Vector3(camera_shoulder_offset, 0.0, 0.0).rotated(Vector3.UP, yaw)
	var target_position: Vector3 = global_position + Vector3(0.0, camera_height, 0.0) + behind_player + shoulder_offset
	camera_pivot.global_position = camera_pivot.global_position.lerp(target_position, min(camera_smooth_speed * delta, 1.0))

func _check_interaction(delta: float) -> void:
	# Keyboard interaction is checked every physics frame, not only on the
	# slower range-scan interval, so short key taps are not lost.
	if InputManager.is_interacting() and is_instance_valid(_current_interactable):
		_try_interact(_current_interactable, true)

	_interaction_timer += delta
	if _interaction_timer < interaction_check_interval or _in_puzzle:
		return
	_interaction_timer = 0.0

	# Find the nearest terminal in its trigger area. Mobile players should not
	# need pixel-perfect camera aiming to press INTERACT.
	var previous_interactable: Node3D = _current_interactable
	var nearest: Node3D = null
	var nearest_distance_sq: float = interaction_range * interaction_range
	var ray_origin: Vector3 = global_position + Vector3(0.0, 1.25, 0.0)

	for candidate in get_tree().get_nodes_in_group("hackable"):
		if not candidate is Node3D:
			continue
		var interactable: Node3D = candidate as Node3D
		if not interactable.has_method("get_player_in_range"):
			continue
		if not bool(interactable.call("get_player_in_range")):
			continue

		var distance_sq: float = global_position.distance_squared_to(interactable.global_position)
		if distance_sq > nearest_distance_sq:
			continue

		# Preserve stealth/geometry rules: don't allow hacking through a wall.
		var ray_target: Vector3 = interactable.global_position + Vector3(0.0, 0.6, 0.0)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		query.exclude = [get_rid()]
		query.collision_mask = 1
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.get("collider") != interactable:
			continue

		nearest = interactable
		nearest_distance_sq = distance_sq

	_current_interactable = nearest
	if _current_interactable != previous_interactable:
		if is_instance_valid(_current_interactable):
			interaction_available.emit(_current_interactable)
		else:
			interaction_unavailable.emit()

	var objective_label: Node = get_tree().root.find_child("ObjectiveLabel", true, false)
	if objective_label:
		if is_instance_valid(_current_interactable):
			objective_label.text = "TERMINAL IN RANGE  •  TAP INTERACT"
		else:
			objective_label.text = "OBJECTIVE: REACH THE TERMINAL  •  DRAG RIGHT SIDE TO LOOK"

func _try_interact_from_hud() -> void:
	# Called directly by the on-screen Android INTERACT button.
	if _current_interactable and is_instance_valid(_current_interactable):
		_try_interact(_current_interactable, true)

func _try_interact(interactable: Node3D, from_hud: bool = false) -> void:
	if not from_hud and not InputManager.is_interacting():
		return
	if not interactable or not is_instance_valid(interactable):
		return
	if interactable.has_method("try_start_hack") and interactable.call("try_start_hack"):
		_enter_puzzle(interactable)

func _enter_puzzle(terminal: Node3D) -> void:
	if _in_puzzle:
		return
	_in_puzzle = true

	if _hacking_puzzle and _hacking_puzzle.has_method("start_puzzle"):
		var completed_callback := Callable(self, "_on_puzzle_completed")
		if not _hacking_puzzle.is_connected("puzzle_completed", completed_callback):
			_hacking_puzzle.connect("puzzle_completed", completed_callback)
		_hacking_puzzle.call("start_puzzle", terminal)

func _on_puzzle_completed(success: bool) -> void:
	_in_puzzle = false
	if _hacking_puzzle:
		var completed_callback := Callable(self, "_on_puzzle_completed")
		if _hacking_puzzle.is_connected("puzzle_completed", completed_callback):
			_hacking_puzzle.disconnect("puzzle_completed", completed_callback)

	if _current_interactable and is_instance_valid(_current_interactable) and _current_interactable.has_method("end_hack"):
		_current_interactable.call("end_hack", success)

	var objective_label := get_tree().root.find_child("ObjectiveLabel", true, false)
	if objective_label:
		if success:
			objective_label.text = "MISSION COMPLETE  •  SYSTEM BREACHED"
		else:
			objective_label.text = "HACK FAILED  •  MOVE CLOSER AND TRY AGAIN"

func _unhandled_input(event: InputEvent) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			# Keep the lower action-button strip free for its own controls.
			if event.position.x > viewport_size.x * 0.42 and event.position.y > 70.0 and event.position.y < viewport_size.y - 150.0:
				_look_touch_id = event.index
		elif event.index == _look_touch_id:
			_look_touch_id = -1
	elif event is InputEventScreenDrag and event.index == _look_touch_id:
		camera_pivot.rotation.y -= event.relative.x * look_sensitivity
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x - event.relative.y * look_sensitivity * 0.65,
			deg_to_rad(-45.0),
			deg_to_rad(-12.0)
		)
