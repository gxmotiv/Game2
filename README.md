# VEIL CIRCUIT

A mobile-first 2.5D stealth and hacking game built with Godot 4.3 LTS.

## Overview

VEIL CIRCUIT is an original stealth-action game where you play as a cybernetically enhanced operative infiltrating secure facilities. Hack terminals, avoid guards, and uncover a corporate conspiracy in a near-future setting.

- **Engine:** Godot 4.3 LTS (Stable)
- **Renderer:** Compatibility (GLES3)
- **Language:** GDScript
- **Platform:** Android (ARM32 + ARM64), 4 GB RAM minimum
- **Orientation:** Landscape
- **Connectivity:** Offline-first, no ads, no tracking

## Features (Planned)

- **Stealth Gameplay:** Vision cones, sound propagation, suspicion meters
- **Hacking Minigames:** Circuit tracing, pattern matching, timing challenges
- **2.5D Perspective:** 3D world with orthographic camera
- **Mobile Controls:** Dual-stick movement + contextual action buttons
- **Progression:** Upgrade tree, equipment, abilities
- **Levels:** Hand-crafted facilities, compact city hub

## Requirements

- Godot 4.3 Stable
- Android SDK (API 21+)
- JDK 17+
- Gradle 8+

## Building

### Desktop (Editor)
```bash
godot --editor
```

### Android Debug APK
```bash
godot --export-release "Android Debug" build/android/veil_circuit_debug.apk
```

### Android Release AAB
```bash
godot --export-release "Android Release" build/android/veil_circuit_release.aab
```

### Headless Validation (CI)
```bash
godot --headless --check-only
godot --headless --script-classes
```

## Project Structure

```
├── assets/          # Source assets (Blender, Aseprite, audio)
├── build/           # Export outputs (gitignored)
├── data/            # Runtime data (JSON, CSV)
├── docs/            # Design documentation
├── export_presets.cfg
├── project.godot
├── scenes/          # All .tscn scenes
│   ├── main/        # Entry points
│   ├── gameplay/    # Player, guards, hacking, interactables
│   ├── world/       # Level scenes
│   ├── ui/          # HUD, menus, minigame UI
│   └── systems/     # Non-instanced system scenes
├── scripts/         # GDScript code
│   ├── autoloads/   # Global singletons
│   ├── core/        # Core systems (stealth, movement, interaction)
│   ├── gameplay/    # Gameplay-specific scripts
│   └── utils/       # Utility functions
├── shaders/         # Custom shaders
├── tests/           # GUT unit/integration tests
└── tools/           # Editor scripts
```

## Key Autoloads

| Name | Script | Purpose |
|------|--------|---------|
| `Globals` | `scripts/autoloads/globals.gd` | Enums, constants, global signals, settings |
| `InputMap` | `scripts/autoloads/input_map.gd` | Input action registration (16 actions) |
| `AudioManager` | `scripts/autoloads/audio_manager.gd` | SFX/music/ambient/voice management |
| `StealthSystem` | `scripts/core/stealth_system.gd` | Vision, hearing, suspicion logic |
| `SaveManager` | `scripts/autoloads/save_manager.gd` | Save/load, auto-save, slots |

## Input Actions (16 Total)

**Movement:** `move_left`, `move_right`, `move_forward`, `move_backward`
**Modifiers:** `sprint`, `crouch`
**Interaction:** `interact`, `pause`
**Camera:** `camera_orbit`, `camera_zoom`
**Hacking:** `hack_up`, `hack_down`, `hack_left`, `hack_right`, `hack_confirm`, `hack_cancel`

## Performance Targets

- **Triangles/frame:** ≤ 15,000
- **Draw calls:** ≤ 30
- **Texture memory:** ≤ 64 MB
- **Frame time:** ≤ 33 ms (30 FPS)
- **APK size (ARM32):** ≤ 80 MB
- **RAM (running):** ≤ 1.5 GB

## Asset Strategy

All assets are original or CC0-licensed:
- Kenney.nl asset packs (Industrial, Character, UI)
- Procedural materials via Godot shaders
- Bfxr/Freesound for audio (CC0)
- Blender for custom low-poly models

## Development Phases

1. **Phase 0:** Project bootstrap (this commit)
2. **Phase 1:** Vertical slice — single room, player, guard, terminal, HUD
3. **Phase 2:** Core systems polish + micro-district level
4. **Phase 3:** City systems, vehicles, progression, full release build
5. **Phase 4:** Post-launch content (optional)

## License

Proprietary — All rights reserved. Assets used under their respective licenses (CC0 for Kenney, etc.).

## Credits

See [CREDITS.md](CREDITS.md) for asset attributions.