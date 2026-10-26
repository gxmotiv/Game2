extends Node

class_name StealthSystemClass

signal visibility_calculated(player_id: int, guard_id: int, visibility: float)
signal suspicion_changed(guard_id: int, suspicion: float)
signal detection_state_changed(guard_id: int, detected: bool)
signal sound_event(position: Vector3, loudness: float, source_id: int)

@export_group("Vision Settings")
@export var default_cone_angle: float = 90.0
@export var default_cone_range: float = 15.0
@export var peripheral_vision_factor: float = 0.3
@export var vision_height_offset: float = 1.6

@export_group("Hearing Settings")
@export var default_hearing_range: float = 10.0
@export var sound_propagation_speed: float = 340.0
@export var wall_sound_dampening: float = 0.5

@export_group("Suspicion Settings")
@export var base_suspicion_rise_rate: float = 15.0
@export var base_suspicion_decay_rate: float = 5.0
@export var detection_threshold: float = 75.0
@export var suspicion_decay_delay: float = 1.0

@export_group("Stance Modifiers")
@export var standing_visibility_multiplier: float = 1.0
@export var crouching_visibility_multiplier: float = 0.5
@export var prone_visibility_multiplier: float = 0.2
@export var standing_sound_multiplier: float = 1.0
@export var crouching_sound_multiplier: float = 0.4
@export var prone_sound_multiplier: float = 0.1

@export_group("Lighting Settings")
@export var light_visibility_multiplier: float = 1.5
@export var shadow_visibility_multiplier: float = 0.5
@export var darkness_visibility_multiplier: float = 0.3

var _guard_data: Dictionary = {}
var _player_data: Dictionary = {}
var _sound_events: Array = []

func register_guard(guard_id: int, guard_node: Node3D, cone_angle: float = -1.0, cone_range: float = -1.0, hearing_range: float = -1.0) -> void:
	_guard_data[guard_id] = {
		"node": guard_node,
		"cone_angle": cone_angle if cone_angle > 0 else default_cone_angle,
		"cone_range": cone_range if cone_range > 0 else default_cone_range,
		"hearing_range": hearing_range if hearing_range > 0 else default_hearing_range,
		"suspicion": 0.0,
		"state": 0,
		"last_known_player_pos": Vector3.ZERO,
		"last_sight_time": 0.0,
		"investigation_target": Vector3.ZERO,
		"decay_timer": 0.0
	}

func unregister_guard(guard_id: int) -> void:
	_guard_data.erase(guard_id)

func register_player(player_id: int, player_node: Node3D) -> void:
	_player_data[player_id] = {
		"node": player_node,
		"stance": 0,
		"light_level": 1.0,
		"move_speed": 0.0,
		"last_position": Vector3.ZERO
	}

func unregister_player(player_id: int) -> void:
	_player_data.erase(player_id)

func update_player_stance(player_id: int, stance: int) -> void:
	if _player_data.has(player_id):
		_player_data[player_id]["stance"] = stance

func update_player_light_level(player_id: int, light_level: float) -> void:
	if _player_data.has(player_id):
		_player_data[player_id]["light_level"] = clamp(light_level, 0.0, 1.0)

func update_player_speed(player_id: int, speed: float) -> void:
	if _player_data.has(player_id):
		_player_data[player_id]["move_speed"] = speed

func update_guard_state(guard_id: int, state: int) -> void:
	if _guard_data.has(guard_id):
		_guard_data[guard_id]["state"] = state

func _physics_process(delta: float) -> void:
	_process_sound_events(delta)
	_update_suspicion(delta)
	_calculate_all_visibility()

func _process_sound_events(delta: float) -> void:
	var events_to_remove = []
	for i in range(_sound_events.size()):
		var event = _sound_events[i]
		event.time_elapsed += delta
		event.current_range += sound_propagation_speed * delta
		
		if event.current_range >= event.max_range:
			events_to_remove.append(i)
	
	for j in range(events_to_remove.size() - 1, -1, -1):
		_sound_events.remove_at(events_to_remove[j])

func emit_sound(position: Vector3, loudness: float, source_id: int, max_range: float = -1.0) -> void:
	var range = max_range if max_range > 0 else default_hearing_range
	_sound_events.append({
		"position": position,
		"loudness": loudness,
		"source_id": source_id,
		"max_range": range,
		"current_range": 0.0,
		"time_elapsed": 0.0
	})
	sound_event.emit(position, loudness, source_id)

