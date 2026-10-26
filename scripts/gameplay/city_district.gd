extends Node3D
## Procedurally builds a compact, low-poly city district using primitive meshes.
## The shared MultiMesh batches visual geometry to keep draw calls low on Android.

const TERMINAL_SCENE: PackedScene = preload("res://scenes/gameplay/terminal/terminal.tscn")
const GUARD_SCENE: PackedScene = preload("res://scenes/gameplay/guard/guard.tscn")
const STREET_SPACING: float = 24.0
const CITY_EXTENT: float = 144.0
const STREET_HALF_COUNT: int = 2

var _rng := RandomNumberGenerator.new()
var _building_collision_count: int = 0
var _security_devices: Dictionary = {}

func _ready() -> void:
	_rng.seed = 20261026
	_build_city_geometry()
	_build_security_network()
	_build_extra_terminals()
	_build_extra_guards()
	print("CITY DISTRICT READY: 4x4 blocks, roads, 4 hackable terminals, low-poly batched geometry.")

func _build_city_geometry() -> void:
	var ground_material := _material(Color(0.11, 0.14, 0.16))
	var road_material := _material(Color(0.055, 0.065, 0.075))
	var sidewalk_material := _material(Color(0.24, 0.27, 0.29))
	var marking_material := _material(Color(0.72, 0.75, 0.68))
	var building_material := _material(Color.WHITE)
	building_material.vertex_color_use_as_albedo = true
	building_material.roughness = 0.92

	# A single collision floor supports the entire district.
	_add_solid_box("DistrictGround", Vector3(0, -0.5, 0), Vector3(CITY_EXTENT, 1.0, CITY_EXTENT), ground_material)

	# Batch all road segments into one draw call.
	var road_instances: Array[Dictionary] = []
	for street in range(-STREET_HALF_COUNT, STREET_HALF_COUNT + 1):
		var offset := float(street) * STREET_SPACING
		road_instances.append({"position": Vector3(0, 0.012, offset), "size": Vector3(CITY_EXTENT, 0.025, 7.0)})
		road_instances.append({"position": Vector3(offset, 0.012, 0), "size": Vector3(7.0, 0.025, CITY_EXTENT)})
	_add_multimesh_boxes("RoadNetwork", road_instances, road_material, false)

	# Sidewalk blocks are also batched; buildings stand on these walkable blocks.
	var sidewalk_instances: Array[Dictionary] = []
	for block_x in range(-STREET_HALF_COUNT, STREET_HALF_COUNT):
		for block_z in range(-STREET_HALF_COUNT, STREET_HALF_COUNT):
			var center := Vector3((float(block_x) + 0.5) * STREET_SPACING, 0.025, (float(block_z) + 0.5) * STREET_SPACING)
			sidewalk_instances.append({"position": center, "size": Vector3(17.0, 0.08, 17.0)})
	_add_multimesh_boxes("SidewalkBlocks", sidewalk_instances, sidewalk_material, false)

	# Dashed lane markings: one batched mesh, no individual node per dash.
	var marking_instances: Array[Dictionary] = []
	for street in range(-STREET_HALF_COUNT, STREET_HALF_COUNT + 1):
		var offset := float(street) * STREET_SPACING
		for dash in range(-3, 4):
			var along := float(dash) * 16.0
			marking_instances.append({"position": Vector3(along, 0.03, offset), "size": Vector3(2.2, 0.012, 0.12)})
			marking_instances.append({"position": Vector3(offset, 0.03, along), "size": Vector3(0.12, 0.012, 2.2)})
	_add_multimesh_boxes("RoadMarkings", marking_instances, marking_material, false)

	# 32 varied buildings with collision bodies; all visible buildings share one draw call.
	var building_instances: Array[Dictionary] = []
	var building_palette: Array[Color] = [
		Color(0.22, 0.28, 0.34), Color(0.30, 0.32, 0.35),
		Color(0.25, 0.29, 0.30), Color(0.34, 0.28, 0.25),
		Color(0.19, 0.25, 0.31)
	]
	for block_x in range(-STREET_HALF_COUNT, STREET_HALF_COUNT):
		for block_z in range(-STREET_HALF_COUNT, STREET_HALF_COUNT):
			var block_center := Vector3((float(block_x) + 0.5) * STREET_SPACING, 0.0, (float(block_z) + 0.5) * STREET_SPACING)
			for slot in range(2):
				var footprint := Vector3(_rng.randf_range(5.0, 6.0), 1.0, _rng.randf_range(5.0, 6.0))
				var height := _rng.randf_range(5.0, 13.0)
				footprint.y = height
				var diagonal := -1.0 if slot == 0 else 1.0
				var position := Vector3(block_center.x + diagonal * 3.4, height * 0.5 + 0.08, block_center.z + diagonal * 3.4)
				var tint: Color = building_palette[_rng.randi_range(0, building_palette.size() - 1)]
				building_instances.append({"position": position, "size": footprint, "color": tint})
				_add_building_collision("BuildingCollision_%02d" % _building_collision_count, position, footprint)
				_building_collision_count += 1
	_add_multimesh_boxes("CityBuildings", building_instances, building_material, true)

	# Low-cost street lamps at the central junction make the district readable at a glance.
	var pole_material := _material(Color(0.13, 0.16, 0.19))
	var lamp_instances: Array[Dictionary] = []
	for x_sign in [-1.0, 1.0]:
		for z_sign in [-1.0, 1.0]:
			lamp_instances.append({"position": Vector3(x_sign * 4.2, 1.7, z_sign * 4.2), "size": Vector3(0.12, 3.4, 0.12)})
	_add_multimesh_boxes("JunctionLampPoles", lamp_instances, pole_material, false)

	var lamp_cap_material := _material(Color(0.18, 0.85, 1.0), true)
	var cap_instances: Array[Dictionary] = []
	for x_sign in [-1.0, 1.0]:
		for z_sign in [-1.0, 1.0]:
			cap_instances.append({"position": Vector3(x_sign * 4.2, 3.35, z_sign * 4.2), "size": Vector3(0.45, 0.12, 0.45)})
	_add_multimesh_boxes("JunctionLampCaps", cap_instances, lamp_cap_material, false)

	var sun := DirectionalLight3D.new()
	sun.name = "DistrictLight"
	sun.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(35.0), 0.0)
	sun.light_color = Color(0.77, 0.84, 1.0)
	sun.light_energy = 0.8
	sun.shadow_enabled = false
	add_child(sun)

