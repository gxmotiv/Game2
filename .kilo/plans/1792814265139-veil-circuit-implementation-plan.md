# VEIL CIRCUIT — Phased Implementation Plan

## Project Overview
- **Game:** VEIL CIRCUIT — mobile-first 2.5D stealth/hacking
- **Engine:** Godot 4.3 LTS (stable), Compatibility renderer (GLES3)
- **Target:** Android 4 GB RAM, ARM32 + ARM64 (Realme 10 / low-end)
- **Scope:** Offline-first, no ads/tracking, original content only
- **Repo:** `gxmotiv/Game2` (currently empty — build from scratch)

---

## Architecture Decisions (Resolved)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Godot version | 4.3 LTS | Stable, good Android export, long-term support |
| Renderer | Compatibility (GLES3) | Runs on ARM32, GLES3 fallback, wide device support |
| 2.5D approach | 3D scenes + orthographic camera | True 3D lighting/shadows, sprite billboards, flexible camera |
| Controls | Dual-stick + action buttons | Standard mobile landscape, familiar, testable |
| Hacking | Minigame (circuit/pattern tracing) | Engaging, skill-based, mobile-friendly touch |
| Stealth AI | Vision cone + sound + suspicion meter | Classic, readable, tunable difficulty |
| Assets | CC0 (Kenney, itch.io) + procedural | Zero cost, original, license-safe, pipeline-friendly |
| Performance budget | 15k tris, 512px atlases, 30 FPS on ARM32 | Meets 4 GB / low-end target |
| Testing in Kilo | Static only (lint, parse, validate) | No GPU, no Godot binary in container |

---

## Folder Structure

```
/workspace/app/
├── .godot/                    # Godot cache (gitignored)
├── .kilo/
│   └── plans/                 # This plan + future plans
├── addons/                    # GUT (testing), any plugins
├── assets/                    # Source assets (Blender, Aseprite, raw)
│   ├── models/                # .blend, .glb source
│   ├── textures/              # .aseprite, .png source
│   └── audio/                 # .wav, .ogg source
├── build/                     # Export outputs (gitignored)
│   └── android/
├── data/                      # Runtime data (JSON, CSV, resources)
│   ├── levels/                # Level definitions
│   ├── upgrades/              # Hacking/player upgrades
│   └── localization/          # CSV for strings
├── docs/                      # Design docs, API reference
├── export_presets.cfg         # Android export config (generated)
├── project.godot              # Project settings (generated)
├── README.md                  # Project overview
├── CREDITS.md                 # Asset attributions
├── scenes/                    # All .tscn files
│   ├── main/                  # Entry points
│   │   ├── main.tscn          # Bootstrap (autoloads, first scene)
│   │   └── main.gd
│   ├── gameplay/              # Core gameplay scenes
│   │   ├── player/
│   │   │   ├── player.tscn
│   │   │   ├── player.gd
│   │   │   ├── player_camera.tscn
│   │   │   └── player_camera.gd
│   │   ├── guard/
│   │   │   ├── guard.tscn
│   │   │   ├── guard.gd
│   │   │   ├── vision_cone.tscn
│   │   │   └── suspicion_meter.tscn
│   │   ├── hacking/
│   │   │   ├── terminal.tscn
│   │   │   ├── terminal.gd
│   │   │   ├── minigame_circuit.tscn
│   │   │   └── minigame_circuit.gd
│   │   └── interactable/
│   │       ├── door.tscn
│   │       └── vent.tscn
│   ├── world/                 # Level scenes
│   │   ├── test_room.tscn     # Phase 1 vertical slice
│   │   └── level_template.tscn
│   ├── ui/                    # HUD, menus, minigame UI
│   │   ├── hud.tscn
│   │   ├── hud.gd
│   │   ├── pause_menu.tscn
│   │   └── minigame_ui.tscn
│   └── systems/               # Non-instanced system scenes
│       ├── input_manager.tscn
│       ├── save_manager.tscn
│       └── audio_manager.tscn
├── scripts/                   # Shared GDScript (autoloads, utils)
│   ├── autoloads/
│   │   ├── globals.gd         # Global constants, enums, signals
│   │   ├── input_map.gd       # Input action definitions
│   │   ├── save_manager.gd    # Save/load (Phase 3+)
│   │   └── audio_manager.gd
│   ├── core/
│   │   ├── stealth_system.gd  # Detection logic (vision, sound, suspicion)
│   │   ├── movement.gd        # Shared movement helpers
│   │   └── interaction.gd     # Interaction interface
│   ├── gameplay/
│   │   ├── player_controller.gd
│   │   ├── guard_ai.gd
│   │   └── hacking_minigame.gd
│   └── utils/
│       ├── math_utils.gd
│       ├── signal_bus.gd      # Global signal bus (optional)
│       └── performance.gd     # Debug/profiling helpers
├── shaders/                   # Custom shaders
│   ├── outline.shader         # Interaction highlight
│   ├── vision_cone.shader     # Guard vision visualization
│   └── hud_shader.shader      # UI effects
├── tests/                     # GUT unit/integration tests
│   ├── unit/
│   └── integration/
└── tools/                     # Editor scripts, import pipelines
    └── asset_import.gd
```

