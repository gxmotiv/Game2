extends Node

func _ready() -> void:
	# Explicitly start with all modal overlays closed. This is a safety net in
	# addition to each overlay's own _ready() setup, and prevents a visible
	# pause/puzzle layer from covering the gameplay on first launch.
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

	# The instanced training room is renamed to "World" in main.tscn, so
	# search for its security light directly rather than looking for a nested
	# node named "TestRoom". Continue startup checks even if the optional link
	# is missing.
	var security_light := world.find_child("SecurityLight", true, false) as Node3D
	if security_light != null and terminal.has_method("set"):
		terminal.set("linked_security_device", security_light)
	else:
		push_warning("SecurityLight was not found; terminal can still be hacked, but it cannot disable the light.")

	# Lightweight startup assertions: if any of these fail, the CI smoke test
	# can catch the broken scene before an APK is handed to the phone tester.
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

	if get_node_or_null("PauseMenu") == null:
		push_error("STARTUP CHECK FAILED: pause menu is missing.")
