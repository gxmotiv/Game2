extends Button
class_name TouchButton

@export var action_name: String = ""

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not pressed.is_connected(_on_button_pressed):
		pressed.connect(_on_button_pressed)
	if not toggled.is_connected(_on_toggled):
		toggled.connect(_on_toggled)
	_update_feedback()

func _on_button_pressed() -> void:
	if not is_instance_valid(InputManager):
		return

	match action_name:
		"interact":
			# Activate on a completed tap, and ask the player to refresh range first.
			var player: Node = get_tree().get_first_node_in_group("player")
			if is_instance_valid(player) and player.has_method("_try_interact_from_hud"):
				player.call("_try_interact_from_hud")
		"pause":
			var pause_menu: Node = get_tree().root.find_child("PauseMenu", true, false)
			if is_instance_valid(pause_menu):
				if bool(pause_menu.get("visible")):
					pause_menu.call("hide_menu")
			else:
				pause_menu.call("show_menu")
		"sprint":
			# Sprint is toggled on mobile: tap once to sprint, tap again to stop.
			set_pressed_no_signal(not button_pressed)
			InputManager.set_touch_sprint(button_pressed)
	_update_feedback()

func _on_toggled(is_on: bool) -> void:
	if not is_instance_valid(InputManager):
		return
	match action_name:
		"crouch":
			InputManager.set_touch_crouch(is_on)
		"sprint":
			InputManager.set_touch_sprint(is_on)
	_update_feedback()

func _update_feedback() -> void:
	if button_pressed:
		modulate = Color(0.8, 1.0, 0.8, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 0.9)
