extends Node
class_name MainScene

@onready var world: Node = $World
@onready var player: Node = $Player
@onready var guard: Node = $Guard
@onready var terminal: Node = $Terminal
@onready var mobile_hud: Node = $MobileHUD
@onready var hacking_puzzle: Node = $HackingPuzzle

func _ready() -> void:
	# This controller must stay alive so Escape or the mobile Pause button can resume.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for gameplay_node in [world, player, guard, terminal, hacking_puzzle]:
		if is_instance_valid(gameplay_node):
			gameplay_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	if is_instance_valid(mobile_hud):
		mobile_hud.process_mode = Node.PROCESS_MODE_ALWAYS

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
	print("Player died!")
	# TODO: Add a dedicated checkpoint/game-over screen in a later gameplay pass.

func _on_hack_started() -> void:
	if is_instance_valid(mobile_hud) and mobile_hud.has_method("set_interact_button_visible"):
		mobile_hud.call("set_interact_button_visible", false)

func _on_hack_completed(_success: bool) -> void:
	if is_instance_valid(mobile_hud) and mobile_hud.has_method("set_interact_button_visible"):
		mobile_hud.call("set_interact_button_visible", true)

func _on_puzzle_completed(success: bool) -> void:
	if is_instance_valid(terminal) and terminal.has_method("end_hack"):
		terminal.call("end_hack", success)
