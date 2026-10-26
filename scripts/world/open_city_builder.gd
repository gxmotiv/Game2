extends Node3D
class_name OpenCityBuilder

@export var district_half_extent: float = 150.0
@export var street_spacing: float = 40.0
@export var street_width: float = 8.0
@export var spawn_district_terminals: bool = true
@export var spawn_network_devices: bool = true

const TERMINAL_SCENE: PackedScene = preload("res://scenes/gameplay/terminal/terminal.tscn")
const DEVICE_SCENE: PackedScene = preload("res://scenes/gameplay/city_device.tscn")
const GUARD_SCENE: PackedScene = preload("res://scenes/gameplay/guard/guard.tscn")

var _rng := RandomNumberGenerator.new()
var _window_transforms: Array[Transform3D] = []
var _window_colors: Array[Color] = []

func _ready() -> void:
	_rng.seed = 741029
	add_to_group("open_world")
	_add_mobile_sunlight()
	_build_ground()
	_build_roads_and_sidewalks()
	_build_buildings()
	_build_road_markings()
	_build_window_multimesh()
	if spawn_network_devices:
		_spawn_network_devices()
	if spawn_district_terminals:
		_spawn_district_terminals()
	# Defer patrols until the main scene has registered the player group.
	call_deferred("_spawn_patrol_guards")
	print("OPEN CITY READY: 300m district, 36 city blocks, procedural buildings and hackable network devices.")


func _add_mobile_sunlight() -> void:
	# One non-shadow-casting directional light keeps the whole district readable
	# without a per-building light budget on low-end mobile GPUs.
	var sunlight := DirectionalLight3D.new()
	sunlight.name = "DistrictSunlight"
	sunlight.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(-28.0), 0.0)
	sunlight.light_color = Color(0.78, 0.86, 1.0)
	sunlight.light_energy = 1.15
	sunlight.shadow_enabled = false
	add_child(sunlight)

func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "DistrictGround"
	ground.position.y = -0.5
	add_child(ground)

	var ground_size := Vector3(district_half_extent * 2.0, 1.0, district_half_extent * 2.0)
	var ground_shape := BoxShape3D.new()
	ground_shape.size = ground_size
	var collision := CollisionShape3D.new()
	collision.name = "GroundCollision"
	collision.shape = ground_shape
	ground.add_child(collision)

	var ground_mesh := BoxMesh.new()
	ground_mesh.size = ground_size
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "GroundMesh"
	floor_mesh.mesh = ground_mesh
	floor_mesh.material_override = _make_material(Color(0.12, 0.14, 0.16))
	ground.add_child(floor_mesh)

	# Invisible boundary walls prevent the player from walking off the district.
	_add_boundary_wall("BoundaryNorth", Vector3(0.0, 5.0, district_half_extent), Vector3(district_half_extent * 2.0, 10.0, 1.0))
	_add_boundary_wall("BoundarySouth", Vector3(0.0, 5.0, -district_half_extent), Vector3(district_half_extent * 2.0, 10.0, 1.0))
	_add_boundary_wall("BoundaryEast", Vector3(district_half_extent, 5.0, 0.0), Vector3(1.0, 10.0, district_half_extent * 2.0))
	_add_boundary_wall("BoundaryWest", Vector3(-district_half_extent, 5.0, 0.0), Vector3(1.0, 10.0, district_half_extent * 2.0))

func _add_boundary_wall(node_name: String, wall_position: Vector3, wall_size: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.name = node_name
	wall.position = wall_position
	var shape := BoxShape3D.new()
	shape.size = wall_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)

