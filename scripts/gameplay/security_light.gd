extends Node3D
class_name SecurityLight

signal disabled

@export var light_node: OmniLight3D
@export var light_mesh: MeshInstance3D
@export var disabled_color: Color = Color(0.3, 0.3, 0.3, 1.0)
@export var disabled_emission: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var active_color: Color = Color(1.0, 0.3, 0.1, 1.0)
@export var active_emission: Color = Color(1.0, 0.3, 0.1, 1.0)

var _disabled: bool = false
var _original_light_color: Color
var _original_mesh_color: Color
var _original_emission: Color

func _ready() -> void:
	if light_node:
		_original_light_color = light_node.light_color
	if light_mesh and light_mesh.material_override:
		_original_mesh_color = light_mesh.material_override.albedo_color
		if light_mesh.material_override.emission_enabled:
			_original_emission = light_mesh.material_override.emission_color
	
	# Start as active (red)
	_set_active(true)

func disable() -> void:
	if _disabled:
		return
	
	_disabled = true
	_set_active(false)
	disabled.emit()

func _set_active(active: bool) -> void:
	if light_node:
		light_node.light_color = active_color if active else disabled_color
		light_node.light_energy = 1.0 if active else 0.2
	
	if light_mesh and light_mesh.material_override:
		light_mesh.material_override.albedo_color = active_color if active else disabled_color
		if light_mesh.material_override.emission_enabled:
			light_mesh.material_override.emission_color = active_emission if active else disabled_emission
			light_mesh.material_override.emission_energy_multiplier = 2.0 if active else 0.2

func is_disabled() -> bool:
	return _disabled

func reset() -> void:
	_disabled = false
	_set_active(true)