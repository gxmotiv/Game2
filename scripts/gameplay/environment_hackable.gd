extends StaticBody3D
class_name EnvironmentHackable
## Low-cost procedural city props controlled by the contextual HACK action.

enum ObjectType { TRAFFIC_LIGHT, STEAM_PIPE, ELECTRICAL_BOX }

@export var object_type: int = ObjectType.TRAFFIC_LIGHT
@export var display_name: String = "Traffic Light"
@export var interaction_range: float = 8.0
@export var effect_radius: float = 12.0
@export var cooldown_duration: float = 6.0

var _prompt: Label3D
var _cooldown := 0.0
var _steam_used := false
var _dark_active := false
var _saved_lights: Array[Dictionary] = []
var _traffic_lamps: Array[MeshInstance3D] = []
var _steam: CPUParticles3D
var _status_led: MeshInstance3D

func _ready() -> void:
	add_to_group("environment_hackables")
	if object_type == ObjectType.ELECTRICAL_BOX:
		add_to_group("dark_zones")
	_build_collision()
	_build_visuals()
	_prompt = Label3D.new()
	_prompt.name = "PromptLabel"
	_prompt.text = "TAP TO HACK"
	_prompt.position = Vector3(0, 2.7, 0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.font_size = 32
	_prompt.pixel_size = 0.006
	_prompt.outline_size = 6
	_prompt.no_depth_test = true
	_prompt.modulate = Color(0.12, 0.95, 1.0)
	_prompt.visible = false
	add_child(_prompt)

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _prompt:
		_prompt.visible = get_player_in_range() and can_hack()
		var camera := get_viewport().get_camera_3d()
		if _prompt.visible and camera:
			_prompt.look_at(camera.global_position, Vector3.UP)
			_prompt.rotate_y(PI)

func _build_collision() -> void:
	var node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	match object_type:
		ObjectType.TRAFFIC_LIGHT:
			shape.size = Vector3(0.65, 2.25, 0.65)
			node.position.y = 1.1
		ObjectType.STEAM_PIPE:
			shape.size = Vector3(1.65, 0.58, 0.62)
			node.position.y = 0.38
		ObjectType.ELECTRICAL_BOX:
			shape.size = Vector3(0.85, 1.1, 0.5)
			node.position.y = 0.62
	node.shape = shape
	add_child(node)

func _build_visuals() -> void:
	match object_type:
		ObjectType.TRAFFIC_LIGHT:
			_add_box("SignalPole", Vector3(0.12, 2.4, 0.12), Vector3(0, 1.2, 0), Color(0.10, 0.14, 0.18))
			_add_box("SignalHousing", Vector3(0.58, 1.0, 0.32), Vector3(0, 2.0, -0.22), Color(0.035, 0.05, 0.07))
			_add_lamp(Color(0.95, 0.08, 0.05), Vector3(0, 2.32, -0.405))
			_add_lamp(Color(1.0, 0.68, 0.08), Vector3(0, 2.0, -0.405))
			_add_lamp(Color(0.08, 0.95, 0.28), Vector3(0, 1.68, -0.405))
		ObjectType.STEAM_PIPE:
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.16
			mesh.bottom_radius = 0.16
			mesh.height = 1.5
			mesh.radial_segments = 12
			var pipe := MeshInstance3D.new()
			pipe.name = "SteamPipe"
			pipe.mesh = mesh
			pipe.position = Vector3(0, 0.35, 0)
			pipe.rotation.z = PI * 0.5
			pipe.material_override = _mat(Color(0.22, 0.29, 0.34), 0.72, 0.45)
			add_child(pipe)
			_add_box("PipeValve", Vector3(0.28, 0.12, 0.12), Vector3(0, 0.56, 0), Color(0.82, 0.27, 0.08))
			_add_box("PipeMount", Vector3(1.65, 0.12, 0.55), Vector3(0, 0.08, 0), Color(0.10, 0.14, 0.17))
		ObjectType.ELECTRICAL_BOX:
			_add_box("ElectricalCabinet", Vector3(0.78, 1.05, 0.42), Vector3(0, 0.62, 0), Color(0.075, 0.13, 0.17))
			_add_box("CabinetDoor", Vector3(0.62, 0.88, 0.035), Vector3(0, 0.64, -0.23), Color(0.12, 0.22, 0.27))
			_status_led = _add_sphere("StatusLED", 0.075, Vector3(0.22, 0.94, -0.27), Color(0.10, 0.92, 0.38), true)

func set_prompt_visible(value: bool) -> void:
	if _prompt:
		_prompt.visible = value and can_hack()

func get_display_name() -> String:
	return display_name

func get_player_in_range() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	return is_instance_valid(player) and player.global_position.distance_to(global_position) <= interaction_range

func can_hack() -> bool:
	return _cooldown <= 0.0 and not (object_type == ObjectType.STEAM_PIPE and _steam_used)

func execute_hack(_player: Node = null) -> bool:
	if not can_hack() or not get_player_in_range():
		return false
	_cooldown = cooldown_duration
	match object_type:
		ObjectType.TRAFFIC_LIGHT:
			_hack_traffic_light()
		ObjectType.STEAM_PIPE:
			_steam_used = true
			_hack_steam_pipe()
		ObjectType.ELECTRICAL_BOX:
			_toggle_dark_zone()
	return true

func is_position_dark(point: Vector3) -> bool:
	return object_type == ObjectType.ELECTRICAL_BOX and _dark_active and point.distance_to(global_position) <= effect_radius

func is_dark_zone_active() -> bool:
	return _dark_active

func _hack_traffic_light() -> void:
	for index in range(_traffic_lamps.size()):
		_set_emission(_traffic_lamps[index], Color(1.0, 0.06, 0.035) if index == 0 else Color(0.12, 0.03, 0.025), index == 0)
	_notify_guards(global_position, effect_radius, false, 4.5)
	print("ENVIRONMENT HACK: %s changed to RED; nearby guards distracted." % name)

func _hack_steam_pipe() -> void:
	if _steam == null:
		_steam = CPUParticles3D.new()
		_steam.name = "SteamBurst"
		_steam.position = Vector3(0, 0.42, 0)
		_steam.amount = 28
		_steam.lifetime = 2.8
		_steam.one_shot = true
		_steam.explosiveness = 0.92
		# CPUParticles3D uses direct particle properties (not GPUParticles3D process_material/draw_pass).
		_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_steam.emission_sphere_radius = 0.38
		_steam.direction = Vector3.UP
		_steam.spread = 58.0
		_steam.gravity = Vector3(0.0, 0.22, 0.0)
		_steam.initial_velocity_min = 1.0
		_steam.initial_velocity_max = 3.2
		_steam.scale_amount_min = 0.28
		_steam.scale_amount_max = 0.72
		_steam.damping_min = 0.2
		_steam.damping_max = 0.7
		var puff := SphereMesh.new()
		puff.radius = 0.15
		puff.height = 0.3
		puff.radial_segments = 8
		puff.rings = 4
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.75, 0.87, 0.9, 0.30)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material = material
		_steam.mesh = puff
		add_child(_steam)
	_steam.restart()
	_steam.emitting = true
	_notify_guards(global_position, effect_radius, true, 5.5)
	print("ENVIRONMENT HACK: %s steam burst; nearby guards blinded and investigating." % name)

