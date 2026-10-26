extends StaticBody3D
class_name Terminal

signal player_entered
signal player_exited
signal hack_started
signal hack_completed(success: bool)

@export_group("Interaction")
@export var interaction_range: float = 2.0
@export var cooldown_time: float = 1.0

@export_group("References")
@export var screen_mesh: MeshInstance3D
@export var status_light: MeshInstance3D
@export var status_light_glow: OmniLight3D
@export var prompt_label: Label3D

@export_group("Security Link")
@export var linked_security_device: Node3D

var _player_in_range: bool = false
var _player: Node3D
var _hacking_active: bool = false
var _cooldown_timer: float = 0.0
var _is_hacked: bool = false
var _original_light_color: Color
var _original_emission: Color
var _interaction_area: Area3D

func _ready() -> void:
	_interaction_area = get_node("InteractionArea")
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)
	
	if prompt_label:
		prompt_label.visible = false
	
	if status_light and status_light.material_override:
		_original_light_color = status_light.material_override.albedo_color
		# Set initial emission color (green for active terminal)
		status_light.material_override.emission = Color(0.2, 0.8, 0.4, 1.0)
		_original_emission = status_light.material_override.emission
	
	if status_light_glow:
		status_light_glow.light_color = Color(1.0, 0.3, 0.1, 1.0)
	
	# Add to "hackable" group for easy finding
	add_to_group("hackable")

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
	
	if prompt_label and _player:
		# Make prompt face camera
		var camera = get_viewport().get_camera_3d()
		if camera:
			prompt_label.look_at(camera.global_position, Vector3.UP)
			prompt_label.rotate_y(PI)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("is_player") or body.name == "Player":
		_player = body
		_player_in_range = true
		if prompt_label and not _is_hacked and not _hacking_active:
			prompt_label.visible = true
		player_entered.emit()

func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player_in_range = false
		_player = null
		if prompt_label:
			prompt_label.visible = false
		player_exited.emit()

func try_start_hack() -> bool:
	if _is_hacked or _hacking_active or _cooldown_timer > 0.0:
		return false
	if not _player_in_range:
		return false
	
	_hacking_active = true
	if prompt_label:
		prompt_label.visible = false
	hack_started.emit()
	return true

func end_hack(success: bool) -> void:
	_hacking_active = false
	_cooldown_timer = cooldown_time
	
	if success:
		_is_hacked = true
		_on_hack_success()
	else:
		_on_hack_failure()
	
	hack_completed.emit(success)
	
	if prompt_label and _player_in_range and not _is_hacked:
		prompt_label.visible = true

func _on_hack_success() -> void:
	# Change status light to green
	if status_light and status_light.material_override:
		status_light.material_override.albedo_color = Color(0.2, 1.0, 0.2, 1.0)
		status_light.material_override.emission = Color(0.2, 1.0, 0.2, 1.0)
	
	if status_light_glow:
		status_light_glow.light_color = Color(0.2, 1.0, 0.2, 1.0)
	
	# Trigger linked security device
	if linked_security_device and linked_security_device.has_method("disable"):
		linked_security_device.disable()

func _on_hack_failure() -> void:
	# Flash red briefly
	if status_light and status_light.material_override:
		var tween = create_tween()
		tween.tween_property(status_light.material_override, "albedo_color", Color(1.0, 0.2, 0.2, 1.0), 0.1)
		tween.tween_property(status_light.material_override, "emission", Color(1.0, 0.2, 0.2, 1.0), 0.1)
		tween.tween_property(status_light.material_override, "albedo_color", Color(1.0, 0.3, 0.1, 1.0), 0.3)
		tween.tween_property(status_light.material_override, "emission", Color(1.0, 0.3, 0.1, 1.0), 0.3)

func is_hacked() -> bool:
	return _is_hacked

func is_hacking_active() -> bool:
	return _hacking_active

func get_player_in_range() -> bool:
	return _player_in_range

func reset_terminal() -> void:
	_is_hacked = false
	_hacking_active = false
	_cooldown_timer = 0.0
	
	if status_light and status_light.material_override:
		status_light.material_override.albedo_color = _original_light_color
		status_light.material_override.emission = _original_emission
	
	if status_light_glow:
		status_light_glow.light_color = Color(1.0, 0.3, 0.1, 1.0)