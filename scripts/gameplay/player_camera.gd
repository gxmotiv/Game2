extends Node3D
class_name PlayerCamera

@export var camera_distance: float = 8.0
@export var camera_height: float = 5.0
@export var camera_angle: float = 45.0
@export var camera_smooth_speed: float = 10.0

@onready var camera = $Camera3D

func _ready() -> void:
	_setup_camera()

func _setup_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.0
	camera.near = 0.1
	camera.far = 100.0
	
	var angle_rad = deg_to_rad(camera_angle)
	rotation = Vector3(-angle_rad, 0, 0)
	position = Vector3(0, camera_height, camera_distance)

func _physics_process(delta: float) -> void:
	if get_parent() and get_parent() is CharacterBody3D:
		var target_pos = get_parent().global_position + Vector3(0, camera_height, 0)
		global_position = global_position.lerp(target_pos, camera_smooth_speed * delta)