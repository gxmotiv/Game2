extends MeshInstance3D
## Builds a compact, low-poly operative mesh at runtime.
## Geometry is merged into three material surfaces so the character costs
## three draw calls instead of one draw call per body part.

const SPHERE_SEGMENTS: int = 8
const SPHERE_RINGS: int = 4

func _ready() -> void:
	_build_character()

func _build_character() -> void:
	var fabric := StandardMaterial3D.new()
	fabric.albedo_color = Color(0.025, 0.045, 0.07, 1.0)
	fabric.roughness = 0.82

	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color(0.11, 0.15, 0.20, 1.0)
	armor.metallic = 0.52
	armor.roughness = 0.42

	var cyan := StandardMaterial3D.new()
	cyan.albedo_color = Color(0.03, 0.72, 1.0, 1.0)
	cyan.metallic = 0.1
	cyan.roughness = 0.3
	cyan.emission_enabled = true
	cyan.emission = Color(0.0, 0.40, 1.0, 1.0)
	cyan.emission_energy_multiplier = 1.5

	var combined := ArrayMesh.new()

	var fabric_tool := SurfaceTool.new()
	fabric_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(fabric_tool, Vector3(0, 0, 0), Vector3(0.54, 0.68, 0.32))
	_add_sphere(fabric_tool, Vector3(0, 0.56, 0.01), 0.19)
	_add_box(fabric_tool, Vector3(-0.37, 0.02, 0), Vector3(0.16, 0.35, 0.18))
	_add_box(fabric_tool, Vector3(0.37, 0.02, 0), Vector3(0.16, 0.35, 0.18))
	_add_box(fabric_tool, Vector3(-0.15, -0.53, 0), Vector3(0.18, 0.37, 0.22))
	_add_box(fabric_tool, Vector3(0.15, -0.53, 0), Vector3(0.18, 0.37, 0.22))
	_add_surface(combined, fabric_tool, fabric)

	var armor_tool := SurfaceTool.new()
	armor_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(armor_tool, Vector3(0, 0.08, -0.17), Vector3(0.40, 0.32, 0.075))
	_add_box(armor_tool, Vector3(-0.29, 0.24, 0), Vector3(0.20, 0.18, 0.24))
	_add_box(armor_tool, Vector3(0.29, 0.24, 0), Vector3(0.20, 0.18, 0.24))
	_add_box(armor_tool, Vector3(-0.39, -0.23, -0.015), Vector3(0.145, 0.29, 0.16))
	_add_box(armor_tool, Vector3(0.39, -0.23, -0.015), Vector3(0.145, 0.29, 0.16))
	_add_box(armor_tool, Vector3(-0.15, -0.72, -0.005), Vector3(0.15, 0.33, 0.18))
	_add_box(armor_tool, Vector3(0.15, -0.72, -0.005), Vector3(0.15, 0.33, 0.18))
	_add_box(armor_tool, Vector3(0, 0.025, 0.22), Vector3(0.32, 0.40, 0.16))
	_add_box(armor_tool, Vector3(0, -0.31, 0), Vector3(0.44, 0.12, 0.31))
	_add_box(armor_tool, Vector3(-0.23, -0.31, -0.09), Vector3(0.12, 0.14, 0.10))
	_add_box(armor_tool, Vector3(0.23, -0.31, -0.09), Vector3(0.12, 0.14, 0.10))
	_add_box(armor_tool, Vector3(-0.15, -0.84, -0.035), Vector3(0.19, 0.13, 0.29))
	_add_box(armor_tool, Vector3(0.15, -0.84, -0.035), Vector3(0.19, 0.13, 0.29))
	_add_box(armor_tool, Vector3(-0.39, -0.40, -0.025), Vector3(0.13, 0.12, 0.15))
	_add_box(armor_tool, Vector3(0.39, -0.40, -0.025), Vector3(0.13, 0.12, 0.15))
	_add_surface(combined, armor_tool, armor)

	var tech_tool := SurfaceTool.new()
	tech_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(tech_tool, Vector3(0, 0.58, -0.17), Vector3(0.28, 0.075, 0.035))
	_add_box(tech_tool, Vector3(0, 0.08, -0.214), Vector3(0.16, 0.055, 0.025))
	_add_box(tech_tool, Vector3(-0.43, -0.25, -0.105), Vector3(0.17, 0.08, 0.13))
	_add_surface(combined, tech_tool, cyan)

	mesh = combined