func calculate_visibility(player_pos: Vector3, guard_pos: Vector3, guard_dir: Vector3, cone_angle: float = -1.0, cone_range: float = -1.0) -> float:
	var angle = cone_angle if cone_angle > 0 else default_cone_angle
	var range = cone_range if cone_range > 0 else default_cone_range
	
	var to_player = (player_pos - guard_pos).normalized()
	var distance = (player_pos - guard_pos).length()
	
	if distance > range:
		return 0.0
	
	var forward = guard_dir.normalized()
	forward.y = 0
	forward = forward.normalized()
	
	var dot = forward.dot(to_player)
	var half_angle_rad = deg_to_rad(angle * 0.5)
	var cos_half_angle = cos(half_angle_rad)
	
	if dot < cos_half_angle:
		var peripheral_angle = angle * peripheral_vision_factor
		var peripheral_half_rad = deg_to_rad(peripheral_angle * 0.5)
		var cos_peripheral = cos(peripheral_half_rad)
		
		if dot < cos_peripheral:
			return 0.0
		
		var peripheral_factor = (dot - cos_peripheral) / (cos_half_angle - cos_peripheral)
		return peripheral_factor * peripheral_vision_factor * (1.0 - distance / range)
	
	var center_factor = (dot - cos_half_angle) / (1.0 - cos_half_angle)
	var distance_factor = 1.0 - distance / range
	return center_factor * distance_factor

func calculate_visibility_with_obstruction(player_pos: Vector3, guard_pos: Vector3, guard_dir: Vector3, cone_angle: float = -1.0, cone_range: float = -1.0, player_stance: int = 0, light_level: float = 1.0) -> float:
	var base_visibility = calculate_visibility(player_pos, guard_pos, guard_dir, cone_angle, cone_range)
	
	if base_visibility <= 0.0:
		return 0.0
	
	if not _has_line_of_sight(guard_pos, player_pos):
		return 0.0
	
	var stance_mult = _get_stance_visibility_multiplier(player_stance)
	var light_mult = _get_light_visibility_multiplier(light_level)
	
	return base_visibility * stance_mult * light_mult

func _has_line_of_sight(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		from + Vector3(0.0, vision_height_offset, 0.0),
		to + Vector3(0.0, vision_height_offset, 0.0)
	)
	query.collision_mask = 1

	# This script is an autoload and has no guaranteed World3D during _ready().
	# Get the direct space state from a live scene node instead of caching a
	# possibly-invalid physics-space RID at startup.
	var space_state: PhysicsDirectSpaceState3D = null
	for guard_id in _guard_data:
		var guard_node = _guard_data[guard_id].get("node") as Node3D
		if is_instance_valid(guard_node) and guard_node.is_inside_tree():
			space_state = guard_node.get_world_3d().direct_space_state
			break
	if space_state == null:
		return true

	return space_state.intersect_ray(query).is_empty()

func _get_stance_visibility_multiplier(stance: int) -> float:
	match stance:
		0: return standing_visibility_multiplier
		1: return crouching_visibility_multiplier
		2: return prone_visibility_multiplier
	return 1.0

func _get_light_visibility_multiplier(light_level: float) -> float:
	if light_level > 0.7:
		return light_visibility_multiplier
	elif light_level > 0.3:
		return 1.0
	else:
		return darkness_visibility_multiplier

func calculate_suspicion_delta(visibility: float, distance: float, sound_level: float, guard_id: int) -> float:
	if not _guard_data.has(guard_id):
		return 0.0
	
	var guard = _guard_data[guard_id]
	var rise_rate = base_suspicion_rise_rate
	var delta = 0.0
	
	if visibility > 0.0:
		var distance_factor = 1.0 - min(distance / guard.cone_range, 1.0)
		delta += visibility * rise_rate * distance_factor
		guard.last_sight_time = Time.get_ticks_msec() / 1000.0
		guard.last_known_player_pos = Vector3.ZERO
	
	if sound_level > 0.0:
		var sound_factor = sound_level / 100.0
		delta += sound_factor * rise_rate * 0.5
		guard.investigation_target = Vector3.ZERO
	
	guard.decay_timer = suspicion_decay_delay
	return delta

func _update_suspicion(delta: float) -> void:
	for guard_id in _guard_data:
		var guard = _guard_data[guard_id]
		
		if guard.decay_timer > 0.0:
			guard.decay_timer -= delta
			continue
		
		if guard.suspicion > 0.0:
			guard.suspicion = max(0.0, guard.suspicion - base_suspicion_decay_rate * delta)
			suspicion_changed.emit(guard_id, guard.suspicion)
		
		var detected = guard.suspicion >= detection_threshold
		if detected != (guard.state >= 3):
			detection_state_changed.emit(guard_id, detected)

