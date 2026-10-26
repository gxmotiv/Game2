extends CanvasLayer
class_name MobileHUD

@onready var interact_button: Button = $ButtonContainer/InteractButton

func set_interact_button_visible(value: bool) -> void:
	if is_instance_valid(interact_button):
		interact_button.visible = value
