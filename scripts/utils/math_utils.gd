class_name MathUtils

static func lerp_angle(from: float, to: float, weight: float) -> float:
	var diff = wrapf(to - from, -PI, PI)
	return from + diff * weight

static func angle_to_vector(angle: float) -> Vector2:
	return Vector2(cos(angle), sin(angle))

static func vector_to_angle(vector: Vector2) -> float:
	return atan2(vector.y, vector.x)

static func clamp_angle(angle: float) -> float:
	return wrapf(angle, -PI, PI)

static func angle_diff(from: float, to: float) -> float:
	return wrapf(to - from, -PI, PI)

static func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func smootherstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

static func approach(value: float, target: float, max_change: float) -> float:
	if value < target:
		return min(value + max_change, target)
	elif value > target:
		return max(value - max_change, target)
	return value

static func vector2_approach(current: Vector2, target: Vector2, max_change: float) -> Vector2:
	var diff = target - current
	var dist = diff.length()
	if dist <= max_change or dist == 0.0:
		return target
	return current + diff.normalized() * max_change