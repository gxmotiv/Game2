extends CharacterBody3D
class_name Guard
## Lightweight patrol and vision AI for the compact Android city district.

signal state_changed(new_state: int)
signal suspicion_changed(value: float)
signal detected_player(player_position: Vector3)

@export_group("Patrol")
@export var patrol_points: Array[Vector3] = [
	Vector3(-8.0, 1.0, -8.0),
	Vector3(-8.0, 1.0, 8.0),
	Vector3(8.0, 1.0, 8.0),
	Vector3(8.0, 1.0, -8.0)
]
@export var patrol_speed: float = 2.0
@export var patrol_wait_time: float = 1.0

@export_group("Movement")
@export var max_speed: float = 4.5
@export var acceleration: float = 12.0
@export var gravity: float = 9.8
@export var turn_speed: float = 7.0

@export_group("Vision")
@export_range(30.0, 150.0, 1.0) var cone_angle: float = 90.0
@export var cone_range: float = 15.0
@export var detection_update_interval: float = 0.12

@export_group("Suspicion")
@export var suspicion_rise_rate: float = 24.0
@export var suspicion_decay_rate: float = 14.0
@export var detection_threshold: float = 100.0
@export var suspicious_threshold: float = 1.0

@export_group("Investigation")
@export var search_time: float = 5.0

@onready var vision_ray: RayCast3D = get_node_or_null("VisionRay") as RayCast3D
@onready var vision_cone_mesh: MeshInstance3D = get_node_or_null("VisionCone") as MeshInstance3D
@onready var state_indicator: MeshInstance3D = get_node_or_null("StateIndicator") as MeshInstance3D
@onready var awareness_label: Label3D = get_node_or_null("AwarenessLabel") as Label3D

enum State {
	PATROL = 0,
	SUSPICIOUS = 1,
	INVESTIGATING = 2,
	ALERT = 3,
	SEARCHING = 4,
	RETURNING = 5
}

var _state: int = State.PATROL
var _suspicion: float = 0.0
var _patrol_world_points: Array[Vector3] = []
var _current_patrol_index: int = 0
var _patrol_timer: float = 0.0
var _target_position: Vector3 = Vector3.ZERO
var _last_known_player_pos: Vector3 = Vector3.ZERO
var _search_timer: float = 0.0
var _detection_timer: float = 0.0
var _player_visible: bool = false
var _player_node: Node3D
var _stealth_system: Node
var _guard_id: int
var _alert_reported: bool = false

func _ready() -> void:
	add_to_group("guards")
	_stealth_system = get_node_or_null("/root/StealthSystem")
	if vision_cone_mesh:
		vision_cone_mesh.visible = false
	if state_indicator:
		state_indicator.visible = false
	if vision_ray:
		vision_ray.enabled = true
		vision_ray.collision_mask = 1
		vision_ray.exclude_parent = true
		vision_ray.position = Vector3(0.0, 1.35, 0.0)
	else:
		push_error("Guard is missing its VisionRay RayCast3D node.")

	_rebuild_patrol_route()
	_find_player()
	_guard_id = hash(str(get_instance_id()))
	if _stealth_system:
		_stealth_system.call("register_guard", _guard_id, self, cone_angle, cone_range)
	if not _patrol_world_points.is_empty():
		_target_position = _patrol_world_points[0]
	_update_awareness_indicator()

func _exit_tree() -> void:
	if _stealth_system and _stealth_system.has_method("unregister_guard"):
		_stealth_system.call("unregister_guard", _guard_id)

func _rebuild_patrol_route() -> void:
	_patrol_world_points.clear()
	var parent_3d := get_parent() as Node3D
	for point in patrol_points:
		_patrol_world_points.append(parent_3d.to_global(point) if parent_3d else point)
	_current_patrol_index = 0

func set_patrol_points(points: Array[Vector3]) -> void:
	patrol_points = points.duplicate()
	if is_inside_tree():
		_rebuild_patrol_route()
		if not _patrol_world_points.is_empty():
			_target_position = _patrol_world_points[0]

func get_patrol_points() -> Array[Vector3]:
	return patrol_points.duplicate()

func get_state() -> int:
	return _state

func get_suspicion() -> float:
	return _suspicion

func get_guard_id() -> int:
	return _guard_id

func get_detection_range_for_player(target: Node3D) -> float:
	if is_instance_valid(target) and bool(target.get("_is_crouching")):
		return cone_range * 0.5
	return cone_range

func can_see_player_now() -> bool:
	_find_player()
	return _can_see_player()

func _find_player() -> void:
	var candidate := get_tree().get_first_node_in_group("player") as Node3D
	if candidate == null:
		candidate = get_tree().root.find_child("Player", true, false) as Node3D
	if candidate == _player_node:
		return
	if vision_ray and is_instance_valid(_player_node) and _player_node is CollisionObject3D:
		vision_ray.remove_exception(_player_node as CollisionObject3D)
	_player_node = candidate
	if vision_ray and is_instance_valid(_player_node) and _player_node is CollisionObject3D:
		vision_ray.add_exception(_player_node as CollisionObject3D)

func _physics_process(delta: float) -> void:
	_detection_timer += delta
	if _detection_timer >= detection_update_interval:
		var scan_delta: float = _detection_timer
		_detection_timer = 0.0
		_check_player_visibility(scan_delta)

	_handle_state_machine(delta)
	_handle_movement(delta)
	move_and_slide()