func _build_roads_and_sidewalks() -> void:
	var road_material := _make_material(Color(0.045, 0.055, 0.068))
	var sidewalk_material := _make_material(Color(0.20, 0.22, 0.24))
	var road_length := district_half_extent * 2.0

	for coordinate in range(-120, 121, int(street_spacing)):
		var vertical_road := BoxMesh.new()
		vertical_road.size = Vector3(street_width, 0.04, road_length)
		_add_visual(vertical_road, Vector3(float(coordinate), 0.025, 0.0), road_material, "Road_NS_%d" % coordinate)

		var horizontal_road := BoxMesh.new()
		horizontal_road.size = Vector3(road_length, 0.04, street_width)
		_add_visual(horizontal_road, Vector3(0.0, 0.025, float(coordinate)), road_material, "Road_EW_%d" % coordinate)

		for side in [-1.0, 1.0]:
			var vertical_sidewalk := BoxMesh.new()
			vertical_sidewalk.size = Vector3(1.6, 0.025, road_length)
			_add_visual(vertical_sidewalk, Vector3(float(coordinate) + side * (street_width * 0.5 + 1.0), 0.012, 0.0), sidewalk_material, "Sidewalk_NS_%d_%d" % [coordinate, int(side)])

			var horizontal_sidewalk := BoxMesh.new()
			horizontal_sidewalk.size = Vector3(road_length, 0.025, 1.6)
			_add_visual(horizontal_sidewalk, Vector3(0.0, 0.012, float(coordinate) + side * (street_width * 0.5 + 1.0)), sidewalk_material, "Sidewalk_EW_%d_%d" % [coordinate, int(side)])

func _build_buildings() -> void:
	var colors: Array[Color] = [
		Color(0.18, 0.23, 0.28),
		Color(0.24, 0.25, 0.29),
		Color(0.28, 0.20, 0.19),
		Color(0.17, 0.27, 0.28),
		Color(0.30, 0.29, 0.25),
		Color(0.20, 0.20, 0.26)
	]
	for block_x in range(-3, 3):
		for block_z in range(-3, 3):
			var base_x := float(block_x) * street_spacing + street_spacing * 0.5
			var base_z := float(block_z) * street_spacing + street_spacing * 0.5
			var center := Vector3(
				base_x + _rng.randf_range(-2.0, 2.0),
				0.0,
				base_z + _rng.randf_range(-2.0, 2.0)
			)
			var width := _rng.randf_range(9.0, 15.0)
			var depth := _rng.randf_range(9.0, 15.0)
			var height := _rng.randf_range(10.0, 25.0)
			var is_landmark := block_x == 0 and block_z == 0
			if is_landmark:
				width = 14.0
				depth = 14.0
				height = 34.0
			var color_index := _rng.randi_range(0, colors.size() - 1)
			_create_building("Building_%d_%d" % [block_x + 3, block_z + 3], center, Vector3(width, height, depth), colors[color_index], is_landmark)

func _create_building(node_name: String, center: Vector3, size: Vector3, building_color: Color, landmark: bool) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = Vector3(center.x, size.y * 0.5, center.z)
	add_child(body)

	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "BuildingCollision"
	collision.shape = shape
	body.add_child(collision)

	var box := BoxMesh.new()
	box.size = size
	var building_mat := _make_material(building_color)
	var mesh := MeshInstance3D.new()
	mesh.name = "BuildingMesh"
	mesh.mesh = box
	mesh.material_override = building_mat
	body.add_child(mesh)

	_queue_building_windows(center, size)

	# Original neon facade sign: visual detail only, no additional collision.
	var sign_width := minf(3.6, size.x * 0.48)
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(sign_width, 0.28, 0.10)
	var sign_color := Color(0.08, 0.9, 0.75) if landmark else Color(_rng.randf_range(0.2, 1.0), _rng.randf_range(0.2, 1.0), _rng.randf_range(0.2, 1.0))
	var sign_material := _make_material(sign_color, sign_color, 0.55)
	var sign := MeshInstance3D.new()
	sign.name = "NeonFacadeSign"
	sign.mesh = sign_mesh
	sign.material_override = sign_material
	sign.position = Vector3(0.0, 3.0 - size.y * 0.5, size.z * 0.5 + 0.07)
	body.add_child(sign)

	if _rng.randf() < 0.55 or landmark:
		var roof_unit := BoxMesh.new()
		roof_unit.size = Vector3(1.4, 0.7, 1.2)
		var roof_mesh := MeshInstance3D.new()
		roof_mesh.name = "RoofEquipment"
		roof_mesh.mesh = roof_unit
		roof_mesh.material_override = _make_material(Color(0.07, 0.09, 0.12))
		roof_mesh.position = Vector3(_rng.randf_range(-size.x * 0.2, size.x * 0.2), size.y * 0.5 + 0.35, 0.0)
		body.add_child(roof_mesh)

