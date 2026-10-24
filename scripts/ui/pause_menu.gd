extends CanvasLayer
class_name PauseMenu

@onready var resume_button = $PanelContainer/ButtonContainer/ResumeButton
@onready var restart_button = $PanelContainer/ButtonContainer/RestartButton
@onready var settings_button = $PanelContainer/ButtonContainer/SettingsButton
@onready var quit_button = $PanelContainer/ButtonContainer/QuitButton
@onready var panel = $PanelContainer

func _ready() -> void:
	visible = false
	
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func show_menu() -> void:
	visible = true
	get_tree().paused = true

func hide_menu() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	hide_menu()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
	hide_menu()

func _on_settings_pressed() -> void:
	# TODO: Open settings menu
	print("Settings pressed")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		if visible:
			hide_menu()
		else:
			show_menu()