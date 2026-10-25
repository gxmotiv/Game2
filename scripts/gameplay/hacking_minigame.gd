extends Node
class_name HackingMinigame

signal puzzle_started(terminal_id: String)
signal puzzle_completed(success: bool, terminal_id: String)

@export var puzzle_scene: PackedScene = preload("res://scenes/ui/minigame_circuit.tscn")

var _current_puzzle: CanvasLayer
var _current_terminal: String = ""

func start_minigame(terminal_id: String) -> void:
	_current_terminal = terminal_id
	
	if not _current_puzzle or not _current_puzzle.is_inside_tree():
		_current_puzzle = puzzle_scene.instantiate()
		get_tree().root.add_child(_current_puzzle)
	
	if _current_puzzle and _current_puzzle.has_method("start_puzzle"):
		_current_puzzle.start_puzzle(terminal_id)
		_current_puzzle.puzzle_completed.connect(_on_puzzle_completed)
	
	puzzle_started.emit(terminal_id)

func _on_puzzle_completed(success: bool) -> void:
	if _current_puzzle:
		_current_puzzle.puzzle_completed.disconnect(_on_puzzle_completed)
	
	puzzle_completed.emit(success, _current_terminal)
	_current_terminal = ""

func cancel_minigame() -> void:
	if _current_puzzle and _current_puzzle.is_inside_tree():
		_current_puzzle.queue_free()
		_current_puzzle = null
	_current_terminal = ""