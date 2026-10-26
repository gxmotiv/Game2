extends SceneTree

func _initialize() -> void:
	call_deferred("_run_gameplay_smoke_test")

func _fail(message: String) -> void:
	push_error("GAMEPLAY_SMOKE_FAIL: " + message)
	quit(1)

func _run_gameplay_smoke_test() -> void:
	var packed_scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	if packed_scene == null:
		_fail("Could not load the main scene.")
		return

	var game: Node = packed_scene.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame

	var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
	var terminal: Node3D = game.get_node_or_null("Terminal") as Node3D
	var puzzle: Node = game.get_node_or_null("HackingPuzzle")
	var input_manager: Node = root.get_node_or_null("InputManager")
	if player == null or terminal == null or puzzle == null or input_manager == null:
		_fail("Main scene is missing Player, Terminal, HackingPuzzle, or InputManager.")
		return

	# Exercise the same virtual movement vector used by the mobile joystick.
	var start_position: Vector3 = player.global_position
	input_manager.call("set_touch_move_vector", Vector2(0.0, -1.0))
	for frame_index in range(30):
		await physics_frame
	input_manager.call("set_touch_move_vector", Vector2.ZERO)
	if player.global_position.z >= start_position.z - 0.35:
		_fail("Virtual joystick input did not move the player forward.")
		return
	print("GAMEPLAY CHECK OK: virtual movement moves the player.")

	# Put the player in front of the terminal and allow Area3D overlaps to update.
	player.global_position = Vector3(0.0, 1.0, -4.0)
	for frame_index in range(4):
		await physics_frame
	if not bool(terminal.call("get_player_in_range")):
		_fail("Terminal InteractionArea did not detect the nearby player.")
		return

	player.call("_check_interaction", 0.1)
	if player.get("_current_interactable") != terminal:
		_fail("Player did not select the nearby terminal for interaction.")
		return

	player.call("_try_interact_from_hud")
	await process_frame
	if not bool(terminal.call("is_hacking_active")) or not bool(puzzle.call("is_puzzle_active")) or not puzzle.visible:
		_fail("INTERACT did not open the hacking puzzle.")
		return
	print("GAMEPLAY CHECK OK: terminal interaction opens the hacking puzzle.")

	# The puzzle generator guarantees a horizontal route across the middle row.
	# Rotate each of its straight pipe tiles until it connects left-to-right.
	var grid_size: int = int(puzzle.get("grid_size"))
	var route_row: int = int((puzzle.get("_start_pos") as Vector2i).y)
	var rotations: Array = puzzle.get("_node_rotations")
	for column in range(1, grid_size - 1):
		var node_index: int = route_row * grid_size + column
		var attempts: int = 0
		while int(rotations[node_index]) % 2 == 0 and attempts < 4:
			puzzle.call("_rotate_node", node_index)
			attempts += 1

	await create_timer(1.7).timeout
	if not bool(terminal.call("is_hacked")):
		_fail("Solving the guaranteed circuit route did not complete the hack.")
		return
	if puzzle.visible or bool(puzzle.call("is_puzzle_active")):
		_fail("Hacking puzzle did not close after success.")
		return

	print("GAMEPLAY CHECK OK: circuit puzzle completes and terminal records the hack.")
	print("GAMEPLAY SMOKE TEST PASSED.")
	quit(0)
