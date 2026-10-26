extends Button
class_name TouchButton

@export var action_name: String = ""
@export var hold_mode: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	toggled.connect(_on_toggled)

func _on_button_down() -> void:
	match action_name:
		"interact":
			# Direct callback is reliable on Android; don't depend on keyboard InputMap.
			var player := get_tree().get_first_node_in_group("player")
			if player and player.has_method("_try_interact_from_hud"):
				player.call("_try_interact_from_hud")
		"sprint":
			InputManager.set_touch_sprint(true)
		"pause":
			var pause_menu := get_tree().root.find_child("PauseMenu", true, false)
			if pause_menu:
				if pause_menu.visible:
					pause_menu.call("hide_menu")
				else:
					pause_menu.call("show_menu")

func _on_button_up() -> void:
	if action_name == "sprint":
		InputManager.set_touch_sprint(false)

func _on_toggled(button_pressed: bool) -> void:
	if action_name == "crouch":
		InputManager.set_touch_crouch(button_pressed)