---

## Scene Architecture

### Core Node Hierarchy (Runtime)
```
Main (Node)
├── World (Node3D)                 # Current level root
│   ├── LevelGeometry (StaticBody3D + CollisionShape3D + MeshInstance3D)
│   ├── Player (CharacterBody3D)
│   │   ├── Camera3D (orthographic)
│   │   ├── SpringArm (for smooth follow)
│   │   └── InteractionRayCast
│   ├── Guards (Node3D)            # Guard instances
│   │   ├── Guard_1 (CharacterBody3D)
│   │   │   ├── VisionCone (MeshInstance3D + shader)
│   │   │   └── SuspicionMeter (CanvasLayer)
│   │   └── ...
│   ├── Terminals (Node3D)         # Hackable objects
│   │   └── Terminal_A (StaticBody3D + Area3D)
│   └── Interactables (Node3D)     # Doors, vents, etc.
├── HUD (CanvasLayer)
│   ├── Minimap
│   ├── SuspicionIndicator
│   ├── HackPrompt
│   └── ControlsOverlay (debug)
├── MinigameUI (CanvasLayer)       # Activated during hacking
├── PauseMenu (CanvasLayer)
└── Systems (Node)                 # Autoloads instanced here for scene access
    ├── InputManager
    ├── AudioManager
    └── SaveManager
```

### Autoloads (Project Settings → Autoload)
| Name | Script | Purpose |
|------|--------|---------|
| `Globals` | `scripts/autoloads/globals.gd` | Enums, constants, global signals |
| `InputMap` | `scripts/autoloads/input_map.gd` | Input action registration |
| `SaveManager` | `scripts/autoloads/save_manager.gd` | Persistent data (Phase 3+) |
| `AudioManager` | `scripts/autoloads/audio_manager.gd` | SFX/music pooling |
| `StealthSystem` | `scripts/core/stealth_system.gd` | Central detection logic |

---

## Input System (InputMap Actions)

| Action | Type | Keys (Editor) | Keys (Android) | Purpose |
|--------|------|---------------|----------------|---------|
| `move_left` | Axis (X-) | A / Left | Virtual stick X- | Strafe left |
| `move_right` | Axis (X+) | D / Right | Virtual stick X+ | Strafe right |
| `move_forward` | Axis (Y-) | W / Up | Virtual stick Y- | Move forward |
| `move_backward` | Axis (Y+) | S / Down | Virtual stick Y+ | Move backward |
| `sprint` | Button | Shift | Button (hold) | Sprint modifier |
| `crouch` | Button | Ctrl | Button (toggle) | Crouch/stealth |
| `interact` | Button | E / Space | Button (tap) | Interact/hack |
| `camera_orbit` | Axis2D | Mouse drag | Right stick / swipe | Orbit camera |
| `camera_zoom` | Axis | Scroll | Pinch | Zoom (clamped) |
| `pause` | Button | Esc | Button (top-right) | Pause menu |
| `hack_up` | Button | W / Up | D-pad up | Minigame navigation |
| `hack_down` | Button | S / Down | D-pad down | Minigame navigation |
| `hack_left` | Button | A / Left | D-pad left | Minigame navigation |
| `hack_right` | Button | D / Right | D-pad right | Minigame navigation |
| `hack_confirm` | Button | Enter / Space | Button (large) | Minigame confirm |
| `hack_cancel` | Button | Esc / Q | Button (small) | Minigame cancel |

