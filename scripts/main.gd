extends Node

func _ready() -> void:
	# Link terminal to security light
	var terminal = get_node("Terminal")
	var world = get_node("World")
	var test_room = world.find_child("TestRoom", true, false)
	var security_light = test_room.find_child("SecurityLight", true, false) if test_room else null
	
	if terminal and security_light:
		terminal.linked_security_device = security_light