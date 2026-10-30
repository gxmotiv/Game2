extends Node
## Adds a lightweight visual layer after the procedural district has finished building.
## It uses small screen-space shader calculations and MultiMesh batches, not per-prop nodes.

const ROAD_SHADER := preload("res://shaders/city_asphalt.gdshader")
const CONCRETE_SHADER := preload("res://shaders/city_concrete.gdshader")
const FACADE_SHADER := preload("res://shaders/city_facade.gdshader")
const METAL_SHADER := preload("res://shaders/city_metal.gdshader")

func _ready() -> void:
	# The parent creates its procedural geometry in _ready(). Deferring this call
	# guarantees every batch exists before materials and supplemental details are applied.
	call_deferred("_apply_visual_pass")

func _apply_visual_pass() -> void:
	var city := get_parent() as Node3D
	if city == null:
		push_warning("City visual pass has no Node3D parent.")
		return

	_add_environment(city)
	_set_material(city, "RoadNetwork", _shader_material(ROAD_SHADER, {
		"base_color": Color(0.035, 0.052, 0.072),
		"roughness_value": 0.86,
		"grain_strength": 0.13
	}))
	_set_material(city, "DistrictGround/MeshInstance3D", _shader_material(CONCRETE_SHADER, {
		"base_color": Color(0.075, 0.105, 0.13),
		"seam_color": Color(0.035, 0.052, 0.07),
		"tile_scale": 0.18,
		"seam_width": 0.012,
		"roughness_value": 0.95
	}))
	_set_material(city, "SidewalkBlocks", _shader_material(CONCRETE_SHADER, {
		"base_color": Color(0.16, 0.205, 0.23),
		"seam_color": Color(0.065, 0.095, 0.12),
		"tile_scale": 0.40,
		"seam_width": 0.022,
		"roughness_value": 0.92
	}))
	_set_material(city, "CityBuildings", _shader_material(FACADE_SHADER, {
		"base_color": Color.WHITE,
		"roughness_value": 0.84,
		"panel_scale": 0.72
	}))

	var metal_material := _shader_material(METAL_SHADER, {
		"base_color": Color(0.075, 0.12, 0.15),
		"metallic_value": 0.48,
		"roughness_value": 0.58
	})
	for node_path in [
		"RooftopHVAC",
		"StreetUtilityCabinets",
		"DecorativeCameraHousings",
		"SidewalkBollards",
		"JunctionLampPoles"
	]:
		_set_material(city, node_path, metal_material)

	# Sharper glass response; no reflection probes or screen-space reflections.
	var dark_windows := city.get_node_or_null("CityWindows") as GeometryInstance3D
	if dark_windows and dark_windows.material_override is StandardMaterial3D:
		var glass := dark_windows.material_override as StandardMaterial3D
		glass.metallic = 0.28
		glass.roughness = 0.30
	var lit_windows := city.get_node_or_null("CityLitWindows") as GeometryInstance3D
	if lit_windows and lit_windows.material_override is StandardMaterial3D:
		var lit_glass := lit_windows.material_override as StandardMaterial3D
		lit_glass.emission_energy_multiplier = 0.78

	_add_facade_and_roof_details(city)
	_add_crosswalks(city)
	print("CITY VISUAL PASS READY: procedural surface detail, night atmosphere, facade trims, signs and crosswalks.")

func _add_environment(city: Node3D) -> void:
	if city.get_node_or_null("DistrictEnvironment") != null:
		return
	var world_environment := WorldEnvironment.new()
	world_environment.name = "DistrictEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.012, 0.025, 0.052)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.20, 0.30, 0.43)
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.13
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = Color(0.025, 0.065, 0.12)
	environment.fog_depth_begin = 36.0
	environment.fog_depth_end = 126.0
	environment.fog_depth_curve = 1.35
	# Compatibility renderer uses a simplified glow path; keep it intentionally subtle.
	environment.glow_enabled = true
	environment.glow_intensity = 0.32
	environment.glow_bloom = 0.045
	environment.glow_hdr_threshold = 1.15
	world_environment.environment = environment
	city.add_child(world_environment)