func _calculate_all_visibility() -> void:
	for player_id in _player_data:
		var player = _player_data[player_id]
		var player_node = player.node
		if not player_node or not player_node.is_inside_tree():
			continue
		
		var player_pos = player_node.global_position
		var stance = player.stance
		var light_level = player.light_level
		
		for guard_id in _guard_data:
			var guard = _guard_data[guard_id]
			var guard_node = guard.node
			if not guard_node or not guard_node.is_inside_tree():
				continue
			
			var guard_pos = guard_node.global_position
			var guard_dir = -guard_node.global_transform.basis.get_column(2)
			
			var visibility = calculate_visibility_with_obstruction(
				player_pos, guard_pos, guard_dir,
				guard.cone_angle, guard.cone_range,
				stance, light_level
			)
			
			if visibility > 0.0:
				visibility_calculated.emit(player_id, guard_id, visibility)
				
				var distance = (player_pos - guard_pos).length()
				var suspicion_delta = calculate_suspicion_delta(visibility, distance, 0.0, guard_id)
				guard.suspicion = clamp(guard.suspicion + suspicion_delta, 0.0, 100.0)
				suspicion_changed.emit(guard_id, guard.suspicion)
	
	_process_hearing()

func _process_hearing() -> void:
	for event in _sound_events:
		for guard_id in _guard_data:
			var guard = _guard_data[guard_id]
			var guard_node = guard.node
			if not guard_node or not guard_node.is_inside_tree():
				continue
			
			var guard_pos = guard_node.global_position
			var distance = (event.position - guard_pos).length()
			
			if distance <= event.current_range and distance <= event.max_range:
				var intensity = event.loudness * (1.0 - distance / event.max_range)
				if intensity > 0.1:
					var suspicion_delta = calculate_suspicion_delta(0.0, distance, intensity, guard_id)
					guard.suspicion = clamp(guard.suspicion + suspicion_delta, 0.0, 100.0)
					suspicion_changed.emit(guard_id, guard.suspicion)
					
					if guard.state < 2:
						guard.investigation_target = event.position

func set_guard_suspicion(guard_id: int, suspicion: float) -> void:
	if not _guard_data.has(guard_id):
		return
	var safe_value := clamp(suspicion, 0.0, 100.0)
	_guard_data[guard_id]["suspicion"] = safe_value
	_guard_data[guard_id]["decay_timer"] = suspicion_decay_delay
	suspicion_changed.emit(guard_id, safe_value)

func get_guard_suspicion(guard_id: int) -> float:
	if _guard_data.has(guard_id):
		return _guard_data[guard_id].suspicion
	return 0.0

func get_guard_state(guard_id: int) -> int:
	if _guard_data.has(guard_id):
		return _guard_data[guard_id].state
	return 0

func get_guard_last_known_position(guard_id: int) -> Vector3:
	if _guard_data.has(guard_id):
		return _guard_data[guard_id].last_known_player_pos
	return Vector3.ZERO

func get_guard_investigation_target(guard_id: int) -> Vector3:
	if _guard_data.has(guard_id):
		return _guard_data[guard_id].investigation_target
	return Vector3.ZERO

func set_guard_cone_angle(guard_id: int, angle: float) -> void:
	if _guard_data.has(guard_id):
		_guard_data[guard_id].cone_angle = angle

func set_guard_cone_range(guard_id: int, range: float) -> void:
	if _guard_data.has(guard_id):
		_guard_data[guard_id].cone_range = range

func set_guard_hearing_range(guard_id: int, range: float) -> void:
	if _guard_data.has(guard_id):
		_guard_data[guard_id].hearing_range = range

func reset_guard_suspicion(guard_id: int) -> void:
	if _guard_data.has(guard_id):
		_guard_data[guard_id].suspicion = 0.0
		suspicion_changed.emit(guard_id, 0.0)

func get_all_guards() -> Array[int]:
	return _guard_data.keys()

func get_all_players() -> Array[int]:
	return _player_data.keys()

func is_player_detected_by_any_guard(player_id: int) -> bool:
	if not _player_data.has(player_id):
		return false
	
	for guard_id in _guard_data:
		var guard = _guard_data[guard_id]
		if guard.suspicion >= detection_threshold:
			return true
	return false

func get_highest_suspicion() -> float:
	var max_suspicion = 0.0
	for guard_id in _guard_data:
		max_suspicion = max(max_suspicion, _guard_data[guard_id].suspicion)
	return max_suspicion