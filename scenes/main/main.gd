extends Node

class_name MainScene

@onready var world = $World
@onready var player = $Player
@onready var guard = $Guard
@onready var terminal = $Terminal
@onready var mobile_hud = $MobileHUD
@onready var hacking_puzzle = $HackingPuzzle
@onready var systems = $Systems

func _ready() -> void:
	# Connect signals
	if player:
		player.connect("died", _on_player_died)
	
	if terminal:
		terminal.connect("hack_started", _on_hack_started)
		terminal.connect("hack_completed", _on_hack_completed)
	
	if hacking_puzzle:
		hacking_puzzle.connect("puzzle_completed", _on_puzzle_completed)
	
	# Initialize systems
	if Systems:
		pass # Systems are autoloads

func _on_player_died() -> void:
	print("Player died!")
	# TODO: Show game over screen, respawn at checkpoint

func _on_hack_started() -> void:
	print("Hack started")
	if mobile_hud:
		mobile_hud.set_interact_button_visible(false)

func _on_hack_completed(success: bool) -> void:
	print("Hack completed: ", success)
	if mobile_hud:
		mobile_hud.set_interact_button_visible(true)

func _on_puzzle_completed(success: bool) -> void:
	if terminal:
		terminal.end_hack(success)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_tree().paused = not get_tree().paused