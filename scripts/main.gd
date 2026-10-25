extends Node

func _ready() -> void:
	# Link terminal to security light
	var terminal = get_node("Terminal")
	var world = get_node("World")
	var test_room = world.find_child("TestRoom", true, false)
	var security_light = test_room.find_child("SecurityLight", true, false) if test_room else null
	
	if terminal and security_light:
		terminal.linked_security_device = security_light
	# Diagnostic guard: list invalid mesh instances while headless testing.
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			push_error("NULL MESH INSTANCE: %s" % mesh_node.get_path())