func _queue_building_windows(center: Vector3, size: Vector3) -> void:
	var window_colors: Array[Color] = [
		Color(0.36, 0.78, 0.90),
		Color(0.95, 0.72, 0.42),
		Color(0.24, 0.55, 0.72),
		Color(0.52, 0.88, 0.82)
	]
	var columns_x := clampi(int(size.x / 2.5), 2, 5)
	var columns_z := clampi(int(size.z / 2.5), 2, 5)
	var rows := clampi(int(size.y / 2.7), 2, 12)
	for row in range(1, rows):
		var y := float(row) * 2.65
		for column in range(columns_x):
			var x_offset := lerpf(-size.x * 0.31, size.x * 0.31, float(column) / float(maxi(columns_x - 1, 1)))
			_queue_window(Transform3D(Basis.IDENTITY, Vector3(center.x + x_offset, y, center.z + size.z * 0.5 + 0.06)), window_colors[_rng.randi_range(0, window_colors.size() - 1)])
			_queue_window(Transform3D(Basis.IDENTITY, Vector3(center.x + x_offset, y, center.z - size.z * 0.5 - 0.06)), window_colors[_rng.randi_range(0, window_colors.size() - 1)])
		for column in range(columns_z):
			var z_offset := lerpf(-size.z * 0.31, size.z * 0.31, float(column) / float(maxi(columns_z - 1, 1)))
			var x_basis := Basis(Vector3.UP, PI * 0.5)
			_queue_window(Transform3D(x_basis, Vector3(center.x + size.x * 0.5 + 0.06, y, center.z + z_offset)), window_colors[_rng.randi_range(0, window_colors.size() - 1)])
			_queue_window(Transform3D(x_basis, Vector3(center.x - size.x * 0.5 - 0.06, y, center.z + z_offset)), window_colors[_rng.randi_range(0, window_colors.size() - 1)])

func _queue_window(transform: Transform3D, tint: Color) -> void:
	_window_transforms.append(transform)
	_window_colors.append(tint)

func _build_window_multimesh() -> void:
	if _window_transforms.is_empty():
		return
	var window_mesh := BoxMesh.new()
	window_mesh.size = Vector3(0.82, 0.48, 0.07)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = window_mesh
	multi.instance_count = _window_transforms.size()
	for index in range(_window_transforms.size()):
		multi.set_instance_transform(index, _window_transforms[index])
		multi.set_instance_color(index, _window_colors[index])
	var window_material := StandardMaterial3D.new()
	window_material.vertex_color_use_as_albedo = true
	window_material.emission_enabled = true
	window_material.emission = Color(0.22, 0.42, 0.55)
	window_material.emission_energy_multiplier = 0.22
	var windows := MultiMeshInstance3D.new()
	windows.name = "InstancedBuildingWindows"
	windows.multimesh = multi
	windows.material_override = window_material
	windows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(windows)

func _build_road_markings() -> void:
	var transforms: Array[Transform3D] = []
	var white := _make_material(Color(0.63, 0.69, 0.72))
	for street in range(-120, 121, int(street_spacing)):
		for offset in range(-132, 133, 12):
			if _near_street(float(offset)):
				continue
			for lane_offset in [-1.25, 1.25]:
				transforms.append(Transform3D(Basis.IDENTITY, Vector3(float(street) + lane_offset, 0.052, float(offset))))
				var horizontal_basis := Basis(Vector3.UP, PI * 0.5)
				transforms.append(Transform3D(horizontal_basis, Vector3(float(offset), 0.052, float(street) + lane_offset))
			)
	var dash := BoxMesh.new()
	dash.size = Vector3(0.12, 0.025, 2.8)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = dash
	multi.instance_count = transforms.size()
	for index in range(transforms.size()):
		multi.set_instance_transform(index, transforms[index])
	var markings := MultiMeshInstance3D.new()
	markings.name = "RoadLaneMarkings"
	markings.multimesh = multi
	markings.material_override = white
	markings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(markings)

func _near_street(value: float) -> bool:
	for street in range(-120, 121, int(street_spacing)):
		if absf(value - float(street)) < 5.0:
			return true
	return false

