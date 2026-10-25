extends Node

class_name GameGlobalsClass

signal game_paused()
signal game_resumed()
signal game_over(won: bool)
signal level_loaded(level_name: String)
signal player_detected(guard_id: int, suspicion: float)
signal hacking_started(terminal_id: String)
signal hacking_ended(result: int, terminal_id: String)
signal guard_state_changed(guard_id: int, new_state: int)
signal suspicion_changed(value: float)
signal settings_changed()

enum GuardState {
	IDLE = 0,
	PATROL = 1,
	SUSPICIOUS = 2,
	INVESTIGATING = 3,
	ALERT = 4,
	SEARCHING = 5,
	RETURNING = 6
}

enum HackResult {
	SUCCESS = 0,
	FAIL = 1,
	CANCEL = 2
}

enum HackMinigameType {
	CIRCUIT_TRACE = 0,
	PATTERN_MATCH = 1,
	TIMING = 2,
	LOGIC_GATE = 3
}

enum PlayerStance {
	STANDING = 0,
	CROUCHING = 1,
	PRONE = 2
}

enum GameDifficulty {
	EASY = 0,
	NORMAL = 1,
	HARD = 2
}

const GAME_VERSION: String = "0.1.0"
const TARGET_FPS: int = 30
const MAX_SUSPICION: float = 100.0
const SUSPICION_DECAY_RATE: float = 5.0
const SUSPICION_RISE_RATE: float = 15.0
const DETECTION_THRESHOLD: float = 75.0
const VISION_CONE_ANGLE: float = 90.0
const VISION_CONE_RANGE: float = 15.0
const HEARING_RANGE: float = 10.0
const PLAYER_MOVE_SPEED: float = 3.0
const PLAYER_SPRINT_SPEED: float = 6.0
const PLAYER_CROUCH_SPEED: float = 1.5
const GUARD_PATROL_SPEED: float = 2.0
const GUARD_CHASE_SPEED: float = 5.0
const HACK_TIME_BASE: float = 30.0
const HACK_TIME_PER_NODE: float = 2.0

var current_difficulty: int = GameDifficulty.NORMAL
var master_volume: float = 0.8
var sfx_volume: float = 0.8
var music_volume: float = 0.6
var vibration_enabled: bool = true
var inverted_camera_y: bool = false
var camera_sensitivity: float = 1.0

func _ready() -> void:
	_load_settings()
	call_deferred("_apply_volumes_deferred")

func _apply_volumes_deferred() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		current_difficulty = config.get_value("gameplay", "difficulty", GameDifficulty.NORMAL)
		master_volume = config.get_value("audio", "master_volume", 0.8)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		music_volume = config.get_value("audio", "music_volume", 0.6)
		vibration_enabled = config.get_value("input", "vibration_enabled", true)
		inverted_camera_y = config.get_value("input", "inverted_camera_y", false)
		camera_sensitivity = config.get_value("input", "camera_sensitivity", 1.0)

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("gameplay", "difficulty", current_difficulty)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("input", "vibration_enabled", vibration_enabled)
	config.set_value("input", "inverted_camera_y", inverted_camera_y)
	config.set_value("input", "camera_sensitivity", camera_sensitivity)
	config.save("user://settings.cfg")

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	var idx = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(master_volume))
	_save_settings()
	settings_changed.emit()

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	var idx = AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(sfx_volume))
	_save_settings()
	settings_changed.emit()

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	var idx = AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(music_volume))
	_save_settings()
	settings_changed.emit()
	settings_changed.emit()

func set_difficulty(difficulty: int) -> void:
	current_difficulty = difficulty
	_save_settings()
	settings_changed.emit()

func set_vibration_enabled(enabled: bool) -> void:
	vibration_enabled = enabled
	_save_settings()
	settings_changed.emit()

func set_inverted_camera_y(inverted: bool) -> void:
	inverted_camera_y = inverted
	_save_settings()
	settings_changed.emit()

func set_camera_sensitivity(sensitivity: float) -> void:
	camera_sensitivity = clamp(sensitivity, 0.1, 3.0)
	_save_settings()
	settings_changed.emit()

func get_difficulty_multiplier() -> float:
	match current_difficulty:
		GameDifficulty.EASY: return 0.7
		GameDifficulty.NORMAL: return 1.0
		GameDifficulty.HARD: return 1.4
	return 1.0

func guard_state_to_string(state: int) -> String:
	match state:
		GuardState.IDLE: return "Idle"
		GuardState.PATROL: return "Patrol"
		GuardState.SUSPICIOUS: return "Suspicious"
		GuardState.INVESTIGATING: return "Investigating"
		GuardState.ALERT: return "Alert"
		GuardState.SEARCHING: return "Searching"
		GuardState.RETURNING: return "Returning"
	return "Unknown"

func hack_result_to_string(result: int) -> String:
	match result:
		HackResult.SUCCESS: return "Success"
		HackResult.FAIL: return "Fail"
		HackResult.CANCEL: return "Cancel"
	return "Unknown"