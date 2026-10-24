extends Node

class_name AudioManagerClass

signal music_started(track_name: String)
signal music_stopped(track_name: String)
signal sfx_played(sfx_name: String)

@export_group("Audio Buses")
@export var master_bus_name: String = "Master"
@export var sfx_bus_name: String = "SFX"
@export var music_bus_name: String = "Music"
@export var voice_bus_name: String = "Voice"
@export var ambient_bus_name: String = "Ambient"

@export_group("SFX Pool")
@export var max_sfx_instances: int = 16

var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _sfx_library: Dictionary = {}
var _music_library: Dictionary = {}
var _ambient_library: Dictionary = {}
var _voice_library: Dictionary = {}
var _as: Variant

func _ready() -> void:
	_as = Engine.get_singleton("AudioServer")
	_setup_audio_buses()
	_init_sfx_pool()
	_create_players()

func _setup_audio_buses() -> void:
	if not _as or not _as.has_method("has_bus"):
		return
	
	if not _as.call("has_bus", master_bus_name):
		_as.call("add_bus", master_bus_name)
	
	var bus_names = [sfx_bus_name, music_bus_name, voice_bus_name, ambient_bus_name]
	for bus_name in bus_names:
		if not _as.call("has_bus", bus_name):
			var idx = _as.call("add_bus", bus_name)
			var master_idx = _as.call("get_bus_index", master_bus_name)
			_as.call("set_bus_send", idx, master_idx, true)

func _init_sfx_pool() -> void:
	for i in range(max_sfx_instances):
		var player = AudioStreamPlayer.new()
		player.bus = sfx_bus_name
		player.autoplay = false
		add_child(player)
		_sfx_pool.append(player)

func _create_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = music_bus_name
	_music_player.autoplay = false
	add_child(_music_player)
	
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = ambient_bus_name
	_ambient_player.autoplay = false
	add_child(_ambient_player)
	
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = voice_bus_name
	_voice_player.autoplay = false
	add_child(_voice_player)

func register_sfx(name: String, stream: AudioStream) -> void:
	_sfx_library[name] = stream

func register_music(name: String, stream: AudioStream) -> void:
	_music_library[name] = stream

func register_ambient(name: String, stream: AudioStream) -> void:
	_ambient_library[name] = stream

func register_voice(name: String, stream: AudioStream) -> void:
	_voice_library[name] = stream

func play_sfx(name: String, position: Vector3 = Vector3.ZERO, volume_db: float = 0.0, pitch_scale: float = 1.0, max_distance: float = 50.0, attenuation_model: int = 1) -> AudioStreamPlayer:
	var stream = _sfx_library.get(name)
	if not stream:
		push_error("SFX not found: ", name)
		return null
	
	var player = _get_available_sfx_player()
	if not player:
		player = _sfx_pool[0]
	
	if player.stream != stream:
		player.stream = stream
	
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	
	if position != Vector3.ZERO:
		player.global_position = position
		player.max_distance = max_distance
		player.attenuation_model = attenuation_model
	
	player.play()
	sfx_played.emit(name)
	return player