func _build_security_network() -> void:
	_security_devices["SecurityLight"] = _create_security_light("SecurityLight", Vector3(6.0, 3.0, -8.0))
	_security_devices["SecurityLightNorth"] = _create_security_light("SecurityLightNorth", Vector3(-7.0, 3.0, 12.0))
	_security_devices["SecurityLightEast"] = _create_security_light("SecurityLightEast", Vector3(29.0, 3.0, -12.0))
	_security_devices["SecurityLightWest"] = _create_security_light("SecurityLightWest", Vector3(-29.0, 3.0, -12.0))

func _create_security_light(device_name: String, position: Vector3) -> Node3D:
	var script_resource := load("res://scripts/gameplay/security_light.gd") as Script
	var device := script_resource.new() as Node3D
	device.name = device_name
	device.position = position
	var lamp := OmniLight3D.new()
	lamp.name = "SecurityLightOmni"
	lamp.light_color = Color(1.0, 0.28, 0.12)
	lamp.light_energy = 0.45
	lamp.light_range = 5.5
	lamp.shadow_enabled = false
	device.add_child(lamp)
	var lamp_mesh := MeshInstance3D.new()
	lamp_mesh.name = "SecurityLightMesh"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.16
	cylinder.bottom_radius = 0.22
	cylinder.height = 0.35
	lamp_mesh.mesh = cylinder
	var material := _material(Color(1.0, 0.2, 0.08), true)
	material.emission_energy_multiplier = 1.2
	lamp_mesh.material_override = material
	lamp_mesh.position.y = 0.0
	device.add_child(lamp_mesh)
	device.set("light_node", lamp)
	device.set("light_mesh", lamp_mesh)
	add_child(device)
	return device

func _build_extra_terminals() -> void:
	var placements: Array[Dictionary] = [
		{"name": "TerminalNorth", "position": Vector3(-4.0, 1.0, 12.0), "device": "SecurityLightNorth"},
		{"name": "TerminalEast", "position": Vector3(28.0, 1.0, -12.0), "device": "SecurityLightEast"},
		{"name": "TerminalWest", "position": Vector3(-28.0, 1.0, -12.0), "device": "SecurityLightWest"}
	]
	for placement in placements:
		var terminal := TERMINAL_SCENE.instantiate() as Node3D
		terminal.name = str(placement["name"])
		terminal.position = placement["position"]
		terminal.set("linked_security_device", _security_devices[str(placement["device"])])
		add_child(terminal)

func _build_extra_guards() -> void:
	# Keep a small number of guards for gameplay density and Android performance.
	var guard_a := GUARD_SCENE.instantiate() as Node3D
	guard_a.name = "DistrictGuardNorth"
	guard_a.position = Vector3(0.0, 1.0, 22.0)
	add_child(guard_a)
	var guard_b := GUARD_SCENE.instantiate() as Node3D
	guard_b.name = "DistrictGuardEast"
	guard_b.position = Vector3(22.0, 1.0, 0.0)
	add_child(guard_b)

func _add_solid_box(box_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = position
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	add_child(body)

func _add_building_collision(box_name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = position
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)

func _add_multimesh_boxes(node_name: String, instances: Array[Dictionary], material: StandardMaterial3D, use_instance_colors: bool) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = use_instance_colors
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	multi.mesh = box
	multi.instance_count = instances.size()
	for index in range(instances.size()):
		var item: Dictionary = instances[index]
		var size: Vector3 = item["size"]
		var position: Vector3 = item["position"]
		multi.set_instance_transform(index, Transform3D(Basis().scaled(size), position))
		if use_instance_colors:
			multi.set_instance_color(index, item["color"])
	var visual := MultiMeshInstance3D.new()
	visual.name = node_name
	visual.multimesh = multi
	visual.material_override = material
	add_child(visual)

func _material(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.7
	return material