**Implementation:** `scripts/autoloads/input_map.gd` registers all actions at runtime; Android touch controls map to same actions via `InputManager` (virtual sticks, buttons).

---

## Asset Strategy

| Category | Source | Pipeline | Budget |
|----------|--------|----------|--------|
| Environment | Kenney "Industrial" / "Prototype" packs | Blender → GLB → Godot | 512px albedo atlas, 1k tris per prop |
| Characters | Kenney "Character" + custom Blender low-poly | Rig in Blender → GLB | 2k tris (player), 1.5k tris (guard) |
| UI/Icons | Kenney "UI Pack" + procedural (Godot Shader) | Direct import | 256px atlas |
| VFX | Godot Particles2D/3D + shader | In-engine | < 50 particles simultaneous |
| Audio | Freesound (CC0) + synthesized (Bfxr) | OGG Vorbis, 44.1 kHz | < 500 KB total |
| Shaders | Custom (outline, vision, hud) | Written in Godot shader language | Minimal ALU |

**Texture Atlasing:** Single 512×512 atlas per scene (environment, characters, UI). Use `TextureAtlas` resource in Godot 4.3.

**Import Settings (project.godot):**
```ini
[texture_importer]
default_filter=Nearest
default_repeat=Disabled
compress/mode=VRAM (ASTC for Android)
compress/lossy_quality=0.7
mipmaps/generate=true
```

---

## Performance Budgets (Enforced via CI + Manual Review)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Triangles/frame | ≤ 15,000 | Godot profiler (Monitors → 3D) |
| Draw calls | ≤ 30 | Rendering → Draw Calls |
| Texture memory | ≤ 64 MB | Debug → Video Memory |
| Script frame time | ≤ 8 ms | Script → Frame Time |
| Physics frame time | ≤ 4 ms | Physics → Frame Time |
| Total frame time | ≤ 33 ms (30 FPS) | Performance → FPS |
| APK size (ARM32) | ≤ 80 MB | `aapt dump badging` |
| RAM (running) | ≤ 1.5 GB | `adb shell dumpsys meminfo` |

**Optimization Rules:**
- No dynamic lights in Phase 1–2 (baked lightmaps only)
- Static geometry merged via `MeshInstance3D` + `MultiMeshInstance3D`
- Guard vision cones: shader-based, no extra meshes
- Particles: `GPUParticles3D` with `local_coords=true`
- Audio: `AudioStreamPlayer3D` with `max_db=-6`, bus compression

---

## Phased Roadmap

### Phase 0 — Repository Bootstrap (This Plan)
- [ ] Create `project.godot` with 4.3 settings, Compatibility renderer, Android export
- [ ] Create `export_presets.cfg` (ARM32 + ARM64, debug/release)
- [ ] Set up folder structure (all directories above)
- [ ] Add `README.md`, `CREDITS.md` (placeholder)
- [ ] Configure `.gitignore` for Godot/Android
- [ ] **Completion:** `godot --headless --check-only` passes; folder structure exists

### Phase 1 — Vertical Slice: Single Room (Playable Prototype)
**Scope:** One enclosed room, player movement, one guard patrol, one hackable terminal, basic HUD.

