class_name PerformanceMonitor
extends Object

static var frame_times: Array = []
static var max_samples: int = 120

static func record_frame_time(frame_time: float) -> void:
	frame_times.append(frame_time)
	if frame_times.size() > max_samples:
		frame_times.pop_front()

static func get_average_frame_time() -> float:
	if frame_times.is_empty():
		return 0.0
	var sum = 0.0
	for t in frame_times:
		sum += t
	return sum / frame_times.size()

static func get_fps() -> float:
	var avg = get_average_frame_time()
	if avg <= 0.0:
		return 0.0
	return 1.0 / avg

static func get_min_max_frame_time() -> Dictionary:
	if frame_times.is_empty():
		return {"min": 0.0, "max": 0.0}
	var min_t = frame_times[0]
	var max_t = frame_times[0]
	for t in frame_times:
		if t < min_t:
			min_t = t
		if t > max_t:
			max_t = t
	return {"min": min_t, "max": max_t}

static func get_memory_usage() -> Dictionary:
	return {
		"static": OS.get_static_memory_usage(),
		"dynamic": OS.get_dynamic_memory_usage(),
		"static_peak": OS.get_static_memory_peak_usage(),
		"dynamic_peak": OS.get_dynamic_memory_peak_usage()
	}

static func print_performance_report() -> void:
	var avg = get_average_frame_time()
	var fps = get_fps()
	var mm = get_min_max_frame_time()
	var mem = get_memory_usage()
	print("=== Performance Report ===")
	print("Avg Frame Time: %.4f ms (%.1f FPS)" % [avg * 1000, fps])
	print("Min Frame Time: %.4f ms" % [mm.min * 1000])
	print("Max Frame Time: %.4f ms" % [mm.max * 1000])
	print("Static Memory: %.2f MB" % [mem.static / 1024.0 / 1024.0])
	print("Dynamic Memory: %.2f MB" % [mem.dynamic / 1024.0 / 1024.0])
	print("==========================")

static func reset() -> void:
	frame_times.clear()