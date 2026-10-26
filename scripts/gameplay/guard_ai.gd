extends CharacterBody3D
class_name Guard

signal state_changed(new_state: int)
signal suspicion_changed(value: float)
signal detected_player(player_position: Vector3)

@export_group("Patrol")
@export var patrol_points: Array[Vector3] = []
@export var patrol_speed: float = 2.0
@export var patrol_wait_time: float = 1.5
@export var loop_patrol: bool = true

@export_group("Movement")
@export var max_speed: float = 5.0
@export var acceleration: float = 15.0
@export var deceleration: float = 20.0
@export var gravity: float = 9.8
@export var turn_speed: float = 8.0

@export_group("Vision")
@export var cone_angle: float = 90.0
@export var cone_range: float = 15.0
@export var detection_update_interval: float = 0.1

@export_group("Suspicion")
@export var suspicion_rise_rate: float = 20.0
@export var suspicion_decay_rate: float = 8.0
@export var detection_threshold: float = 75.0
@export var suspicious_threshold: float = 25.0

@export_group("Investigation")
@export var investigation_time: float = 5.0
@export var search_time: float = 8.0

@export_group("References")
@export var vision_cone_mesh: MeshInstance3D
@export var state_indicator: MeshInstance3D

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
var _current_patrol_index: int = 0
var _patrol_timer: float = 0.0
var _target_position: Vector3 = Vector3.ZERO
var _last_known_player_pos: Vector3 = Vector3.ZERO
var _investigation_timer: float = 0.0
var _search_timer: float = 0.0
var _detection_timer: float = 0.0
var _player_visible: bool = false
var _player_node: Node3D
var _stealth_system: Variant
var _guard_id: int

func _ready() -> void:
	_stealth_system = get_node_or_null("/root/StealthSystem")
	
	# Setup vision cone
	if vision_cone_mesh:
		_setup_vision_cone()
	
	# Setup state indicator
	if state_indicator:
		_update_state_indicator()
	
	# Find player
	_player_node = get_tree().get_first_node_in_group("player")
	if not _player_node:
		_player_node = get_tree().root.find_child("Player", true, false)
	
	# Register with StealthSystem
	_guard_id = _generate_guard_id()
	if _stealth_system:
		_stealth_system.call("register_guard", _guard_id, self, cone_angle, cone_range)
	
	# Set initial patrol target
	if patrol_points.size() > 0:
		_target_position = patrol_points[_current_patrol_index]
	
	_state = State.PATROL

func _generate_guard_id() -> int:
	return hash(str(self) + str(Time.get_ticks_msec()))

func _setup_vision_cone() -> void:
	if vision_cone_mesh and vision_cone_mesh.mesh:
		var cone = vision_cone_mesh.mesh
		if cone is PrimitiveMesh:
			cone.height = cone_range
			cone.bottom_radius = cone_range * tan(deg_to_rad(cone_angle * 0.5))
			cone.top_radius = 0.0
	# Do not wash the whole screen with the cone while the guard is calm.
	vision_cone_mesh.visible = false

func _physics_process(delta: float) -> void:
	_detection_timer += delta
	
	# Run detection at intervals for performance
	if _detection_timer >= detection_update_interval:
		_detection_timer = 0.0
		_check_player_visibility()
	
	_handle_state_machine(delta)
	_handle_movement(delta)
	move_and_slide()

func _check_player_visibility() -> void:
	if not _player_node or not _player_node.is_inside_tree():
		_player_visible = false
		return
	
	if not _stealth_system:
		_player_visible = false
		return
	
	var player_pos = _player_node.global_position
	var guard_pos = global_position
	var guard_dir = -global_transform.basis.z
	
	var visibility = _stealth_system.call("calculate_visibility_with_obstruction",
		player_pos, guard_pos, guard_dir,
		cone_angle, cone_range
	)
	
	_player_visible = visibility > 0.0
	
	if _player_visible:
		_last_known_player_pos = player_pos
		_suspicion = clamp(_suspicion + suspicion_rise_rate * detection_update_interval, 0.0, 100.0)
		if _stealth_system:
			_stealth_system.call("set_guard_suspicion", _guard_id, _suspicion)
		suspicion_changed.emit(_suspicion)
		detected_player.emit(player_pos)
	else:
		# Let StealthSystem handle decay
		if _stealth_system:
			var current = _stealth_system.call("get_guard_suspicion", _guard_id)
			_suspicion = current
			suspicion_changed.emit(_suspicion)

func _handle_state_machine(delta: float) -> void:
	var old_state = _state
	
	match _state:
		State.PATROL:
			_handle_patrol(delta)
		
		State.SUSPICIOUS:
			_handle_suspicious(delta)
		
		State.INVESTIGATING:
			_handle_investigating(delta)
		
		State.ALERT:
			_handle_alert(delta)
		
		State.SEARCHING:
			_handle_searching(delta)
		
		State.RETURNING:
			_handle_returning(delta)
	
	# State transitions
	if _state == State.PATROL and _suspicion >= suspicious_threshold:
		_change_state(State.SUSPICIOUS)
	elif _state == State.SUSPICIOUS and _suspicion >= detection_threshold:
		_change_state(State.ALERT)
	elif _state == State.SUSPICIOUS and _suspicion < suspicious_threshold * 0.5:
		_change_state(State.PATROL)
	elif _state == State.INVESTIGATING:
		if _player_visible:
			_change_state(State.ALERT)
		elif _investigation_timer <= 0.0:
			_change_state(State.SEARCHING)
	elif _state == State.ALERT:
		if not _player_visible:
			_change_state(State.SEARCHING)
	elif _state == State.SEARCHING:
		if _player_visible:
			_change_state(State.ALERT)
		elif _search_timer <= 0.0:
			_change_state(State.RETURNING)
	elif _state == State.RETURNING:
		if _player_visible:
			_change_state(State.ALERT)
		elif global_position.distance_to(_target_position) < 1.0:
			_change_state(State.PATROL)
	
	if _state != old_state:
		_on_state_changed(old_state, _state)

