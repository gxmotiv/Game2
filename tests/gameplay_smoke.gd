extends SceneTree

func _initialize() -> void:
	call_deferred("_run_gameplay_smoke_test")

func _fail(message: String) -> void:
	push_error("GAMEPLAY_SMOKE_FAIL: " + message)
	quit(1)

func _joystick_press(joystick: Control, base: Control, direction: Vector2, touch_index: int) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = touch_index
	event.pressed = true
	var local_point: Vector2 = base.size * 0.5 + direction.normalized() * 48.0
	event.position = base.get_global_transform_with_canvas() * local_point
	joystick.call("handle_touch_event", event)
	return event

func _joystick_release(joystick: Control, event: InputEventScreenTouch) -> void:
	var release := InputEventScreenTouch.new()
	release.index = event.index
	release.pressed = false
	release.position = event.position
	joystick.call("handle_touch_event", release)

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
	var guard: CharacterBody3D = game.get_node_or_null("Guard") as CharacterBody3D
	var puzzle: CanvasLayer = game.get_node_or_null("HackingPuzzle") as CanvasLayer
	var input_manager: Node = root.get_node_or_null("InputManager")
	var mobile_hud: Node = game.get_node_or_null("MobileHUD")
	if player == null or terminal == null or guard == null or puzzle == null or input_manager == null or mobile_hud == null:
		_fail("Main scene is missing Player, Terminal, Guard, HackingPuzzle, InputManager, or MobileHUD.")
		return

	# Phase 3 regression checks: three route-driven guards, RayCast3D vision,
	# a half-range crouch modifier, and physical cover blocking sight.
	var guards := get_nodes_in_group("guards")
	if guards.size() != 3:
		_fail("Expected exactly three city guards, found " + str(guards.size()) + ".")
		return
	for guard_node in guards:
		if not guard_node is CharacterBody3D:
			_fail("A guard is not a CharacterBody3D.")
			return
		if not guard_node.get_node_or_null("VisionRay") is RayCast3D:
			_fail("A guard is missing its VisionRay RayCast3D.")
			return
		if not guard_node.get_node_or_null("AwarenessLabel") is Label3D:
			_fail("A guard is missing its overhead awareness indicator.")
			return
		var patrol_route: Array = guard_node.call("get_patrol_points")
		if patrol_route.size() < 4:
			_fail("A guard does not have four patrol waypoints.")
			return
	print("STEALTH CHECK OK: three guards have four waypoints, RayCast3D vision, and overhead awareness labels.")

	# Align the central guard with the player for deterministic vision tests.
	guard.global_position = Vector3(0.0, 1.0, 4.0)
	guard.rotation = Vector3.ZERO
	guard.set("_target_position", Vector3(0.0, 1.0, 0.0))
	player.global_position = Vector3(0.0, 1.0, 0.0)
	player.set("_is_crouching", false)
	if not bool(guard.call("can_see_player_now")):
		_fail("An unobstructed player directly in front of a guard was not detected.")
		return
	var standing_detection_range: float = float(guard.call("get_detection_range_for_player", player))
	player.set("_is_crouching", true)
	var crouching_detection_range: float = float(guard.call("get_detection_range_for_player", player))
	if not is_equal_approx(standing_detection_range, 15.0) or not is_equal_approx(crouching_detection_range, 7.5):
		_fail("Crouching did not halve the guard's detection radius.")
		return
	player.global_position = Vector3(0.0, 1.0, -4.0)
	if bool(guard.call("can_see_player_now")):
		_fail("A crouching player outside the halved detection radius was still visible.")
		return
	player.global_position = Vector3(0.0, 1.0, 0.0)
	if not bool(guard.call("can_see_player_now")):
		_fail("A crouching player inside the reduced detection radius was not visible.")
		return
	player.set("_is_crouching", false)
	print("STEALTH CHECK OK: vision cone detects in front and crouching halves range from 15m to 7.5m.")

	# A real collision body between guard and player must block the RayCast3D.
	var cover_body := StaticBody3D.new()
	cover_body.name = "StealthTestCover"
	cover_body.position = Vector3(0.0, 1.4, 2.0)
	var cover_shape := CollisionShape3D.new()
	var cover_box := BoxShape3D.new()
	cover_box.size = Vector3(2.0, 2.8, 0.5)
	cover_shape.shape = cover_box
	cover_body.add_child(cover_shape)
	game.get_node("World").add_child(cover_body)
	await physics_frame
	if bool(guard.call("can_see_player_now")):
		_fail("A solid cover wall did not block the guard's vision ray.")
		return
	cover_body.queue_free()
	await physics_frame
	# Restore the guard to its normal route before the existing movement tests.
	guard.global_position = Vector3(-5.0, 1.0, -5.0)
	guard.rotation = Vector3.ZERO
	guard.velocity = Vector3.ZERO
	guard.set("_target_position", Vector3(-8.0, 1.0, -8.0))
	print("STEALTH CHECK OK: physical cover blocks line of sight.")

	var joystick: Control = mobile_hud.get_node("JoystickContainer/VirtualJoystick") as Control
	var joystick_script: Script = joystick.get_script() as Script
	print("JOYSTICK_DIAGNOSTIC: script=", joystick_script.resource_path if joystick_script != null else "NULL",
		" has_handle=", joystick.has_method("handle_touch_event"),
		" has_input=", joystick.has_method("_input"))
	if joystick_script == null or not joystick.has_method("handle_touch_event"):
		_fail("VirtualJoystick script is not attached or its public touch handler is unavailable.")
		return
	var base: Control = joystick.get_node("Base")
	var interact_button: Button = mobile_hud.get_node("ButtonContainer/InteractButton")
	var sprint_button: Button = mobile_hud.get_node("ButtonContainer/SprintButton")
	var crouch_button: Button = mobile_hud.get_node("ButtonContainer/CrouchButton")
	var pause_button: Button = mobile_hud.get_node("PauseButton")
	var pause_menu: Node = game.get_node_or_null("PauseMenu")
	if pause_menu == null:
		_fail("Pause menu node is missing.")
		return

	# The joystick must translate real touch coordinates into a movement vector.
	var camera_before_joystick: float = float(player.get("_camera_yaw"))
	var start_position: Vector3 = player.global_position
	var forward_touch: InputEventScreenTouch = _joystick_press(joystick, base, Vector2(0, -1), 11)
	var reported_input: Vector2 = input_manager.call("get_touch_move_vector")
	if reported_input.y > -0.4:
		_fail("Joystick forward touch did not produce negative Y movement input: " + str(reported_input))
		return
	for frame_index in range(24):
		await physics_frame
	_joystick_release(joystick, forward_touch)
	input_manager.call("set_touch_move_vector", Vector2.ZERO)
	if player.global_position.z >= start_position.z - 0.2:
		_fail("Real joystick touch/drag did not move the player forward.")
		return
	if not is_zero_approx(float(player.get("_camera_yaw")) - camera_before_joystick):
		_fail("Left joystick input unexpectedly rotated the camera.")
		return
	print("GAMEPLAY CHECK OK: real joystick touch moves the player forward without rotating the camera.")

	# Check all four directional vectors and physical movement, including strafe.
	var movement_cases: Array[Dictionary] = [
		{"label":"backward","direction":Vector2(0, 1),"axis":"z","sign":1.0},
		{"label":"right strafe","direction":Vector2(1, 0),"axis":"x","sign":1.0},
		{"label":"left strafe","direction":Vector2(-1, 0),"axis":"x","sign":-1.0}
	]
	for case in movement_cases:
		player.global_position = Vector3(0.0, 1.0, 0.0)
		player.velocity = Vector3.ZERO
		player.set("_target_velocity", Vector3.ZERO)
		await physics_frame
		var start: Vector3 = player.global_position
		var touch: InputEventScreenTouch = _joystick_press(joystick, base, case["direction"], 12)
		var vector: Vector2 = input_manager.call("get_touch_move_vector")
		if case["axis"] == "x" and signf(vector.x) != signf(float(case["sign"])):
			_fail("Joystick " + str(case["label"]) + " input has the wrong horizontal direction: " + str(vector))
			return
		if case["axis"] == "z" and signf(vector.y) != signf(float(case["sign"])):
			_fail("Joystick " + str(case["label"]) + " input has the wrong vertical direction: " + str(vector))
			return
		for frame_index in range(24):
			await physics_frame
		_joystick_release(joystick, touch)
		input_manager.call("set_touch_move_vector", Vector2.ZERO)
		var delta_position: Vector3 = player.global_position - start
		if case["axis"] == "x" and delta_position.x * float(case["sign"]) < 0.2:
			_fail("Joystick " + str(case["label"]) + " did not move the player in the correct direction: " + str(delta_position))
			return
		if case["axis"] == "z" and delta_position.z * float(case["sign"]) < 0.2:
			_fail("Joystick " + str(case["label"]) + " did not move the player in the correct direction: " + str(delta_position))
			return
	print("GAMEPLAY CHECK OK: forward, backward, left, and right joystick movement all work.")

	# Test crouch and sprint button state using the same handlers bound to actual GUI buttons.
	crouch_button.set_pressed_no_signal(true)
	crouch_button.emit_signal("toggled", true)
	await physics_frame
	print("BUTTON_DIAGNOSTIC: crouch_input=", input_manager.call("is_touch_crouching"),
		" player_crouching=", player.get("_is_crouching"),
		" last_touch_crouch=", player.get("_last_touch_crouch"),
		" button_script=", crouch_button.get_script().resource_path if crouch_button.get_script() != null else "NULL",
		" signal_connected=", crouch_button.is_connected("toggled", Callable(crouch_button, "_on_toggled")))
	if not bool(input_manager.call("is_touch_crouching")) or not bool(player.get("_is_crouching")):
		_fail("CROUCH button did not activate crouch.")
		return
	crouch_button.set_pressed_no_signal(false)
	crouch_button.emit_signal("toggled", false)
	await physics_frame
	if bool(input_manager.call("is_touch_crouching")) or bool(player.get("_is_crouching")):
		_fail("CROUCH button did not release crouch.")
		return

	sprint_button.set_pressed_no_signal(true)
	sprint_button.emit_signal("toggled", true)
	if not bool(input_manager.call("is_touch_sprinting")):
		_fail("SPRINT button did not enable sprint.")
		return
	sprint_button.emit_signal("pressed")
	if not bool(input_manager.call("is_touch_sprinting")):
		_fail("SPRINT tap handler accidentally cancelled sprint.")
		return
	sprint_button.set_pressed_no_signal(false)
	sprint_button.emit_signal("toggled", false)
	if bool(input_manager.call("is_touch_sprinting")):
		_fail("SPRINT button did not turn sprint off.")
		return
	print("GAMEPLAY CHECK OK: CROUCH and SPRINT buttons toggle correctly.")

	# Pause should stop the game, show the overlay, and resume through the menu.
	print("PAUSE_DIAGNOSTIC_BEFORE: action=", pause_button.get("action_name"),
		" button_script=", pause_button.get_script().resource_path if pause_button.get_script() != null else "NULL",
		" handler_connected=", pause_button.is_connected("pressed", Callable(pause_button, "_on_button_pressed")),
		" pause_script=", pause_menu.get_script().resource_path if pause_menu.get_script() != null else "NULL",
		" has_show=", pause_menu.has_method("show_menu"),
		" has_hide=", pause_menu.has_method("hide_menu"),
		" paused_before=", paused,
		" visible_before=", pause_menu.get("visible"))
	pause_button.emit_signal("pressed")
	print("PAUSE_DIAGNOSTIC_AFTER: action=", pause_button.get("action_name"),
		" paused_after=", paused,
		" visible_after=", pause_menu.get("visible"))
	if not paused or not bool(pause_menu.get("visible")):
		_fail("PAUSE button did not pause the tree and show the pause menu.")
		return
	pause_menu.call("hide_menu")
	if paused or bool(pause_menu.get("visible")):
		_fail("RESUME did not unpause and hide the pause menu.")
		return
	print("GAMEPLAY CHECK OK: PAUSE and RESUME work.")

	# Camera look must ignore touches over the bottom button row, not just the joystick.
	var viewport_size: Vector2 = player.get_viewport().get_visible_rect().size
	var camera_yaw_before_buttons: float = float(player.get("_camera_yaw"))
	var bottom_touch := InputEventScreenTouch.new()
	bottom_touch.index = 23
	bottom_touch.pressed = true
	bottom_touch.position = Vector2(viewport_size.x * 0.75, viewport_size.y - 170.0)
	player.call("handle_camera_touch_event", bottom_touch)
	var bottom_drag := InputEventScreenDrag.new()
	bottom_drag.index = 23
	bottom_drag.position = bottom_touch.position + Vector2(100.0, -10.0)
	bottom_drag.relative = Vector2(100.0, -10.0)
	player.call("handle_camera_touch_event", bottom_drag)
	if not is_zero_approx(float(player.get("_camera_yaw")) - camera_yaw_before_buttons):
		_fail("Dragging a side action button area rotated the camera.")
		return
	print("GAMEPLAY CHECK OK: action-button gestures do not rotate the camera.")

	# Guard light/cone must not tint the player's entire camera view.
	var cone: Node3D = guard.get_node_or_null("VisionCone") as Node3D
	if cone != null and cone.visible:
		_fail("Guard vision cone is visible and can tint the mobile camera.")
		return

	# Move into the terminal trigger and invoke the real INTERACT button handler.
	player.global_position = Vector3(0.0, 1.0, -4.0)
	player.velocity = Vector3.ZERO
	player.set("_target_velocity", Vector3.ZERO)
	for frame_index in range(4):
		await physics_frame
	if not bool(terminal.call("get_player_in_range")):
		_fail("Terminal InteractionArea did not detect the nearby player.")
		return

	player.call("_check_interaction", 0.1)
	interact_button.emit_signal("pressed")
	await process_frame
	if not bool(terminal.call("is_hacking_active")) or not bool(puzzle.call("is_puzzle_active")) or not puzzle.visible:
		_fail("INTERACT button did not open the hacking puzzle.")
		return
	print("GAMEPLAY CHECK OK: INTERACT opens the hacking puzzle.")

	# Exercise the actual TextureButton pressed signal used by touch input.
	# Put a harmless test pipe off the guaranteed route so this cannot finish the puzzle.
	var test_index: int = 0
	var puzzle_nodes: Array = puzzle.get("_nodes")
	var puzzle_rotations: Array = puzzle.get("_node_rotations")
	puzzle_nodes[test_index] = 1 # STRAIGHT
	puzzle_rotations[test_index] = 0
	puzzle.call("_update_button_visual", test_index)
	var puzzle_grid: GridContainer = puzzle.get_node("PuzzleContainer/GridContainer") as GridContainer
	var test_button: TextureButton = puzzle_grid.get_child(test_index) as TextureButton
	var rotation_before: int = int(puzzle_rotations[test_index])
	var texture_cache_before: int = (puzzle.get("_texture_cache") as Dictionary).size()
	test_button.emit_signal("pressed")
	if int(puzzle_rotations[test_index]) != (rotation_before + 1) % 4:
		_fail("Puzzle tile pressed signal did not rotate the pipe immediately.")
		return
	for tap_index in range(4):
		test_button.emit_signal("pressed")
	if (puzzle.get("_texture_cache") as Dictionary).size() != texture_cache_before:
		_fail("Puzzle tap regenerated textures instead of reusing the cache.")
		return
	print("GAMEPLAY CHECK OK: puzzle button taps rotate immediately and reuse cached textures.")

	# Solve the generated straight route to validate end-to-end hacking.
	var grid_size: int = int(puzzle.get("grid_size"))
	var start_grid_position: Vector2i = puzzle.get("_start_pos")
	var route_row: int = start_grid_position.y
	var rotations: Array = puzzle.get("_node_rotations")
	for column in range(1, grid_size - 1):
		var node_index: int = route_row * grid_size + column
		var attempts: int = 0
		while int(rotations[node_index]) % 2 == 0 and attempts < 4:
			puzzle.call("_rotate_node", node_index)
			attempts += 1

	await create_timer(1.7).timeout
	if not bool(terminal.call("is_hacked")):
		_fail("Solving the circuit route did not complete the hack.")
		return
	if puzzle.visible or bool(puzzle.call("is_puzzle_active")):
		_fail("Hacking puzzle did not close after success.")
		return
	print("GAMEPLAY CHECK OK: circuit puzzle completes and terminal records the hack.")

	# Complete the awareness meter to verify the 100% spotted/alarm transition.
	var stealth_system: Node = root.get_node_or_null("StealthSystem")
	if stealth_system == null or not is_equal_approx(float(stealth_system.get("detection_threshold")), 100.0):
		_fail("Shared StealthSystem detection threshold is not 100 percent.")
		return
	guard.global_position = Vector3(0.0, 1.0, 4.0)
	guard.rotation = Vector3.ZERO
	guard.set("_target_position", player.global_position)
	player.global_position = Vector3(0.0, 1.0, 0.0)
	player.set("_is_crouching", false)
	guard.call("_check_player_visibility", 5.0)
	if not is_equal_approx(float(guard.call("get_suspicion")), 100.0):
		_fail("A sustained clear sighting did not fill suspicion to 100 percent.")
		return
	if int(guard.call("get_state")) != 3:
		_fail("A 100 percent suspicion level did not transition the guard to ALERT.")
		return
	var awareness_label: Label3D = guard.get_node("AwarenessLabel") as Label3D
	if awareness_label == null or not awareness_label.visible or not awareness_label.text.begins_with("!"):
		_fail("The guard awareness indicator did not switch to the red exclamation mark.")
		return
	var spotted_banner: Label = game.get_node_or_null("DetectionFeedback/SpottedBanner") as Label
	var red_flash: ColorRect = game.get_node_or_null("DetectionFeedback/RedAlertFlash") as ColorRect
	if spotted_banner == null or not spotted_banner.visible or red_flash == null:
		_fail("The 100 percent detection event did not trigger the on-screen security alarm.")
		return
	print("STEALTH CHECK OK: 100 percent suspicion triggers ALERT, red exclamation marker, and screen alarm.")
	print("GAMEPLAY SMOKE TEST PASSED.")
	quit(0)