func _can_see_player() -> bool:
	if not is_instance_valid(_player_node) or not _player_node.is_inside_tree() or vision_ray == null:
		return false

	var target_position := _player_node.global_position
	var effective_range := get_detection_range_for_player(_player_node)
	var horizontal_offset := Vector3(
		target_position.x - global_position.x,
		0.0,
		target_position.z - global_position.z
	)
	var distance := horizontal_offset.length()
	if distance <= 0.001 or distance > effective_range:
		return false

	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		return false
	forward = forward.normalized()
	var direction := horizontal_offset / distance
	if forward.dot(direction) < cos(deg_to_rad(cone_angle * 0.5)):
		return false

	var target_height := 0.65 if bool(_player_node.get("_is_crouching")) else 1.1
	var target_point := target_position + Vector3(0.0, target_height, 0.0)
	vision_ray.target_position = vision_ray.to_local(target_point)
	vision_ray.force_raycast_update()
	return not vision_ray.is_colliding()

func _check_player_visibility(elapsed: float) -> void:
	_find_player()
	_player_visible = _can_see_player()
	var previous_suspicion := _suspicion
	if _player_visible:
		_last_known_player_pos = _player_node.global_position
		_suspicion = minf(100.0, _suspicion + suspicion_rise_rate * elapsed)
	else:
		_suspicion = maxf(0.0, _suspicion - suspicion_decay_rate * elapsed)

	if not is_equal_approx(previous_suspicion, _suspicion):
		suspicion_changed.emit(_suspicion)
		_update_awareness_indicator()
	if _stealth_system:
		_stealth_system.call("set_guard_suspicion", _guard_id, _suspicion)

	if _suspicion >= detection_threshold:
		if not _alert_reported:
			_alert_reported = true
			_change_state(State.ALERT)
			detected_player.emit(_last_known_player_pos)
	elif _player_visible and _state == State.PATROL and _suspicion >= suspicious_threshold:
		_change_state(State.SUSPICIOUS)
	elif _suspicion <= 0.0 and _state == State.SUSPICIOUS:
		_change_state(State.PATROL)
		_alert_reported = false

func _handle_state_machine(delta: float) -> void:
	match _state:
		State.PATROL:
			_update_patrol_target(delta)
		State.SUSPICIOUS:
			_target_position = _last_known_player_pos
			if _suspicion <= 0.0:
				_change_state(State.PATROL)
		State.ALERT:
			if _player_visible:
				_target_position = _last_known_player_pos
			else:
				_change_state(State.SEARCHING)
		State.SEARCHING:
			_search_timer -= delta
			if _player_visible:
				_change_state(State.ALERT)
			elif _search_timer <= 0.0:
				_change_state(State.RETURNING)
		State.RETURNING:
			if _player_visible:
				_change_state(State.ALERT)
			elif not _patrol_world_points.is_empty() and _horizontal_distance(global_position, _target_position) < 0.8:
				_change_state(State.PATROL)

func _update_patrol_target(delta: float) -> void:
	if _patrol_world_points.is_empty():
		return
	if _horizontal_distance(global_position, _target_position) <= 0.8:
		_patrol_timer += delta
		if _patrol_timer >= patrol_wait_time:
			_patrol_timer = 0.0
			_current_patrol_index = (_current_patrol_index + 1) % _patrol_world_points.size()
			_target_position = _patrol_world_points[_current_patrol_index]
	else:
		_patrol_timer = 0.0

func _handle_movement(delta: float) -> void:
	var horizontal_target := _target_position - global_position
	horizontal_target.y = 0.0
	if horizontal_target.length_squared() > 0.04:
		var direction := horizontal_target.normalized()
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, minf(turn_speed * delta, 1.0))
		var current_speed := patrol_speed
		match _state:
			State.SUSPICIOUS:
				current_speed *= 0.55
			State.INVESTIGATING, State.SEARCHING:
				current_speed *= 1.1
			State.ALERT:
				current_speed = max_speed
		var target_velocity := -global_transform.basis.z * current_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

func _change_state(new_state: int) -> void:
	if _state == new_state:
		return
	_state = new_state
	if vision_cone_mesh:
		vision_cone_mesh.visible = false
	_update_awareness_indicator()
	if _state == State.SEARCHING:
		_search_timer = search_time
	elif _state == State.RETURNING and not _patrol_world_points.is_empty():
		_target_position = _patrol_world_points[_current_patrol_index]
	elif _state == State.PATROL and _suspicion <= 0.0:
		_alert_reported = false
	if _stealth_system:
		_stealth_system.call("update_guard_state", _guard_id, _state)
	state_changed.emit(_state)

func _update_awareness_indicator() -> void:
	if awareness_label == null:
		return
	if _suspicion <= 0.0 and _state == State.PATROL:
		awareness_label.text = ""
		awareness_label.visible = false
		return

	var filled := clampi(int(ceil(_suspicion / 10.0)), 0, 10)
	var meter := ""
	for index in range(10):
		meter += "#" if index < filled else "-"
	awareness_label.visible = true
	if _suspicion >= 100.0:
		awareness_label.text = "!\n" + meter
		awareness_label.modulate = Color(1.0, 0.12, 0.08, 1.0)
	else:
		awareness_label.text = "?\n" + meter
		var heat := _suspicion / 100.0
		awareness_label.modulate = Color(1.0, lerpf(0.88, 0.24, heat), 0.08, 1.0)
