# VEIL CIRCUIT — Fix Confirmed Godot 4.3 Build Errors

## Problem Summary

The Android build (commit `0286a08`) fails with three script parse errors:

1. **scenes/main/main.gd:12** - Undeclared identifier "Systems"
2. **scripts/core/interaction.gd** - Signals accessed from static functions (4 signals)
3. **scripts/utils/performance.gd** - Unsupported OS APIs: `get_dynamic_memory_usage()` and `get_dynamic_memory_peak_usage()`

---

## Fix 1: scenes/main/main.gd — Fix "Systems" Reference

### Root Cause
In `main.tscn`, `Systems` is a plain `Node` with no script. In `main.gd:12`, `@onready var systems = $Systems` gets the node, but `_ready()` checks `if Systems:` which is invalid - `Systems` is not an autoload, it's just a plain Node child.

### Fix
Remove the unused `Systems` node reference and the incorrect autoload check. The actual autoloads (GameGlobals, InputManager, AudioManager, StealthSystem, SaveManager) are already registered in `project.godot`.

**File:** `scenes/main/main.gd`

```diff
 extends Node
 class_name MainScene

 @onready var world = $World
 @onready var player = $Player
 @onready var guard = $Guard
 @onready var terminal = $Terminal
 @onready var mobile_hud = $MobileHUD
 @onready var hacking_puzzle = $HackingPuzzle
-@onready var systems = $Systems

 func _ready() -> void:
 	# Connect signals
 	if player:
 		player.connect("died", _on_player_died)
 	
 	if terminal:
 		terminal.connect("hack_started", _on_hack_started)
 		terminal.connect("hack_completed", _on_hack_completed)
 	
 	if hacking_puzzle:
 		hacking_puzzle.connect("puzzle_completed", _on_puzzle_completed)
 	
-	# Initialize systems
-	if Systems:
-		pass # Systems are autoloads
```

---

## Fix 2: scripts/core/interaction.gd — Fix Static Signal Emissions

### Root Cause
`InteractionSystem` declares 4 signals at class level but all methods are `static`. In Godot 4.x, signals can only be emitted from **instances**, not static functions. The static methods try to emit signals like `interaction_available.emit(interactable)` which fails at parse time.

### Architecture Decision
Since `InteractionSystem` is used as a global interaction state manager (holding current interactable, range, type), it should be an **autoload singleton** (non-static) rather than a static utility class. This preserves the global state management while allowing signal emission.

### Fix Steps
1. Remove `static` from all methods and variables
2. Keep the class as a regular class (not static)
3. Register as autoload in `project.godot` (name: `InteractionSystem`)
3. Update any callers (though currently unused, the API should work)

**File:** `scripts/core/interaction.gd`

```diff
 class_name InteractionSystem

 signal interaction_available(interactable: Node3D)
 signal interaction_unavailable()
 signal interaction_started(interactable: Node3D)
 signal interaction_completed(interactable: Node3D, success: bool)

 enum InteractionType {
 	HACK = 0,
 	OPEN_DOOR = 1,
 	ENTER_VENT = 2,
 	PICKUP = 3,
 	CUSTOM = 4
 }

-static var _current_interactable: Node3D = null
-static var _interaction_range: float = 2.5
-static var _current_type: int = InteractionType.CUSTOM
+var _current_interactable: Node3D = null
+var _interaction_range: float = 2.5
+var _current_type: int = InteractionType.CUSTOM

-static func set_interaction_range(range: float) -> void:
+func set_interaction_range(range: float) -> void:
 	_interaction_range = range

-static func get_interaction_range() -> float:
+func get_interaction_range() -> float:
 	return _interaction_range

-static func set_current_interactable(interactable: Node3D, type: int = InteractionType.CUSTOM) -> void:
+func set_current_interactable(interactable: Node3D, type: int = InteractionType.CUSTOM) -> void:
 	_current_interactable = interactable
 	_current_type = type
 	if interactable:
 		interaction_available.emit(interactable)
 	else:
 		interaction_unavailable.emit()

-static func get_current_interactable() -> Node3D:
+func get_current_interactable() -> Node3D:
 	return _current_interactable

-static func get_current_type() -> int:
+func get_current_type() -> int:
 	return _current_type

-static func try_interact() -> bool:
+func try_interact() -> bool:
 	if _current_interactable and _current_interactable.is_inside_tree():
 		interaction_started.emit(_current_interactable)
 		return true
 	return false

-static func complete_interaction(success: bool) -> void:
+func complete_interaction(success: bool) -> void:
 	if _current_interactable:
 		interaction_completed.emit(_current_interactable, success)
 		_current_interactable = null
 		_current_type = InteractionType.CUSTOM
 		interaction_unavailable.emit()

-static func is_interacting() -> bool:
+func is_interacting() -> bool:
 	return _current_interactable != null

-static func get_interaction_prompt_text() -> String:
+func get_interaction_prompt_text() -> String:
 	if not _current_interactable:
 		return ""
 	
 	match _current_type:
 		InteractionType.HACK:
 			return "Press [E] to Hack"
 		InteractionType.OPEN_DOOR:
 			return "Press [E] to Open"
 		InteractionType.ENTER_VENT:
 			return "Press [E] to Enter"
 		InteractionType.PICKUP:
 			return "Press [E] to Pick Up"
 		InteractionType.CUSTOM:
 			if _current_interactable.has_method("get_interaction_prompt"):
 				return _current_interactable.get_interaction_prompt()
 			return "Press [E] to Interact"
 	return ""
```