| Task | Description | Completion Criteria |
|------|-------------|---------------------|
| 1.1 | `project.godot` + autoloads (Globals, InputMap, AudioManager) | Autoloads load without error |
| 1.2 | InputMap actions registered; `InputManager` scene with virtual sticks/buttons for Android | Touch controls work in editor preview |
| 1.3 | `Player` scene: CharacterBody3D, orthographic Camera3D, movement (walk/sprint/crouch), interaction raycast | WASD + virtual stick move; camera orbits; 30 FPS in empty scene |
| 1.4 | `TestRoom` level: floor, walls, ceiling (CSG or MeshInstance3D), baked lightmap | Room renders, collisions work |
| 1.5 | `Guard` scene: CharacterBody3D, patrol path (Path3D + PathFollow3D), vision cone (shader), suspicion meter (0–100), states: Idle → Suspicious → Alert | Guard patrols; detects player in cone; suspicion rises/falls |
| 1.6 | `StealthSystem` autoload: vision cone math, sound propagation (radius), suspicion accumulation/decay | Unit tests pass for detection logic |
| 1.7 | `Terminal` scene: Area3D trigger, interaction prompt, minigame launch | Player enters range → prompt shows → press interact → minigame opens |
| 1.8 | `HackingMinigame` (Circuit Trace): grid of nodes, draw path from start to end within time, touch/mouse input | Minigame plays; success/fail returns to world |
| 1.9 | `HUD` scene: suspicion indicator, interaction prompt, minimap placeholder | HUD updates in real time |
| 1.10 | `Main` scene: installs World, Player, Guard, Terminal, HUD; handles pause/resume | Full loop: move → avoid guard → hack terminal → win/lose |
| 1.11 | Android export preset: ARM32 + ARM64, Compatibility renderer, icons, permissions | `godot --export-release "Android" build/android/veil_circuit.apk` succeeds |
| 1.12 | **Static validation in Kilo:** `godot --headless --check-only`, `godot --headless --script-classes`, GUT unit tests for `StealthSystem`, `HackingMinigame` | All static checks pass |

**Phase 1 Completion:** APK builds, installs on device, plays at 30 FPS on Realme 10 (or equivalent 4 GB ARM32), core loop works.

### Phase 2 — Core Systems Polish + Micro-District
| Task | Description |
|------|-------------|
| 2.1 | Guard AI: investigation, search, return to patrol, alert propagation |
| 2.2 | Sound system: footsteps (player speed-based), distractions (thrown objects) |
| 2.3 | Player abilities: vent crawl, door peek, silent takedown (from behind) |
| 2.4 | Hacking minigame variants: pattern match, timing, logic gate |
| 2.5 | `MicroDistrict` level: 3 buildings, rooftops, 3 guards, 3 terminals |
| 2.6 | Save/Load: `SaveManager` (JSON → `user://save.json`), checkpoint system |
| 2.7 | Pause menu: resume, restart, settings (graphics, controls), quit |
| 2.8 | Settings persistence: `ProjectSettings.set_setting()` + `ConfigFile` |
| 2.9 | Performance pass: LOD, occlusion culling, texture atlas verification |
| 2.10 | Android test on ARM32 + ARM64 devices; profile with `adb logcat` + Godot profiler |

### Phase 3 — City Systems + Progression
| Task | Description |
|------|-------------|
| 3.1 | Compact city map: districts, fast travel (subway), safehouses |
| 3.2 | Security pursuit system: wanted level, drones, roadblocks |
| 3.3 | Vehicle system: motorcycle (physics-based, simple) |
| 3.4 | Upgrade tree: hacking speed, stealth, sprint, battery |
| 3.5 | Mission structure: main + side objectives, dynamic guard spawns |
| 3.6 | UI overhaul: map, mission log, upgrade screen, inventory |
| 3.7 | Audio polish: adaptive music, guard barks, environmental ambience |
| 3.8 | Localization framework (CSV → `TranslationServer`) |
| 3.9 | Full Android release build: signing, Play Console bundle (AAB), store assets |

### Phase 4 — Live Ops (Post-Launch, Optional)
- Telemetry (opt-in, local only)
- Challenge modes (time trial, ghost, no-hack)
- Level editor (export/share `.lvl` files)
- Modding API (resource packs)

---

## Testing Strategy

| Layer | Tool | Runs In | What It Catches |
|-------|------|---------|-----------------|
| **Static** | `godot --headless --check-only` | Kilo Code | Missing resources, script errors, cyclic deps |
| **Static** | `godot --headless --script-classes` | Kilo Code | Class registration, naming conflicts |
| **Unit** | GUT (Godot Unit Test) | Kilo (headless) | `StealthSystem`, `HackingMinigame`, `SaveManager` logic |
| **Integration** | GUT + headless scene instantiation | Kilo (headless) | Scene loading, signal wiring, autoload init |
| **Performance** | Godot Profiler (Monitors) | Local device/editor | Frame time, draw calls, memory |
| **Device** | `adb install` + manual play | Physical device (Realme 10, ARM32/ARM64) | Touch controls, thermal throttling, battery, OS interruptions |
| **Export** | `godot --export-release` | Local machine (Linux/Windows/macOS) | APK/AAB validity, signing, permissions |