func _add_surface(target: ArrayMesh, tool: SurfaceTool, material: Material) -> void:
	var generated: ArrayMesh = tool.commit()
	if generated.get_surface_count() == 0:
		return
	var surface_index: int = target.get_surface_count()
	target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, generated.surface_get_arrays(0))
	target.surface_set_material(surface_index, material)

func _add_box(tool: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var lbf := center + Vector3(-h.x, -h.y, -h.z)
	var rbf := center + Vector3(h.x, -h.y, -h.z)
	var rtf := center + Vector3(h.x, h.y, -h.z)
	var ltf := center + Vector3(-h.x, h.y, -h.z)
	var lbb := center + Vector3(-h.x, -h.y, h.z)
	var rbb := center + Vector3(h.x, -h.y, h.z)
	var rtb := center + Vector3(h.x, h.y, h.z)
	var ltb := center + Vector3(-h.x, h.y, h.z)

	# Each quad is ordered so its triangles face outward.
	_add_quad(tool, lbf, ltf, rtf, rbf) # front
	_add_quad(tool, lbb, rbb, rtb, ltb) # back
	_add_quad(tool, rbf, rtf, rtb, rbb) # right
	_add_quad(tool, lbf, lbb, ltb, ltf) # left
	_add_quad(tool, ltf, ltb, rtb, rtf) # top
	_add_quad(tool, lbf, rbf, rbb, lbb) # bottom

func _add_quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_add_triangle(tool, a, b, c)
	_add_triangle(tool, a, c, d)

func _add_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	if normal.length_squared() < 0.5:
		return
	# Godot 4 uses clockwise front-face winding; keep the outward normal and reverse vertex order.
	tool.set_normal(normal)
	tool.add_vertex(a)
	tool.set_normal(normal)
	tool.add_vertex(c)
	tool.set_normal(normal)
	tool.add_vertex(b)

func _add_sphere(tool: SurfaceTool, center: Vector3, radius: float) -> void:
	for ring in range(SPHERE_RINGS):
		var lat0: float = PI * float(ring) / float(SPHERE_RINGS)
		var lat1: float = PI * float(ring + 1) / float(SPHERE_RINGS)
		for segment in range(SPHERE_SEGMENTS):
			var lon0: float = TAU * float(segment) / float(SPHERE_SEGMENTS)
			var lon1: float = TAU * float(segment + 1) / float(SPHERE_SEGMENTS)
			var p00: Vector3 = center + _sphere_point(lat0, lon0, radius)
			var p01: Vector3 = center + _sphere_point(lat0, lon1, radius)
			var p10: Vector3 = center + _sphere_point(lat1, lon0, radius)
			var p11: Vector3 = center + _sphere_point(lat1, lon1, radius)
			_add_triangle_outward(tool, p00, p01, p11, center)
			_add_triangle_outward(tool, p00, p11, p10, center)

func _sphere_point(latitude: float, longitude: float, radius: float) -> Vector3:
	return Vector3(
		radius * sin(latitude) * cos(longitude),
		radius * cos(latitude),
		radius * sin(latitude) * sin(longitude)
	)

func _add_triangle_outward(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, center: Vector3) -> void:
	var normal: Vector3 = (b - a).cross(c - a)
	if normal.length_squared() < 0.000001:
		return
	var midpoint: Vector3 = (a + b + c) / 3.0
	if normal.dot(midpoint - center) < 0.0:
		var swap: Vector3 = b
		b = c
		c = swap
	_add_triangle(tool, a, b, c)