func play_sfx_2d(name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	var stream = _sfx_library.get(name)
	if not stream:
		push_error("SFX not found: ", name)
		return null
	
	var player = _get_available_sfx_player()
	if not player:
		player = _sfx_pool[0]
	
	if player.stream != stream:
		player.stream = stream
	
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	sfx_played.emit(name)
	return player

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return null

func play_music(name: String, fade_time: float = 1.0) -> void:
	var stream = _music_library.get(name)
	if not stream:
		push_error("Music track not found: ", name)
		return
	
	if _music_player.stream == stream and _music_player.playing:
		return
	
	if _music_player.playing:
		_music_player.fade_out(fade_time)
		await get_tree().create_timer(fade_time).timeout
	
	_music_player.stream = stream
	_music_player.play(fade_time)
	music_started.emit(name)

func stop_music(fade_time: float = 1.0) -> void:
	if _music_player.playing:
		_music_player.fade_out(fade_time)
		await get_tree().create_timer(fade_time).timeout
		music_stopped.emit(_music_player.stream.get_name() if _music_player.stream else "unknown")

func play_ambient(name: String, fade_time: float = 2.0, loop: bool = true) -> void:
	var stream = _ambient_library.get(name)
	if not stream:
		push_error("Ambient track not found: ", name)
		return
	
	if _ambient_player.stream == stream and _ambient_player.playing:
		return
	
	if _ambient_player.playing:
		_ambient_player.fade_out(fade_time)
		await get_tree().create_timer(fade_time).timeout
	
	_ambient_player.stream = stream
	_ambient_player.loop = loop
	_ambient_player.play(fade_time)

func stop_ambient(fade_time: float = 2.0) -> void:
	if _ambient_player.playing:
		_ambient_player.fade_out(fade_time)

func play_voice(name: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	var stream = _voice_library.get(name)
	if not stream:
		push_error("Voice line not found: ", name)
		return null
	
	_voice_player.stream = stream
	_voice_player.volume_db = volume_db
	_voice_player.play()
	return _voice_player

func _call_as(method: String, arg1: Variant = null, arg2: Variant = null, arg3: Variant = null) -> Variant:
	if _as and _as.has_method(method):
		if arg3 != null:
			return _as.call(method, arg1, arg2, arg3)
		elif arg2 != null:
			return _as.call(method, arg1, arg2)
		elif arg1 != null:
			return _as.call(method, arg1)
		else:
			return _as.call(method)
	return null

func set_master_volume(volume_db: float) -> void:
	var idx = _call_as("get_bus_index", master_bus_name)
	if idx is int:
		_call_as("set_bus_volume_db", idx, volume_db)

func set_sfx_volume(volume_db: float) -> void:
	var idx = _call_as("get_bus_index", sfx_bus_name)
	if idx is int:
		_call_as("set_bus_volume_db", idx, volume_db)

func set_music_volume(volume_db: float) -> void:
	var idx = _call_as("get_bus_index", music_bus_name)
	if idx is int:
		_call_as("set_bus_volume_db", idx, volume_db)

func set_voice_volume(volume_db: float) -> void:
	var idx = _call_as("get_bus_index", voice_bus_name)
	if idx is int:
		_call_as("set_bus_volume_db", idx, volume_db)

func set_ambient_volume(volume_db: float) -> void:
	var idx = _call_as("get_bus_index", ambient_bus_name)
	if idx is int:
		_call_as("set_bus_volume_db", idx, volume_db)

func get_master_volume() -> float:
	var idx = _call_as("get_bus_index", master_bus_name)
	if idx is int:
		return _call_as("get_bus_volume_db", idx)
	return 0.0

func get_sfx_volume() -> float:
	var idx = _call_as("get_bus_index", sfx_bus_name)
	if idx is int:
		return _call_as("get_bus_volume_db", idx)
	return 0.0

func get_music_volume() -> float:
	var idx = _call_as("get_bus_index", music_bus_name)
	if idx is int:
		return _call_as("get_bus_volume_db", idx)
	return 0.0

func pause_all() -> void:
	_call_as("set_pause", true)

func resume_all() -> void:
	_call_as("set_pause", false)

func stop_all_sfx() -> void:
	for player in _sfx_pool:
		player.stop()

func is_music_playing() -> bool:
	return _music_player.playing

func get_current_music() -> String:
	if _music_player.stream:
		return _music_player.stream.get_name()
	return ""

func load_sfx_library(directory: String) -> void:
	var dir = DirAccess.open(directory)
	if not dir:
		push_error("Cannot open SFX directory: ", directory)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".ogg") or file_name.ends_with(".wav")):
			var stream = load(directory + "/" + file_name)
			if stream:
				var name = file_name.get_basename()
				register_sfx(name, stream)
		file_name = dir.get_next()
	dir.list_dir_end()

func load_music_library(directory: String) -> void:
	var dir = DirAccess.open(directory)
	if not dir:
		push_error("Cannot open music directory: ", directory)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".ogg") or file_name.ends_with(".wav")):
			var stream = load(directory + "/" + file_name)
			if stream:
				var name = file_name.get_basename()
				register_music(name, stream)
		file_name = dir.get_next()
	dir.list_dir_end()