**Kilo Code Can Do:** Static checks, unit/integration tests (if Godot headless installed), linting GDScript (`gdlint` or `godot --headless --lint`), plan validation.

**Requires External:** Godot editor (visual scene building), Android SDK + JDK (export), physical device (touch/performance), GPU (rendering validation).

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Godot 4.3 Android export broken for ARM32 | Medium | High | Test export early (Phase 1.11); fallback to 4.2 if needed |
| Compatibility renderer lacks feature X | Low | Medium | Prototype shaders early; document workarounds |
| 15k tris budget too tight for 2.5D | Medium | High | Profile Phase 1 room; adjust LOD/atlas strategy |
| Virtual stick feel bad on mobile | Medium | Medium | Iterate in Phase 1.2; test on device ASAP |
| Minigame too hard/frustrating on touch | Medium | Medium | Playtest early; add accessibility (auto-solve, time extension) |
| No GPU in Kilo → no rendering tests | Certain | Medium | Accept; rely on device testing for visual/perf |
| Asset pipeline (Blender → Godot) breaks | Low | Low | Document import settings; use GLB 2.0 |
| APK > 80 MB on ARM32 | Medium | Medium | Strip debug symbols; compress textures (ASTC); split assets via pck |

---

## First Task (Code Mode Entry Point)

**Task 0.1 — Bootstrap Godot Project**

Create the minimal Godot 4.3 project structure in `/workspace/app`:

1. `project.godot` with:
   - `config_version=5`
   - `rendering/renderer/rendering_method="compatibility"`
   - `application/run/main_scene="res://scenes/main/main.tscn"`
   - Android export settings (package name, version, orientation=landscape)
   - Input map actions (all 16 from table above)
   - Autoload list (Globals, InputMap, AudioManager, StealthSystem, SaveManager)
   - Physics: 60 Hz, 3D physics enabled
   - Display: window width/height 1280×720 (landscape), resizable=false

2. `export_presets.cfg` with two presets:
   - `Android Debug` (ARM32 + ARM64, debug symbols, `runnable=true`)
   - `Android Release` (ARM32 + ARM64, strip symbols, `runnable=false`)

3. Folder structure (all directories from **Folder Structure** section)

4. `scripts/autoloads/globals.gd` — enums: `GuardState {IDLE, SUSPICIOUS, ALERT}`, `HackResult {SUCCESS, FAIL, CANCEL}`, global signals

5. `scripts/autoloads/input_map.gd` — registers all 16 actions at runtime (idempotent)

6. `scripts/autoloads/audio_manager.gd` — skeleton (bus layout, play_sfx, play_music)

7. `scripts/core/stealth_system.gd` — skeleton with `calculate_visibility(player_pos, guard_pos, guard_dir, cone_angle, cone_range) -> float` and `calculate_suspicion_delta(visibility, distance, sound_level) -> float`

8. `.gitignore` for Godot + Android (`.godot/`, `build/`, `*.apk`, `*.aab`, `*.keystore`, `local://`, `user://`)

9. `README.md` — project name, Godot version, how to run/export

10. `CREDITS.md` — placeholder for CC0 attributions

**Validation (run in Kilo after implementation):**
```bash
godot --headless --check-only
godot --headless --script-classes
# Should exit 0 with no errors
```

**Do not:** Create scenes, player, guard, or level yet. Only project config, autoloads, and folder skeleton.

---

## Open Questions (Marked Out of Scope for Phase 0)
- Exact keymap for keyboard vs. gamepad (beyond mobile)
- Localization languages (start with EN only)
- Monetization (confirmed: none)
- Multiplayer (confirmed: single-player only)
- Console/desktop ports (later, if at all)

---

## Next Steps After Phase 0
1. Switch to implementation agent
2. Execute Task 0.1 (bootstrap)
3. Validate static checks pass
4. Proceed to Phase 1.1–1.12 (vertical slice)

---

*Plan saved to `.kilo/plans/1792814265139-veil-circuit-implementation-plan.md`*