extends Node

func _ready() -> void:
	var terminal := get_node_or_null("Terminal")
	var world := get_node_or_null("World")
	if terminal == null or world == null:
		push_warning("Main scene is missing Terminal or World; check main.tscn scene instances.")
		return

	var test_room := world.find_child("TestRoom", true, false)
	if test_room == null:
		push_warning("Training room was not found; the security light link is unavailable.")
		return

	var security_light := test_room.get_node_or_null("SecurityLight")
	if security_light and terminal.has_method("set"):
		terminal.set("linked_security_device", security_light)
