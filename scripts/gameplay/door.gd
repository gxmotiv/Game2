extends StaticBody3D
class_name Door

signal player_entered
signal player_exited
signal opened()
signal closed()

@export var open_speed: float = 2.0
@export var interaction_range: float = 2.0

var _is_open: bool = false
var _target_rotation: float = 0.0
var _player_in_range: bool = false

func _ready() -> void:
	add_to_group("hackable")

func _physics_process(delta: float) -> void:
	if _is_open:
		rotation.y = lerp(rotation.y, _target_rotation, open_speed * delta)
		if abs(rotation.y - _target_rotation) < 0.01:
			rotation.y = _target_rotation
	elif rotation.y != 0.0:
		rotation.y = lerp(rotation.y, 0.0, open_speed * delta)
		if abs(rotation.y) < 0.01:
			rotation.y = 0.0

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.has_method("is_player") or body.name == "Player":
		_player_in_range = true
		player_entered.emit()

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body == get_parent().get_node("Player"):
		_player_in_range = false
		player_exited.emit()

func try_open() -> bool:
	if not _is_open and _player_in_range:
		_is_open = true
		_target_rotation = PI / 2
		opened.emit()
		return true
	return false

func try_close() -> bool:
	if _is_open:
		_is_open = false
		_target_rotation = 0.0
		closed.emit()
		return true
	return false

func is_open() -> bool:
	return _is_open

func get_interaction_prompt() -> String:
	if _is_open:
		return "Press [E] to Close"
	return "Press [E] to Open"