func _handle_patrol(delta: float) -> void:
	if patrol_points.size() == 0:
		return
	
	var distance = global_position.distance_to(_target_position)
	
	if distance < 1.0:
		_patrol_timer += delta
		if _patrol_timer >= patrol_wait_time:
			_patrol_timer = 0.0
			_current_patrol_index = (_current_patrol_index + 1) % patrol_points.size()
			_target_position = patrol_points[_current_patrol_index]
	else:
		_patrol_timer = 0.0

func _handle_suspicious(delta: float) -> void:
	# Slow down and look around
	if _target_position != Vector3.ZERO and _target_position != _last_known_player_pos:
		_target_position = _last_known_player_pos

func _handle_investigating(delta: float) -> void:
	_investigation_timer -= delta
	
	var distance = global_position.distance_to(_target_position)
	if distance < 1.5:
		_investigation_timer = investigation_time
		_target_position = _last_known_player_pos + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))

func _handle_alert(delta: float) -> void:
	# Chase player directly
	if _player_visible:
		_target_position = _last_known_player_pos
		_investigation_timer = investigation_time
		_search_timer = search_time

func _handle_searching(delta: float) -> void:
	_search_timer -= delta
	
	var distance = global_position.distance_to(_target_position)
	if distance < 1.5:
		_target_position = _last_known_player_pos + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))

func _handle_returning(delta: float) -> void:
	# Return to patrol route
	if patrol_points.size() > 0:
		_target_position = patrol_points[_current_patrol_index]

func _change_state(new_state: int) -> void:
	_state = new_state
	if vision_cone_mesh:
		vision_cone_mesh.visible = new_state in [State.SUSPICIOUS, State.INVESTIGATING, State.ALERT, State.SEARCHING]
	_update_state_indicator()
	state_changed.emit(_state)
	
	# Reset timers on state change
	match _state:
		State.INVESTIGATING:
			_investigation_timer = investigation_time
			_target_position = _last_known_player_pos
		State.SEARCHING:
			_search_timer = search_time
		State.RETURNING:
			if patrol_points.size() > 0:
				_target_position = patrol_points[_current_patrol_index]
	
	if _stealth_system:
		_stealth_system.call("update_guard_state", _guard_id, _state)

func _on_state_changed(old_state: int, new_state: int) -> void:
	pass # Debug

func _handle_movement(delta: float) -> void:
	if _target_position == Vector3.ZERO:
		velocity = Vector3(velocity.x, velocity.y - gravity * delta, velocity.z)
		return
	
	var to_target = (_target_position - global_position).normalized()
	to_target.y = 0
	
	# Determine speed based on state
	var current_speed = patrol_speed
	match _state:
		State.PATROL, State.RETURNING:
			current_speed = patrol_speed
		State.SUSPICIOUS:
			current_speed = patrol_speed * 0.7
		State.INVESTIGATING, State.SEARCHING:
			current_speed = patrol_speed * 1.2
		State.ALERT:
			current_speed = max_speed
	
	# Smooth rotation toward target
	var target_angle = atan2(to_target.x, to_target.z)
	var current_angle = rotation.y
	var angle_diff = wrapf(target_angle - current_angle, -PI, PI)
	rotation.y = current_angle + angle_diff * min(turn_speed * delta, 1.0)
	
	# Move forward
	var forward_dir = -global_transform.basis.z
	var target_velocity = forward_dir * current_speed
	
	if is_on_floor():
		velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)
	else:
		velocity.y -= gravity * delta

func _update_state_indicator() -> void:
	if not state_indicator:
		return
	
	match _state:
		State.PATROL:
			state_indicator.material_override = _create_material(Color(0.2, 1.0, 0.2, 1.0))  # Green
		State.SUSPICIOUS:
			state_indicator.material_override = _create_material(Color(1.0, 1.0, 0.0, 1.0))  # Yellow
		State.INVESTIGATING:
			state_indicator.material_override = _create_material(Color(1.0, 0.6, 0.0, 1.0))  # Orange
		State.ALERT:
			state_indicator.material_override = _create_material(Color(1.0, 0.0, 0.0, 1.0))  # Red
		State.SEARCHING:
			state_indicator.material_override = _create_material(Color(1.0, 0.0, 0.5, 1.0))  # Pink
		State.RETURNING:
			state_indicator.material_override = _create_material(Color(0.0, 0.5, 1.0, 1.0))  # Blue
	
	# Pulse effect for alert states
	if _state in [State.ALERT, State.SEARCHING]:
		var t = fmod(Time.get_ticks_msec() / 1000.0 * 8.0, 2.0)
		if t > 1.0:
			t = 2.0 - t
		state_indicator.scale = Vector3(1.0, 1.0 + t * 0.5, 1.0)
	else:
		state_indicator.scale = Vector3.ONE

func _create_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	mat.emission = color
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.render_priority = 1
	return mat

func get_state() -> int:
	return _state

func get_suspicion() -> float:
	return _suspicion

func get_patrol_points() -> Array[Vector3]:
	return patrol_points

func set_patrol_points(points: Array[Vector3]) -> void:
	patrol_points = points
	if patrol_points.size() > 0:
		_current_patrol_index = 0
		_target_position = patrol_points[0]