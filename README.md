# VEIL CIRCUIT

A mobile-first 2.5D stealth and hacking game built with Godot 4.3 LTS, now expanding from a test room into a compact procedural city district.

## Overview

VEIL CIRCUIT is an original stealth-action game where you play as a cybernetically enhanced operative infiltrating secure facilities. Hack terminals, avoid guards, and uncover a corporate conspiracy in a near-future setting.

- **Engine:** Godot 4.3 LTS (Stable)
- **Renderer:** Compatibility (GLES3)
- **Language:** GDScript
- **Platform:** Android (ARM32 + ARM64), 4 GB RAM minimum
- **Orientation:** Landscape
- **Connectivity:** Offline-first, no ads, no tracking

## Current playable slice

- **Playable city district:** Procedural 4×4-block district with roads, sidewalks, lane markings, low-poly buildings, facade windows, rooftop HVAC props, junction lamps, utility cabinets, decorative CCTV housings, and sidewalk bollards.
- **Player character:** Original low-poly cyber-operative assembled from procedural meshes with dark tactical clothing, armor, backpack, utility belt, and cyan cyber-tech accents.
- **Hacking:** Interactive circuit puzzle and hackable terminals connected to the security-light network.
- **Stealth foundation:** Guard patrols and security devices; a larger mission and detection system remains in development.
- **Mobile controls:** Touch joystick, camera-look area, sprint, crouch, interact, and pause/resume.
- **Performance strategy:** Godot Compatibility renderer, batched MultiMesh city props, limited dynamic lighting, and a 30 FPS target for low-end Android.
- **Zero-budget policy:** Built-in Godot geometry/materials and free/open-source resources only; no paid assets, API keys, ads, tracking, or required runtime downloads.

## Planned next milestones

- Improve guard awareness and stealth feedback, then add mission objectives and progression.
- Add safe, tested character movement and hacking animations.
- Add optional free licensed sound effects and ambient audio with documented asset licenses.
- Continue profiling on real Android hardware before raising texture sizes, lighting cost, or scene density.
- See `docs/OPEN_CITY_ROADMAP.md` for the broader roadmap. Remote camera control, vehicles, drones, and streaming a much larger city are not claimed as complete features.

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

## Low-End Character Visuals

The player operative is generated procedurally in `scripts/gameplay/player_visual.gd`:
a hooded silhouette, layered tactical armor, backpack, utility belt, boots, and cyan
hacking visor/device. The geometry is merged into **three material surfaces** instead
of one renderable node per body part, reducing per-character draw-call overhead.
It uses no downloaded models, textures, paid services, or runtime dependencies.

The model is a lightweight visual prototype, not yet a rigged/animated production
character. The Compatibility renderer and 30 FPS target remain in place. Real-device
frame rate, heat, memory use, and long-session stability must still be measured on
the target Android phone before making performance guarantees.

## Batched City Facade Details

The procedural district adds dark reflective windows, a restrained mix of cyan-lit
windows, and rooftop HVAC units. These details are generated from low-poly boxes and
shared through three MultiMesh batches, rather than creating a separate scene node
for every window or roof unit. The city keeps its deterministic seed and does not
download textures or models at runtime.

## Development Phases

1. **Phase 0:** Project bootstrap
2. **Phase 1:** Playable vertical slice — player, guard, terminal, HUD
3. **Phase 2:** Compact procedural city district and responsive puzzle input (in progress)
4. **Phase 3:** Camera/network hacks, traffic systems, mission loop, and progression
5. **Phase 4:** Streamed district expansion, vehicle prototype, and broader release testing

## License

Proprietary — All rights reserved. Assets used under their respective licenses (CC0 for Kenney, etc.).

## Credits

See [CREDITS.md](CREDITS.md) for asset attributions.