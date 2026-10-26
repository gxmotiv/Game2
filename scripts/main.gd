extends Node

var _hacked_network_nodes: int = 0
var _network_nodes_total: int = 0

func _enter_tree() -> void:
	# A few Android/debug scene instantiations have returned UI nodes without
	# their serialized script instance. Ensure PauseMenu's script is present
	# before its _ready() connects Resume/Restart/Settings/Quit buttons.
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

	# Every terminal and city device shares the same hack-result contract. This
	# gives the open district a simple network objective without extra services.
	var callback := Callable(self, "_on_network_node_hacked")
	for network_node in get_tree().get_nodes_in_group("hackable"):
		if network_node.has_signal("hack_completed"):
			_network_nodes_total += 1
			if not network_node.is_connected("hack_completed", callback):
				network_node.connect("hack_completed", callback)
	print("CITY CHECK OK: %d hackable network nodes registered." % _network_nodes_total)

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

func _on_network_node_hacked(success: bool) -> void:
	if not success:
		return
	_hacked_network_nodes = mini(_hacked_network_nodes + 1, _network_nodes_total)
	call_deferred("_refresh_network_objective")

func _refresh_network_objective() -> void:
	var objective_label: Node = get_tree().root.find_child("ObjectiveLabel", true, false)
	if objective_label == null:
		return
	if _network_nodes_total > 0 and _hacked_network_nodes >= _network_nodes_total:
		objective_label.set("text", "NOVA GRID CONTROLLED  •  ALL NETWORK NODES COMPROMISED")
	else:
		objective_label.set("text", "NETWORK BREACH: %d/%d  •  EXPLORE NOVA GRID" % [_hacked_network_nodes, _network_nodes_total])