func _shader_material(shader: Shader, parameters: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	for key in parameters.keys():
		material.set_shader_parameter(key, parameters[key])
	return material

func _set_material(root: Node, node_path: String, material: Material) -> void:
	var target := root.get_node_or_null(node_path) as GeometryInstance3D
	if target != null:
		target.material_override = material
		target.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _add_facade_and_roof_details(city: Node3D) -> void:
	var building_batch := city.get_node_or_null("CityBuildings") as MultiMeshInstance3D
	if building_batch == null or building_batch.multimesh == null:
		return

	var roof_trim: Array[Dictionary] = []
	var neon_edges: Array[Dictionary] = []
	var sign_panels: Array[Dictionary] = []
	var cyan_sign_lines: Array[Dictionary] = []
	var amber_sign_lines: Array[Dictionary] = []
	var antennas: Array[Dictionary] = []
	var count := building_batch.multimesh.instance_count

	for index in range(count):
		var transform := building_batch.multimesh.get_instance_transform(index)
		var size := transform.basis.get_scale()
		var center := transform.origin
		roof_trim.append({
			"position": Vector3(center.x, center.y + size.y * 0.5 + 0.075, center.z),
			"size": Vector3(size.x + 0.22, 0.15, size.z + 0.22)
		})

		if index % 2 == 0:
			neon_edges.append({
				"position": Vector3(center.x - size.x * 0.40, center.y + 0.15, center.z + size.z * 0.5 + 0.06),
				"size": Vector3(0.075, min(size.y * 0.68, 5.6), 0.055)
			})

		if index % 4 == 0:
			var sign_center := Vector3(center.x, center.y + size.y * 0.62, center.z + size.z * 0.5 + 0.13)
			sign_panels.append({
				"position": sign_center,
				"size": Vector3(2.45, 0.78, 0.12)
			})
			var line_array := cyan_sign_lines if (index / 4) % 2 == 0 else amber_sign_lines
			line_array.append({
				"position": sign_center + Vector3(0.0, 0.26, -0.075),
				"size": Vector3(2.05, 0.055, 0.035)
			})
			line_array.append({
				"position": sign_center + Vector3(-0.58, -0.05, -0.075),
				"size": Vector3(0.78, 0.055, 0.035)
			})
			line_array.append({
				"position": sign_center + Vector3(0.50, -0.20, -0.075),
				"size": Vector3(0.95, 0.035, 0.035)
			})

		if index % 3 == 0:
			antennas.append({
				"position": Vector3(center.x + size.x * 0.22, center.y + size.y * 0.5 + 0.58, center.z - size.z * 0.18),
				"size": Vector3(0.065, 1.15, 0.065)
			})

	_add_boxes(city, "BuildingRoofTrims", roof_trim, _flat_material(Color(0.075, 0.11, 0.14), 0.62, 0.34))
	_add_boxes(city, "BuildingNeonEdges", neon_edges, _emissive_material(Color(0.015, 0.52, 0.78), 0.82))
	_add_boxes(city, "BuildingSignPanels", sign_panels, _flat_material(Color(0.018, 0.035, 0.060), 0.34, 0.42))
	_add_boxes(city, "CyanSignLighting", cyan_sign_lines, _emissive_material(Color(0.02, 0.62, 0.95), 0.88))
	_add_boxes(city, "AmberSignLighting", amber_sign_lines, _emissive_material(Color(1.0, 0.26, 0.075), 0.72))
	_add_boxes(city, "RooftopAntennas", antennas, _flat_material(Color(0.10, 0.15, 0.18), 0.52, 0.55))

func _add_crosswalks(city: Node3D) -> void:
	var stripes: Array[Dictionary] = []
	# Interior intersections only: clear navigation cues without filling every road segment.
	for street_x in range(-1, 2):
		for street_z in range(-1, 2):
			var x := float(street_x) * 24.0
			var z := float(street_z) * 24.0
			for side in [-1.0, 1.0]:
				for stripe in range(4):
					var offset := float(stripe) * 0.34
					stripes.append({
						"position": Vector3(x, 0.055, z + side * (3.95 + offset)),
						"size": Vector3(5.8, 0.018, 0.16)
					})
					stripes.append({
						"position": Vector3(x + side * (3.95 + offset), 0.055, z),
						"size": Vector3(0.16, 0.018, 5.8)
					})
	_add_boxes(city, "IntersectionCrosswalks", stripes, _flat_material(Color(0.68, 0.78, 0.80), 0.95, 0.0))

func _flat_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.roughness = 0.34
	return material

func _add_boxes(parent: Node3D, node_name: String, entries: Array[Dictionary], material: Material) -> void:
	if entries.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = BoxMesh.new()
	multi.instance_count = entries.size()
	for index in range(entries.size()):
		var item: Dictionary = entries[index]
		var size: Vector3 = item["size"]
		var position: Vector3 = item["position"]
		multi.set_instance_transform(index, Transform3D(Basis().scaled(size), position))
	var visual := MultiMeshInstance3D.new()
	visual.name = node_name
	visual.multimesh = multi
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)
