extends CanvasLayer
class_name HackingPuzzle

signal puzzle_completed(success: bool)

@export_group("Puzzle Settings")
@export var grid_size: int = 4
@export var time_limit: float = 60.0
@export var max_hints: int = 2

@export_group("Node Types")
@export var node_type_empty: int = 0
@export var node_type_straight: int = 1
@export var node_type_corner: int = 2
@export var node_type_t_junction: int = 3
@export var node_type_cross: int = 4
@export var node_type_start: int = 5
@export var node_type_end: int = 6

@export_group("Colors")
@export var color_empty: Color = Color(0.15, 0.15, 0.2, 1.0)
@export var color_pipe: Color = Color(0.2, 0.7, 0.4, 1.0)
@export var color_connected: Color = Color(0.2, 1.0, 0.4, 1.0)
@export var color_start: Color = Color(0.2, 0.8, 1.0, 1.0)
@export var color_end: Color = Color(1.0, 0.8, 0.2, 1.0)
@export var color_error: Color = Color(1.0, 0.3, 0.3, 1.0)

@export_group("UI References")
@export var grid_container: GridContainer
@export var timer_label: Label
@export var hint_button: Button
@export var exit_button: Button

enum NodeType {
	EMPTY = 0,
	STRAIGHT = 1,
	CORNER = 2,
	T_JUNCTION = 3,
	CROSS = 4,
	START = 5,
	END = 6
}

enum Direction {
	UP = 0,
	RIGHT = 1,
	DOWN = 2,
	LEFT = 3
}

const DIR_VECTORS = {
	Direction.UP: Vector2i(0, -1),
	Direction.RIGHT: Vector2i(1, 0),
	Direction.DOWN: Vector2i(0, 1),
	Direction.LEFT: Vector2i(-1, 0)
}

const CONNECTIONS = {
	NodeType.EMPTY: [],
	NodeType.STRAIGHT: [Direction.UP, Direction.DOWN],
	NodeType.CORNER: [Direction.UP, Direction.RIGHT],
	NodeType.T_JUNCTION: [Direction.UP, Direction.RIGHT, Direction.DOWN],
	NodeType.CROSS: [Direction.UP, Direction.RIGHT, Direction.DOWN, Direction.LEFT],
	NodeType.START: [Direction.RIGHT],
	NodeType.END: [Direction.LEFT]
}

var _nodes: Array = []
var _node_buttons: Array = []
var _node_rotations: Array = []
var _start_pos: Vector2i = Vector2i(0, 0)
var _end_pos: Vector2i = Vector2i(3, 3)
var _time_remaining: float = 0.0
var _hints_remaining: int = 0
var _puzzle_active: bool = false
var _terminal: Node
var _solution_shown: bool = false

