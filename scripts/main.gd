extends Node

func _ready() -> void:
	# Keep only the controller and mobile HUD alive while paused, so Pause can resume.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var world: Node = get_node_or_null("World")
	var player: Node = get_node_or_null("Player")
	var guard: Node = get_node_or_null("Guard")
	var terminal: Node = get_node_or_null("Terminal")
	var mobile_hud: Node = get_node_or_null("MobileHUD")
	var hacking_puzzle: Node = get_node_or_null("HackingPuzzle")

	for gameplay_node in [world, player, guard, terminal, hacking_puzzle]:
		if is_instance_valid(gameplay_node):
			gameplay_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	if is_instance_valid(mobile_hud):
		mobile_hud.process_mode = Node.PROCESS_MODE_ALWAYS

	# Keep the existing security-light link.
	var test_room: Node = world.find_child("TestRoom", true, false) if is_instance_valid(world) else null
	var security_light: Node = test_room.find_child("SecurityLight", true, false) if is_instance_valid(test_room) else null
	if is_instance_valid(terminal) and is_instance_valid(security_light):
		terminal.set("linked_security_device", security_light)

	if is_instance_valid(player) and player.has_signal("died") and not player.is_connected("died", _on_player_died):
		player.connect("died", _on_player_died)
	if is_instance_valid(terminal):
		if terminal.has_signal("hack_started") and not terminal.is_connected("hack_started", _on_hack_started):
			terminal.connect("hack_started", _on_hack_started)
		if terminal.has_signal("hack_completed") and not terminal.is_connected("hack_completed", _on_hack_completed):
			terminal.connect("hack_completed", _on_hack_completed)
	if is_instance_valid(hacking_puzzle) and hacking_puzzle.has_signal("puzzle_completed") and not hacking_puzzle.is_connected("puzzle_completed", _on_puzzle_completed):
		hacking_puzzle.connect("puzzle_completed", _on_puzzle_completed)

func _process(_delta: float) -> void:
	if InputManager.is_paused():
		get_tree().paused = not get_tree().paused

func _on_player_died() -> void:
	push_warning("Player died. Checkpoint/game-over UI is not implemented yet.")

func _on_hack_started() -> void:
	var mobile_hud: Node = get_node_or_null("MobileHUD")
	if is_instance_valid(mobile_hud) and mobile_hud.has_method("set_interact_button_visible"):
		mobile_hud.call("set_interact_button_visible", false)

func _on_hack_completed(_success: bool) -> void:
	var mobile_hud: Node = get_node_or_null("MobileHUD")
	if is_instance_valid(mobile_hud) and mobile_hud.has_method("set_interact_button_visible"):
		mobile_hud.call("set_interact_button_visible", true)

func _on_puzzle_completed(success: bool) -> void:
	var terminal: Node = get_node_or_null("Terminal")
	if is_instance_valid(terminal) and terminal.has_method("end_hack"):
		terminal.call("end_hack", success)
