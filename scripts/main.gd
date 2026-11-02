extends Node

var _alarm_active: bool = false
var _alarm_flash: ColorRect
var _alarm_banner: Label

func _enter_tree() -> void:
	# Recover the pause-menu script before its child controls run _ready().
	_ensure_node_script("PauseMenu", "res://scripts/ui/pause_menu.gd")

func _ensure_node_script(node_path: String, script_path: String) -> void:
	var target: Node = get_node_or_null(node_path)
	if target == null:
		return
	var desired_script: Script = load(script_path) as Script
	if desired_script == null:
		push_error("Failed to load required scene script: " + script_path)
		return
	if target.get_script() != desired_script:
		target.set_script(desired_script)

func _ready() -> void:
	# Explicitly start with all modal overlays closed.
	var hacking_overlay := get_node_or_null("HackingPuzzle")
	if hacking_overlay:
		hacking_overlay.hide()
	var pause_overlay := get_node_or_null("PauseMenu")
	if pause_overlay and pause_overlay.has_method("hide_menu"):
		pause_overlay.call("hide_menu")
	elif pause_overlay:
		pause_overlay.hide()

	if hacking_overlay and hacking_overlay.visible:
		push_error("STARTUP CHECK FAILED: hacking puzzle overlay is visible at launch.")
	if pause_overlay and pause_overlay.visible:
		push_error("STARTUP CHECK FAILED: pause menu is visible at launch.")
	else:
		print("STARTUP CHECK OK: startup overlays are hidden.")

	var terminal := get_node_or_null("Terminal")
	var world := get_node_or_null("World")
	if terminal == null or world == null:
		push_warning("Main scene is missing Terminal or World; check main.tscn scene instances.")
		return

	var security_light := world.find_child("SecurityLight", true, false) as Node3D
	if security_light != null:
		terminal.set("linked_security_device", security_light)
	else:
		push_warning("SecurityLight was not found; terminal can still be hacked, but it cannot disable the light.")

	var player := get_node_or_null("Player")
	if player == null:
		push_error("STARTUP CHECK FAILED: Player scene is missing.")
	else:
		var active_camera := player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
		if active_camera == null:
			push_error("STARTUP CHECK FAILED: gameplay camera is missing.")
		elif not active_camera.current:
			push_error("STARTUP CHECK FAILED: gameplay camera is not current.")
		else:
			print("STARTUP CHECK OK: active gameplay camera found.")

	var mobile_hud := get_node_or_null("MobileHUD")
	if mobile_hud == null or mobile_hud.find_child("VirtualJoystick", true, false) == null:
		push_error("STARTUP CHECK FAILED: mobile joystick is missing.")
	elif mobile_hud.find_child("PauseButton", true, false) == null:
		push_error("STARTUP CHECK FAILED: mobile pause button is missing.")
	else:
		print("STARTUP CHECK OK: mobile controls found.")

	var pause_menu := get_node_or_null("PauseMenu")
	if pause_menu == null:
		push_error("STARTUP CHECK FAILED: pause menu is missing.")
	elif pause_menu.visible:
		push_error("STARTUP CHECK FAILED: pause menu should be hidden on launch.")

	var hacking_puzzle := get_node_or_null("HackingPuzzle")
	if hacking_puzzle == null:
		push_error("STARTUP CHECK FAILED: hacking puzzle overlay is missing.")
	elif hacking_puzzle.visible:
		push_error("STARTUP CHECK FAILED: hacking puzzle should be hidden on launch.")

	_setup_detection_feedback()
	_connect_guard_alerts()

func _setup_detection_feedback() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DetectionFeedback"
	layer.layer = 30
	add_child(layer)

	_alarm_flash = ColorRect.new()
	_alarm_flash.name = "RedAlertFlash"
	_alarm_flash.color = Color(0.95, 0.015, 0.025, 0.0)
	_alarm_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alarm_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_alarm_flash)

	_alarm_banner = Label.new()
	_alarm_banner.name = "SpottedBanner"
	_alarm_banner.text = "SPOTTED  •  SECURITY ALERT"
	_alarm_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alarm_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_alarm_banner.add_theme_font_size_override("font_size", 30)
	_alarm_banner.add_theme_color_override("font_color", Color(1.0, 0.16, 0.12, 1.0))
	_alarm_banner.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 1.0))
	_alarm_banner.add_theme_constant_override("outline_size", 6)
	_alarm_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alarm_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_alarm_banner.offset_top = 84.0
	_alarm_banner.offset_bottom = 132.0
	_alarm_banner.visible = false
	layer.add_child(_alarm_banner)

func _connect_guard_alerts() -> void:
	var guards := get_tree().get_nodes_in_group("guards")
	if guards.size() < 3:
		push_warning("STEALTH SETUP: expected three guards, found %d." % guards.size())
	for guard_node in guards:
		var callback := Callable(self, "_on_guard_detected").bind(guard_node)
		if not guard_node.is_connected("detected_player", callback):
			guard_node.connect("detected_player", callback)
	print("STEALTH SETUP OK: connected %d guard alert signal(s)." % guards.size())

func _on_guard_detected(_player_position: Vector3, guard_node: Node) -> void:
	if _alarm_active:
		return
	_alarm_active = true

	var guard_id := int(guard_node.call("get_guard_id")) if guard_node.has_method("get_guard_id") else -1
	var globals := get_node_or_null("/root/GameGlobals")
	if globals:
		globals.emit_signal("player_detected", guard_id, 100.0)

	if _alarm_banner:
		_alarm_banner.visible = true
	if _alarm_flash:
		var tween := create_tween()
		tween.tween_property(_alarm_flash, "color:a", 0.42, 0.10)
		tween.tween_property(_alarm_flash, "color:a", 0.0, 0.48)
	print("STEALTH ALERT: player spotted by guard %d; security alarm triggered." % guard_id)
