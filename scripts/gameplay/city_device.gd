extends StaticBody3D
class_name CityHackDevice

signal hack_completed(success: bool)

@export_enum("Traffic signal", "Security camera", "Power relay") var device_type: int = 0
@export var display_name: String = "Network device"
@export var cooldown_time: float = 0.6

var _player_in_range: bool = false
var _player: Node3D
var _hacking_active: bool = false
var _is_hacked: bool = false
var _cooldown: float = 0.0
var _visuals: Node3D
var _indicator: MeshInstance3D
var _prompt_label: Label3D

func _ready() -> void:
	add_to_group("hackable")
	_build_visuals()
	var area := get_node_or_null("InteractionArea") as Area3D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	_prompt_label = Label3D.new()
	_prompt_label.name = "DevicePrompt"
	_prompt_label.text = "%s  •  TAP INTERACT" % display_name.to_upper()
	_prompt_label.font_size = 24
	_prompt_label.outline_size = 5
	_prompt_label.modulate = Color(0.25, 1.0, 0.68, 1.0)
	_prompt_label.position = Vector3(0.0, 3.25, 0.0)
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.visible = false
	add_child(_prompt_label)

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _prompt_label and _player_in_range and is_instance_valid(_player):
		var camera := get_viewport().get_camera_3d()
		if camera:
			_prompt_label.look_at(camera.global_position, Vector3.UP)
			_prompt_label.rotate_y(PI)

func _build_visuals() -> void:
	_visuals = Node3D.new()
	_visuals.name = "Visuals"
	add_child(_visuals)
	var dark := _make_material(Color(0.045, 0.07, 0.09))
	var metal := _make_material(Color(0.20, 0.25, 0.29))
	var status_color := Color(0.20, 0.95, 0.48) if device_type == 0 else Color(0.24, 0.72, 1.0)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.07
	pole.bottom_radius = 0.10
	pole.height = 2.25
	_add_visual(pole, Vector3(0, 1.13, 0), metal, "Pole")

	match device_type:
		0:
			var housing := BoxMesh.new()
			housing.size = Vector3(0.48, 0.9, 0.36)
			_add_visual(housing, Vector3(0, 2.05, 0), dark, "SignalHousing")
			var lamp := SphereMesh.new()
			lamp.radius = 0.12
			lamp.height = 0.24
			_add_visual(lamp, Vector3(0, 2.32, -0.205), _make_material(Color(1.0, 0.22, 0.20), Color(1.0, 0.12, 0.1), 0.35), "RedLamp")
			_indicator = _add_visual(lamp, Vector3(0, 2.05, -0.205), _make_material(Color(0.95, 0.68, 0.14), Color(0.9, 0.55, 0.08), 0.25), "AmberLamp")
			_add_visual(lamp, Vector3(0, 1.78, -0.205), _make_material(Color(0.12, 0.45, 0.25)), "GreenLamp")
		1:
			var camera_body := BoxMesh.new()
			camera_body.size = Vector3(0.78, 0.30, 0.34)
			_add_visual(camera_body, Vector3(0, 2.28, -0.13), dark, "CameraHousing")
			var lens := SphereMesh.new()
			lens.radius = 0.11
			lens.height = 0.22
			_indicator = _add_visual(lens, Vector3(0, 2.28, -0.34), _make_material(Color(1.0, 0.20, 0.18), Color(1.0, 0.10, 0.08), 0.35), "CameraLens")
		_:
			var cabinet := BoxMesh.new()
			cabinet.size = Vector3(0.88, 1.35, 0.68)
			_add_visual(cabinet, Vector3(0, 0.95, 0), metal, "RelayCabinet")
			var screen := BoxMesh.new()
			screen.size = Vector3(0.54, 0.42, 0.07)
			_indicator = _add_visual(screen, Vector3(0, 1.15, -0.365), _make_material(Color(0.15, 0.75, 1.0), Color(0.1, 0.65, 1.0), 0.4), "RelayScreen")

func _add_visual(mesh: Mesh, local_position: Vector3, material: Material, node_name: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	_visuals.add_child(instance)
	return instance

func _make_material(color: Color, glow_color: Color = Color.BLACK, glow_strength: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if glow_strength > 0.0:
		material.emission_enabled = true
		material.emission = glow_color
		material.emission_energy_multiplier = glow_strength
	return material

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player = body
		_player_in_range = true
		if _prompt_label and not _is_hacked and not _hacking_active:
			_prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player = null
		_player_in_range = false
		if _prompt_label:
			_prompt_label.visible = false

func get_player_in_range() -> bool:
	return _player_in_range

func try_start_hack() -> bool:
	if _is_hacked or _hacking_active or _cooldown > 0.0 or not _player_in_range:
		return false
	_hacking_active = true
	if _prompt_label:
		_prompt_label.visible = false
	return true

func end_hack(success: bool) -> void:
	if not _hacking_active:
		return
	_hacking_active = false
	_cooldown = cooldown_time
	if success:
		_is_hacked = true
		_apply_hack_effect()
	elif _prompt_label and _player_in_range:
		_prompt_label.visible = true
	hack_completed.emit(success)

func _apply_hack_effect() -> void:
	if _prompt_label:
		_prompt_label.visible = false
	if device_type == 1:
		# Cameras are visually disabled; the interaction area stays alive so
		# mission logic and save systems can still inspect this network node.
		_visuals.visible = false
	elif _indicator:
		_indicator.material_override = _make_material(Color(0.20, 1.0, 0.50), Color(0.12, 1.0, 0.42), 0.65)

func is_hacked() -> bool:
	return _is_hacked

func is_hacking_active() -> bool:
	return _hacking_active

func reset_device() -> void:
	_is_hacked = false
	_hacking_active = false
	_cooldown = 0.0
	if _visuals:
		_visuals.queue_free()
	_build_visuals()
	if _prompt_label:
		_prompt_label.visible = _player_in_range