**Also update `project.godot` autoload section:**
```diff
 [autoload]
 
 GameGlobals = "*res://scripts/autoloads/globals.gd"
 InputManager = "*res://scripts/autoloads/input_map.gd"
 AudioManager = "*res://scripts/autoloads/audio_manager.gd"
 StealthSystem = "*res://scripts/core/stealth_system.gd"
 SaveManager = "*res://scripts/autoloads/save_manager.gd"
+InteractionSystem = "*res://scripts/core/interaction.gd"
```

---

## Fix 3: scripts/utils/performance.gd — Remove Unsupported OS APIs

### Root Cause
Godot 4.3's `OS` class does not have `get_dynamic_memory_usage()` or `get_dynamic_memory_peak_usage()`. These methods exist in newer Godot versions (4.4+) but not in 4.3 stable.

Available in Godot 4.3:
- `OS.get_static_memory_usage()` ✅
- `OS.get_static_memory_peak_usage()` ✅
- `OS.get_dynamic_memory_usage()` ❌ (not in 4.3)
- `OS.get_dynamic_memory_peak_usage()` ❌ (not in 4.3)

### Fix
Remove the unsupported dynamic memory calls. Keep only static memory tracking which is available.

**File:** `scripts/utils/performance.gd`

```diff
 static func get_memory_usage() -> Dictionary:
 	return {
 		"static": OS.get_static_memory_usage(),
-		"dynamic": OS.get_dynamic_memory_usage(),
 		"static_peak": OS.get_static_memory_peak_usage(),
-		"dynamic_peak": OS.get_dynamic_memory_peak_usage()
 	}

 static func print_performance_report() -> void:
 	var avg = get_average_frame_time()
 	var fps = get_fps()
 	var mm = get_min_max_frame_time()
 	var mem = get_memory_usage()
 	print("=== Performance Report ===")
 	print("Avg Frame Time: %.4f ms (%.1f FPS)" % [avg * 1000, fps])
 	print("Min Frame Time: %.4f ms" % [mm.min * 1000])
 	print("Max Frame Time: %.4f ms" % [mm.max * 1000])
 	print("Static Memory: %.2f MB" % [mem.static / 1024.0 / 1024.0])
-	print("Dynamic Memory: %.2f MB" % [mem.dynamic / 1024.0 / 1024.0])
 	print("==========================")
```

---

## Validation Plan

```bash
# 1. Syntax check
godot --headless --check-only --path /workspace/app

# 2. Script class registration
godot --headless --script-classes --path /workspace/app

# 3. Android Debug export (dry run - just verify no parse errors)
godot --headless --export-release "Android Debug" build/android/veil_circuit_debug.apk --path /workspace/app
```

---

## Files to Change

| File | Changes |
|------|---------|
| `scenes/main/main.gd` | Remove `Systems` node reference |
| `scripts/core/interaction.gd` | Remove `static` from all methods/vars, add autoload registration |
| `scripts/utils/performance.gd` | Remove unsupported `OS.get_dynamic_memory_*` calls |
| `project.godot` | Add `InteractionSystem` autoload |

---

## Validation Checklist

- [ ] `godot --headless --check-only` passes (exit code 0)
- [ ] `godot --headless --script-classes` passes (20+ classes registered)
- [ ] Android Debug export completes without parse errors
- [ ] APK artifact generated at `build/android/veil_circuit_debug.apk`
- [ ] GitHub Actions run passes

---

## Out of Scope
- Android device testing (requires physical device)
- Runtime gameplay verification
- Performance profiling on device
- APK installation on device
- Adding new gameplay features

---

**Ready for implementation.** The fixes are minimal, targeted, and address only the confirmed parse errors.