extends Node

class_name SaveManagerClass

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_deleted(slot: int)
signal auto_save_triggered()

@export var max_save_slots: int = 10
@export var auto_save_interval: float = 300.0
@export var save_file_prefix: String = "veil_circuit_save_"
@export var save_file_extension: String = ".save"

var _auto_save_timer: float = 0.0
var _current_slot: int = -1
var _save_data: Dictionary = {}

func _ready() -> void:
	_ensure_save_dir()

func _ensure_save_dir() -> void:
	var dir = DirAccess.open("user://saves")
	if not dir:
		DirAccess.make_dir_recursive_absolute("user://saves")

func _physics_process(delta: float) -> void:
	if auto_save_interval > 0.0:
		_auto_save_timer += delta
		if _auto_save_timer >= auto_save_interval:
			_auto_save_timer = 0.0
			if _current_slot >= 0:
				auto_save(_current_slot)
				auto_save_triggered.emit()

func save_game(slot: int, game_state: Dictionary) -> bool:
	var save_path = _get_save_path(slot)
	var data = {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"game_version": "0.1.0",
		"slot": slot,
		"game_state": game_state
	}
	
	var json_string = JSON.stringify(data, "  ")
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open save file for writing: ", save_path)
		save_completed.emit(slot, false)
		return false
	
	file.store_string(json_string)
	file.close()
	
	_current_slot = slot
	_save_data[slot] = data
	save_completed.emit(slot, true)
	return true

func load_game(slot: int) -> Dictionary:
	var save_path = _get_save_path(slot)
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file for reading: ", save_path)
		load_completed.emit(slot, false)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json_string)
	if not parse_result:
		push_error("Failed to parse save file: ", save_path)
		load_completed.emit(slot, false)
		return {}
	
	var data = parse_result
	if not _validate_save_data(data):
		push_error("Save data validation failed: ", save_path)
		load_completed.emit(slot, false)
		return {}
	
	_current_slot = slot
	_save_data[slot] = data
	load_completed.emit(slot, true)
	return data.game_state

func _validate_save_data(data: Dictionary) -> bool:
	if not data.has("version"):
		return false
	if not data.has("game_state"):
		return false
	if data.version > 1:
		push_warning("Save version newer than supported: ", data.version)
	return true

func auto_save(slot: int) -> void:
	var game_state = _collect_current_game_state()
	save_game(slot, game_state)

func _collect_current_game_state() -> Dictionary:
	return {
		"current_level": "",
		"player_position": Vector3.ZERO,
		"player_rotation": 0.0,
		"player_health": 100,
		"player_stamina": 100,
		"inventory": {},
		"upgrades": {},
		"completed_objectives": [],
		"guard_states": {},
		"hacked_terminals": [],
		"settings": {
			"difficulty": GameGlobals.current_difficulty if GameGlobals else 1,
			"master_volume": GameGlobals.master_volume if GameGlobals else 0.8,
			"sfx_volume": GameGlobals.sfx_volume if GameGlobals else 0.8,
			"music_volume": GameGlobals.music_volume if GameGlobals else 0.6,
			"vibration_enabled": GameGlobals.vibration_enabled if GameGlobals else true,
			"inverted_camera_y": GameGlobals.inverted_camera_y if GameGlobals else false,
			"camera_sensitivity": GameGlobals.camera_sensitivity if GameGlobals else 1.0
		},
		"play_time": Time.get_ticks_msec() / 1000.0
	}

func apply_game_state(game_state: Dictionary) -> void:
	if game_state.has("settings"):
		var settings = game_state.settings
		if GameGlobals:
			GameGlobals.set_difficulty(settings.get("difficulty", 1))
			GameGlobals.set_master_volume(settings.get("master_volume", 0.8))
			GameGlobals.set_sfx_volume(settings.get("sfx_volume", 0.8))
			GameGlobals.set_music_volume(settings.get("music_volume", 0.6))
			GameGlobals.set_vibration_enabled(settings.get("vibration_enabled", true))
			GameGlobals.set_inverted_camera_y(settings.get("inverted_camera_y", false))
			GameGlobals.set_camera_sensitivity(settings.get("camera_sensitivity", 1.0))

func delete_save(slot: int) -> bool:
	var save_path = _get_save_path(slot)
	if FileAccess.file_exists(save_path):
		var err = DirAccess.remove_absolute(save_path)
		if err == OK:
			_save_data.erase(slot)
			if _current_slot == slot:
				_current_slot = -1
			save_deleted.emit(slot)
			return true
	return false

func get_save_info(slot: int) -> Dictionary:
	var save_path = _get_save_path(slot)
	if not FileAccess.file_exists(save_path):
		return {"exists": false}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return {"exists": false, "error": "Cannot read file"}
	
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json_string)
	if not parse_result:
		return {"exists": true, "error": "Invalid save data"}
	
	var data = parse_result
	return {
		"exists": true,
		"version": data.get("version", 0),
		"timestamp": data.get("timestamp", 0),
		"game_version": data.get("game_version", "unknown"),
		"slot": data.get("slot", slot),
		"play_time": data.game_state.get("play_time", 0) if data.has("game_state") else 0,
		"level": data.game_state.get("current_level", "unknown") if data.has("game_state") else "unknown"
	}

func get_all_saves() -> Array[Dictionary]:
	var saves = []
	for i in range(max_save_slots):
		saves.append(get_save_info(i))
	return saves

func has_save(slot: int) -> bool:
	var save_path = _get_save_path(slot)
	return FileAccess.file_exists(save_path)

func get_latest_save_slot() -> int:
	var latest_slot = -1
	var latest_time = 0
	
	for i in range(max_save_slots):
		var info = get_save_info(i)
		if info.exists and info.timestamp > latest_time:
			latest_time = info.timestamp
			latest_slot = i
	
	return latest_slot

func _get_save_path(slot: int) -> String:
	return "user://saves/%s%d%s" % [save_file_prefix, slot, save_file_extension]

func set_current_slot(slot: int) -> void:
	_current_slot = slot

func get_current_slot() -> int:
	return _current_slot

func export_save(slot: int, destination_path: String) -> bool:
	var save_path = _get_save_path(slot)
	if not FileAccess.file_exists(save_path):
		return false
	
	return DirAccess.copy_absolute(save_path, destination_path)

func import_save(slot: int, source_path: String) -> bool:
	if not FileAccess.file_exists(source_path):
		return false
	
	var dest_path = _get_save_path(slot)
	return DirAccess.copy_absolute(source_path, dest_path)

func clear_all_saves() -> void:
	for i in range(max_save_slots):
		delete_save(i)