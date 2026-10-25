extends Node
class_name InteractionSystemClass

signal interaction_available(interactable: Node3D)
signal interaction_unavailable()
signal interaction_started(interactable: Node3D)
signal interaction_completed(interactable: Node3D, success: bool)

enum InteractionType {
	HACK = 0,
	OPEN_DOOR = 1,
	ENTER_VENT = 2,
	PICKUP = 3,
	CUSTOM = 4
}

var _current_interactable: Node3D = null
var _interaction_range: float = 2.5
var _current_type: int = InteractionType.CUSTOM

func set_interaction_range(range: float) -> void:
	_interaction_range = range

func get_interaction_range() -> float:
	return _interaction_range

func set_current_interactable(interactable: Node3D, type: int = InteractionType.CUSTOM) -> void:
	_current_interactable = interactable
	_current_type = type
	if interactable:
		interaction_available.emit(interactable)
	else:
		interaction_unavailable.emit()

func get_current_interactable() -> Node3D:
	return _current_interactable

func get_current_type() -> int:
	return _current_type

func try_interact() -> bool:
	if _current_interactable and _current_interactable.is_inside_tree():
		interaction_started.emit(_current_interactable)
		return true
	return false

func complete_interaction(success: bool) -> void:
	if _current_interactable:
		interaction_completed.emit(_current_interactable, success)
		_current_interactable = null
		_current_type = InteractionType.CUSTOM
		interaction_unavailable.emit()

func is_interacting() -> bool:
	return _current_interactable != null

func get_interaction_prompt_text() -> String:
	if not _current_interactable:
		return ""
	
	match _current_type:
		InteractionType.HACK:
			return "Press [E] to Hack"
		InteractionType.OPEN_DOOR:
			return "Press [E] to Open"
		InteractionType.ENTER_VENT:
			return "Press [E] to Enter"
		InteractionType.PICKUP:
			return "Press [E] to Pick Up"
		InteractionType.CUSTOM:
			if _current_interactable.has_method("get_interaction_prompt"):
				return _current_interactable.get_interaction_prompt()
			return "Press [E] to Interact"
	return ""