func _spawn_network_devices() -> void:
	var definitions: Array[Dictionary] = [
		{"name": "TrafficSignal_Alpha", "label": "Traffic control", "type": 0, "position": Vector3(6, 0, -34), "yaw": 0.0},
		{"name": "SecurityCamera_Beta", "label": "Street camera", "type": 1, "position": Vector3(-6, 0, 46), "yaw": PI},
		{"name": "PowerRelay_Gamma", "label": "Power relay", "type": 2, "position": Vector3(46, 0, 6), "yaw": 0.0},
		{"name": "SecurityCamera_Delta", "label": "Security camera", "type": 1, "position": Vector3(-46, 0, -6), "yaw": PI * 0.5},
		{"name": "TrafficSignal_Epsilon", "label": "Traffic control", "type": 0, "position": Vector3(86, 0, 46), "yaw": PI},
		{"name": "SecurityCamera_Zeta", "label": "Street camera", "type": 1, "position": Vector3(-86, 0, -46), "yaw": 0.0},
		{"name": "PowerRelay_Eta", "label": "Power relay", "type": 2, "position": Vector3(46, 0, 86), "yaw": 0.0},
		{"name": "SecurityCamera_Theta", "label": "Security camera", "type": 1, "position": Vector3(-46, 0, -86), "yaw": PI * 0.5}
	]
	for definition in definitions:
		var device := DEVICE_SCENE.instantiate() as Node3D
		if device == null:
			push_warning("Could not instance a city network device.")
			continue
		device.name = str(definition["name"])
		device.position = definition["position"]
		device.rotation.y = float(definition["yaw"])
		device.set("device_type", int(definition["type"]))
		device.set("display_name", str(definition["label"]))
		add_child(device)

func _spawn_district_terminals() -> void:
	var positions: Array[Vector3] = [
		Vector3(33.0, 0.75, -20.0),
		Vector3(-33.0, 0.75, -20.0),
		Vector3(33.0, 0.75, 20.0),
		Vector3(-33.0, 0.75, 20.0)
	]
	for index in range(positions.size()):
		var terminal := TERMINAL_SCENE.instantiate() as Node3D
		if terminal == null:
			push_warning("Could not instance a district terminal.")
			continue
		terminal.name = "DistrictRelay_%02d" % (index + 1)
		terminal.position = positions[index]
		if index % 2 == 1:
			terminal.rotation.y = PI
		var light := terminal.get_node_or_null("StatusLight/StatusLightGlow") as OmniLight3D
		if light:
			# Keep the emissive indicator but disable dynamic point lights on mobile.
			light.visible = false
		add_child(terminal)

func _add_visual(mesh_resource: Mesh, mesh_position: Vector3, material: Material, node_name: String) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh_resource
	instance.position = mesh_position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

func _make_material(color: Color, glow_color: Color = Color.BLACK, glow_strength: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if glow_strength > 0.0:
		material.emission_enabled = true
		material.emission = glow_color
		material.emission_energy_multiplier = glow_strength
	return material

func _spawn_patrol_guards() -> void:
	var east_route: Array[Vector3] = [
		Vector3(45, 0, 45), Vector3(45, 0, 75),
		Vector3(75, 0, 75), Vector3(75, 0, 45)
	]
	var southwest_route: Array[Vector3] = [
		Vector3(-45, 0, -45), Vector3(-45, 0, -75),
		Vector3(-75, 0, -75), Vector3(-75, 0, -45)
	]
	var far_east_route: Array[Vector3] = [
		Vector3(85, 0, -45), Vector3(85, 0, -75),
		Vector3(115, 0, -75), Vector3(115, 0, -45)
	]
	_spawn_guard("DistrictGuard_East", east_route)
	_spawn_guard("DistrictGuard_Southwest", southwest_route)
	_spawn_guard("DistrictGuard_FarEast", far_east_route)

func _spawn_guard(guard_name: String, patrol_points: Array[Vector3]) -> void:
	var guard := GUARD_SCENE.instantiate() as CharacterBody3D
	if guard == null:
		push_warning("Could not instance patrol guard: " + guard_name)
		return
	guard.name = guard_name
	guard.set("patrol_points", patrol_points)
	guard.position = patrol_points[0] + Vector3(0.0, 1.0, 0.0)
	add_child(guard)
