extends StaticBody3D
class_name Vent

signal player_entered
signal player_exited
signal entered_vent()
signal exited_vent()

@export var interaction_range: float = 2.0
@export var crawl_speed_multiplier: float = 0.5

var _player_in_range: bool = false
var _is_inside: bool = false
var _original_camera_distance: float
var _original_camera_height: float

func _ready() -> void:
	add_to_group("hackable")

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.has_method("is_player") or body.name == "Player":
		_player_in_range = true
		player_entered.emit()

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body == get_parent().get_node("Player"):
		_player_in_range = false
		player_exited.emit()

func try_enter(player: Node) -> bool:
	if not _is_inside and _player_in_range:
		_is_inside = true
		# Signal player to enter crawl mode
		entered_vent.emit()
		return true
	return false

func try_exit(player: Node) -> bool:
	if _is_inside:
		_is_inside = false
		exited_vent.emit()
		return true
	return false

func is_inside() -> bool:
	return _is_inside

func get_interaction_prompt() -> String:
	if _is_inside:
		return "Press [E] to Exit Vent"
	return "Press [E] to Enter Vent"