func _ready() -> void:
	# Get UI references
	if not grid_container:
		grid_container = get_node("PuzzleContainer/GridContainer")
	if not timer_label:
		timer_label = get_node("PuzzleContainer/TitleBar/TimerLabel")
	if not hint_button:
		hint_button = get_node("PuzzleContainer/ButtonBar/HintButton")
	if not exit_button:
		exit_button = get_node("PuzzleContainer/ButtonBar/ExitButton")
	
	# Connect signals
	for i in range(grid_container.get_child_count()):
		var btn = grid_container.get_child(i)
		if btn is TextureButton:
			btn.gui_input.connect(_on_node_gui_input.bind(i))
	
	hint_button.pressed.connect(_on_hint_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Initialize nodes array
	_nodes.resize(grid_size * grid_size)
	_node_buttons.resize(grid_size * grid_size)
	_node_rotations.resize(grid_size * grid_size)
	
	for i in range(grid_container.get_child_count()):
		var btn = grid_container.get_child(i)
		if btn is TextureButton:
			var idx = i
			_node_buttons[idx] = btn
			_nodes[idx] = _generate_random_node()
			_node_rotations[idx] = randi() % 4
			_update_button_visual(idx)

func start_puzzle(terminal: Node) -> void:
	_terminal = terminal
	_time_remaining = time_limit
	_hints_remaining = max_hints
	_puzzle_active = true
	_solution_shown = false
	
	# Regenerate puzzle
	_generate_puzzle()
	_update_all_visuals()
	
	if timer_label:
		timer_label.text = "%ds" % int(_time_remaining)
	
	if hint_button:
		hint_button.disabled = _hints_remaining <= 0
		hint_button.text = "HINT (%d)" % _hints_remaining
	
	visible = true

func _generate_puzzle() -> void:
	# Clear previous
	for i in range(_nodes.size()):
		_nodes[i] = _generate_random_node()
		_node_rotations[i] = randi() % 4
	
	# Ensure start and end positions
	_start_pos = Vector2i(0, randi() % grid_size)
	_end_pos = Vector2i(grid_size - 1, randi() % grid_size)
	
	# Make sure start and end are different
	if _start_pos == _end_pos:
		_end_pos.y = (_end_pos.y + 1) % grid_size
	
	# Set start and end nodes
	var start_idx = _start_pos.y * grid_size + _start_pos.x
	var end_idx = _end_pos.y * grid_size + _end_pos.x
	_nodes[start_idx] = NodeType.START
	_nodes[end_idx] = NodeType.END
	_node_rotations[start_idx] = 0
	_node_rotations[end_idx] = 0
	
	# Ensure there's at least one valid path by creating a simple path
	_create_guaranteed_path()

func _create_guaranteed_path() -> void:
	# Create a simple L-shaped path from start to end
	var current = _start_pos
	var target = _end_pos
	
	# Move horizontally first
	while current.x != target.x:
		var idx = current.y * grid_size + current.x
		if _nodes[idx] != NodeType.START and _nodes[idx] != NodeType.END:
			_nodes[idx] = NodeType.STRAIGHT
			if current.x < target.x:
				_node_rotations[idx] = 1  # Right
			else:
				_node_rotations[idx] = 3  # Left
		current.x += 1 if current.x < target.x else -1
	
	# Then vertically
	while current.y != target.y:
		var idx = current.y * grid_size + current.x
		if _nodes[idx] != NodeType.START and _nodes[idx] != NodeType.END:
			_nodes[idx] = NodeType.STRAIGHT
			if current.y < target.y:
				_node_rotations[idx] = 2  # Down
			else:
				_node_rotations[idx] = 0  # Up
		current.y += 1 if current.y < target.y else -1
	
	# Add some random branches
	for i in range(_nodes.size()):
		if randf() < 0.3 and _nodes[i] not in [NodeType.START, NodeType.END]:
			_nodes[i] = _get_random_pipe_type()
			_node_rotations[i] = randi() % 4

func _get_random_pipe_type() -> int:
	var types = [NodeType.STRAIGHT, NodeType.CORNER, NodeType.T_JUNCTION, NodeType.CROSS]
	return types[randi() % types.size()]

func _generate_random_node() -> int:
	var rand = randf()
	if rand < 0.4:
		return NodeType.EMPTY
	elif rand < 0.55:
		return NodeType.STRAIGHT
	elif rand < 0.7:
		return NodeType.CORNER
	elif rand < 0.85:
		return NodeType.T_JUNCTION
	else:
		return NodeType.CROSS

func _process(delta: float) -> void:
	if not _puzzle_active:
		return
	
	_time_remaining -= delta
	if timer_label:
		timer_label.text = "%ds" % int(ceil(_time_remaining))
		if _time_remaining <= 10.0:
			timer_label.custom_colors.font_color = Color(1.0, 0.3, 0.3, 1.0)
	
	if _time_remaining <= 0.0:
		_fail_puzzle()

func _on_node_gui_input(event: InputEvent, index: int) -> void:
	if not _puzzle_active or _solution_shown:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_rotate_node(index)
	elif event is InputEventScreenTouch and event.pressed:
		_rotate_node(index)

func _rotate_node(index: int) -> void:
	if _nodes[index] in [NodeType.START, NodeType.END, NodeType.EMPTY]:
		return
	
	_node_rotations[index] = (_node_rotations[index] + 1) % 4
	_update_button_visual(index)
	_check_puzzle_solved()

func _update_button_visual(index: int) -> void:
	if index >= _node_buttons.size():
		return
	
	var btn = _node_buttons[index]
	var node_type = _nodes[index]
	var rotation = _node_rotations[index]
	
	if not btn:
		return
	
	# Create texture based on node type and rotation
	var texture = _create_node_texture(node_type, rotation)
	btn.texture_normal = texture

func _create_node_texture(node_type: int, rotation: int) -> ImageTexture:
	var size = 64
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(size / 2, size / 2)
	var pipe_width = 12
	var pipe_length = 40
	
	# Background
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist < size * 0.45:
				img.set_pixel(x, y, color_empty)
	
	# Draw pipe based on type
	var connections = _get_rotated_connections(node_type, rotation)
	
	for dir in connections:
		var vec = DIR_VECTORS[dir]
		var start = center
		var end = center + Vector2(vec.x, vec.y) * pipe_length
		
		# Draw line
		var steps = int(pipe_length)
		for i in range(steps):
			var t = float(i) / steps
			var pos = start.lerp(end, t)
			var px = int(pos.x)
			var py = int(pos.y)
			for dx in range(-pipe_width/2, pipe_width/2 + 1):
				for dy in range(-pipe_width/2, pipe_width/2 + 1):
					var draw_x = px + dx
					var draw_y = py + dy
					if draw_x >= 0 and draw_x < size and draw_y >= 0 and draw_y < size:
						img.set_pixel(draw_x, draw_y, color_pipe)
	
	# Draw center hub
	for dx in range(-8, 9):
		for dy in range(-8, 9):
			if dx*dx + dy*dy <= 64:
				var px = int(center.x + dx)
				var py = int(center.y + dy)
				if px >= 0 and px < size and py >= 0 and py < size:
					img.set_pixel(px, py, color_pipe)
	
	# Special markers for start/end
	if node_type == NodeType.START:
		for dx in range(-10, 11):
			for dy in range(-10, 11):
				if dx*dx + dy*dy <= 100:
					var px = int(center.x + dx)
					var py = int(center.y + dy)
					if px >= 0 and px < size and py >= 0 and py < size:
						img.set_pixel(px, py, color_start)
	elif node_type == NodeType.END:
		for dx in range(-10, 11):
			for dy in range(-10, 11):
				if dx*dx + dy*dy <= 100:
					var px = int(center.x + dx)
					var py = int(center.y + dy)
					if px >= 0 and px < size and py >= 0 and py < size:
						img.set_pixel(px, py, color_end)
	
	var tex = ImageTexture.create_from_image(img)
	return tex

func _get_rotated_connections(node_type: int, rotation: int) -> Array[int]:
	var base = CONNECTIONS[node_type] if CONNECTIONS.has(node_type) else []
	var result = []
	for dir in base:
		var rotated = (dir + rotation) % 4
		result.append(rotated)
	return result

func _update_all_visuals() -> void:
	for i in range(_nodes.size()):
		_update_button_visual(i)

func _check_puzzle_solved() -> void:
	if _is_path_connected():
		_solve_puzzle()

func _is_path_connected() -> bool:
	# BFS from start to end
	var visited = []
	visited.resize(_nodes.size())
	var queue = [_start_pos]
	visited[_start_pos.y * grid_size + _start_pos.x] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var idx = current.y * grid_size + current.x
		var node_type = _nodes[idx]
		
		if current == _end_pos:
			return true
		
		var connections = _get_rotated_connections(node_type, _node_rotations[idx])
		
		for dir in connections:
			var vec = DIR_VECTORS[dir]
			var next = current + vec
			
			if next.x >= 0 and next.x < grid_size and next.y >= 0 and next.y < grid_size:
				var next_idx = next.y * grid_size + next.x
				if not visited[next_idx]:
					# Check if the next node connects back
					var next_connections = _get_rotated_connections(_nodes[next_idx], _node_rotations[next_idx])
					var opposite_dir = (dir + 2) % 4
					if opposite_dir in next_connections:
						visited[next_idx] = true
						queue.append(next)
	
	return false

func _solve_puzzle() -> void:
	_puzzle_active = false
	_solution_shown = true
	
	# Highlight solution path
	_highlight_solution()
	
	# Delay before closing
	var tween = create_tween()
	tween.tween_callback(_on_puzzle_success).set_delay(1.5)

func _on_puzzle_success() -> void:
	puzzle_completed.emit(true)
	visible = false

func _fail_puzzle() -> void:
	_puzzle_active = false
	puzzle_completed.emit(false)
	visible = false

func _on_hint_pressed() -> void:
	if _hints_remaining <= 0 or _solution_shown:
		return
	
	_hints_remaining -= 1
	if hint_button:
		hint_button.disabled = _hints_remaining <= 0
		hint_button.text = "HINT (%d)" % _hints_remaining
	
	# Show one correct rotation
	_show_hint()

func _show_hint() -> void:
	# Find a node that's not correctly rotated and fix it
	for i in range(_nodes.size()):
		if _nodes[i] in [NodeType.START, NodeType.END, NodeType.EMPTY]:
			continue
		# Check if this node is on the solution path
		if _is_on_solution_path(i):
			var correct_rot = _get_correct_rotation(i)
			if _node_rotations[i] != correct_rot:
				_node_rotations[i] = correct_rot
				_update_button_visual(i)
				return

func _is_on_solution_path(index: int) -> bool:
	# Simple check: if this node connects toward start or end
	var pos = Vector2i(index % grid_size, index / grid_size)
	var connections = _get_rotated_connections(_nodes[index], _node_rotations[index])
	return connections.size() > 0

func _get_correct_rotation(index: int) -> int:
	# Simplified: just return a rotation that connects to a neighbor
	var pos = Vector2i(index % grid_size, index / grid_size)
	var node_type = _nodes[index]
	var base_connections = CONNECTIONS[node_type] if CONNECTIONS.has(node_type) else []
	
	for rot in range(4):
		var conns = _get_rotated_connections(node_type, rot)
		for dir in conns:
			var vec = DIR_VECTORS[dir]
			var next = pos + vec
			if next.x >= 0 and next.x < grid_size and next.y >= 0 and next.y < grid_size:
				var next_idx = next.y * grid_size + next.x
				var next_type = _nodes[next_idx]
				if next_type != NodeType.EMPTY:
					var next_conns = _get_rotated_connections(next_type, _node_rotations[next_idx])
					var opposite = (dir + 2) % 4
					if opposite in next_conns:
						return rot
	return 0

func _highlight_solution() -> void:
	# Flash all connected nodes green
	var visited = []
	visited.resize(_nodes.size())
	var queue = [_start_pos]
	visited[_start_pos.y * grid_size + _start_pos.x] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var idx = current.y * grid_size + current.x
		var node_type = _nodes[idx]
		
		if node_type not in [NodeType.START, NodeType.END, NodeType.EMPTY]:
			# Flash green
			var btn = _node_buttons[idx]
			if btn:
				var tween = btn.create_tween()
				tween.tween_property(btn, "modulate:self_modulate", color_connected, 0.2)
				tween.tween_property(btn, "modulate:self_modulate", Color(1,1,1,1), 0.3)
		
		var connections = _get_rotated_connections(node_type, _node_rotations[idx])
		
		for dir in connections:
			var vec = DIR_VECTORS[dir]
			var next = current + vec
			
			if next.x >= 0 and next.x < grid_size and next.y >= 0 and next.y < grid_size:
				var next_idx = next.y * grid_size + next.x
				if not visited[next_idx]:
					var next_connections = _get_rotated_connections(_nodes[next_idx], _node_rotations[next_idx])
					var opposite_dir = (dir + 2) % 4
					if opposite_dir in next_connections:
						visited[next_idx] = true
						queue.append(next)

func _on_exit_pressed() -> void:
	_fail_puzzle()

func is_puzzle_active() -> bool:
	return _puzzle_active