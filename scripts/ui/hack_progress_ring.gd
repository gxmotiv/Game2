extends Control
## Minimal circular progress indicator for the two-second contextual hack.

var _progress: float = 0.0
var _label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(144.0, 144.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.name = "ProgressText"
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.01, 0.025, 0.04, 1.0))
	_label.add_theme_constant_override("outline_size", 4)
	_label.text = "HACKING...\n0%"
	add_child(_label)
	visible = false

func set_active(active: bool) -> void:
	visible = active
	if not active:
		_progress = 0.0
	queue_redraw()

func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	if _label:
		_label.text = "HACKING...\n%d%%" % int(round(_progress * 100.0))
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.08, 0.16, 0.22, 0.95), 9.0, true)
	if _progress > 0.0:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * _progress, 48, Color(0.1, 0.88, 1.0, 1.0), 9.0, true)
