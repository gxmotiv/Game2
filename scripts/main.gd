extends Node

func _ready() -> void:
	var terminal := get_node_or_null("Terminal")
	var world := get_node_or_null("World")
	if terminal == null or world == null:
		push_warning("Main scene is missing Terminal or World; check main.tscn scene instances.")
		return

	var test_room := world.find_child("TestRoom", true, false)
	if test_room == null:
		push_warning("Training room was not found; the security light link is unavailable.")
		return

	var security_light := test_room.get_node_or_null("SecurityLight")
	if security_light and terminal.has_method("set"):
		terminal.set("linked_security_device", security_light)

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