func _toggle_dark_zone() -> void:
	_dark_active = not _dark_active
	if _status_led:
		_set_emission(_status_led, Color(0.04, 0.06, 0.07) if _dark_active else Color(0.10, 0.92, 0.38), not _dark_active)
	if _dark_active:
		_saved_lights.clear()
		for candidate in get_tree().get_nodes_in_group("district_lights"):
			if candidate is Light3D:
				var light := candidate as Light3D
				if global_position.distance_to(light.global_position) <= effect_radius:
					_saved_lights.append({"light": light, "energy": light.light_energy})
					light.light_energy = 0.0
	else:
		for entry in _saved_lights:
			var light: Light3D = entry.get("light") as Light3D
			if is_instance_valid(light):
				light.light_energy = float(entry.get("energy", 1.0))
		_saved_lights.clear()
	print("ENVIRONMENT HACK: %s dark zone %s." % [name, "enabled" if _dark_active else "restored"])

func _notify_guards(point: Vector3, radius: float, blind: bool, duration: float) -> void:
	for candidate in get_tree().get_nodes_in_group("guards"):
		if not candidate is Node3D:
			continue
		var guard := candidate as Node3D
		if guard.global_position.distance_to(point) > radius:
			continue
		if blind and guard.has_method("blind_for"):
			guard.call("blind_for", 2.8)
		if guard.has_method("investigate_distraction"):
			guard.call("investigate_distraction", point, duration)
		elif guard.has_method("investigate_sound"):
			guard.call("investigate_sound", point, duration)

func _add_box(label: String, size: Vector3, point: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = point
	visual.material_override = _mat(color)
	add_child(visual)
	return visual

func _add_sphere(label: String, radius: float, point: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	visual.mesh = mesh
	visual.position = point
	visual.material_override = _mat(color, 0.35, 0.0, emissive)
	add_child(visual)
	return visual

func _add_lamp(color: Color, point: Vector3) -> void:
	_traffic_lamps.append(_add_sphere("TrafficLamp", 0.105, point, color, true))

func _mat(color: Color, roughness: float = 0.8, metallic: float = 0.0, emissive: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.75
	return material

func _set_emission(visual: MeshInstance3D, color: Color, enabled: bool) -> void:
	if visual == null:
		return
	var material := visual.material_override as StandardMaterial3D
	if material == null:
		return
	material.albedo_color = color
	material.emission_enabled = enabled
	material.emission = color
