extends CanvasLayer
class_name MinigameUI

@onready var timer_label = $TimerLabel
@onready var hint_button = $ButtonContainer/HintButton
@onready var exit_button = $ButtonContainer/ExitButton

signal hint_requested()
signal exit_requested()

func _ready() -> void:
	visible = false
	hint_button.pressed.connect(_on_hint_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func show_ui() -> void:
	visible = true

func hide_ui() -> void:
	visible = false

func update_timer(seconds: float) -> void:
	if timer_label:
		timer_label.text = "%ds" % int(ceil(seconds))
		if seconds <= 10.0:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))

func set_hints_remaining(count: int) -> void:
	if hint_button:
		hint_button.disabled = count <= 0
		hint_button.text = "HINT (%d)" % count

func _on_hint_pressed() -> void:
	hint_requested.emit()

func _on_exit_pressed() -> void:
	exit_requested.emit()