class_name SignalBus
extends Object

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
signal player_died()
signal checkpoint_reached(checkpoint_id: String)
signal objective_completed(objective_id: String)
signal objective_failed(objective_id: String)
signal alarm_triggered()
signal alarm_cleared()
signal checkpoint_saved()
signal game_loaded()

static var instance: SignalBus

func _init():
	instance = self

static func get_instance() -> SignalBus:
	if instance == null:
		instance = SignalBus.new()
	return instance