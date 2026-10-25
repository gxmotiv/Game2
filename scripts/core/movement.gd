class_name MovementUtils

static func calculate_move_velocity(input_dir: Vector2, current_velocity: Vector3, target_speed: float, acceleration: float, delta: float, is_on_floor: bool, air_acceleration: float, gravity: float) -> Vector3:
	var target_velocity = Vector3(input_dir.x, 0, input_dir.y) * target_speed
	var new_velocity = current_velocity
	
	if is_on_floor:
		new_velocity.x = lerp(current_velocity.x, target_velocity.x, acceleration * delta)
		new_velocity.z = lerp(current_velocity.z, target_velocity.z, acceleration * delta)
	else:
		new_velocity.x = lerp(current_velocity.x, target_velocity.x, air_acceleration * delta)
		new_velocity.z = lerp(current_velocity.z, target_velocity.z, air_acceleration * delta)
	
	if not is_on_floor:
		new_velocity.y -= gravity * delta
	
	return new_velocity

static func apply_gravity(velocity: Vector3, gravity: float, delta: float) -> Vector3:
	var new_vel = velocity
	new_vel.y -= gravity * delta
	return new_vel

static func move_toward(current: float, target: float, max_change: float) -> float:
	if current < target:
		return min(current + max_change, target)
	elif current > target:
		return max(current - max_change, target)
	return current

static func rotate_toward(current_angle: float, target_angle: float, turn_speed: float, delta: float) -> float:
	var diff = wrapf(target_angle - current_angle, -PI, PI)
	return current_angle + diff * min(turn_speed * delta, 1.0)

static func get_direction_from_input(input_vector: Vector2) -> Vector3:
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
	return Vector3(input_vector.x, 0, input_vector.y)