# VEIL CIRCUIT — Open-city development plan

## Current milestone: Nova Grid district

- Original procedural city layout (~300 × 300 metres), with a road grid, sidewalks, varied low-poly buildings, emissive windows and a central landmark.
- Reusable city network devices: traffic signals, security cameras and power relays, plus distributed hack terminals.
- Existing player movement, crouch/sprint, guard stealth, terminal circuit puzzle and pause flow remain the core interaction loop.
- Puzzle tile textures are cached so rotating a tile does not rebuild a 64 × 64 image on every touch. The success transition is shorter.
- Built from Godot primitives and project-owned GDScript: no paid assets, API keys, or online service required.

## Next systems, in order

1. **Mission layer:** objective chains, rewards, map markers, save/checkpoint state and optional side jobs.
2. **City simulation:** traffic lanes, simple vehicle driving, hackable traffic controls, pursuers and wanted/alert escalation.
3. **Surveillance network:** remote camera view, tagging visible guards, network links and timed hacks.
4. **Player tools:** deployable RC scout/drone with a light AI budget, collectible upgrades and a skill tree.
5. **World scale:** split the district into chunks and load nearby chunks only; add interiors after the city loop is stable.
6. **Polish:** original audio, UI feedback, accessibility settings, device profiling and Android memory/FPS checks.

## Device-first constraints

The first target is a modest Android phone. Keep shadows off, avoid real-time lights where possible, use MultiMesh for repeated windows and road markings, limit visible NPCs, and keep the render target modest. Add licensed CC0 assets only when a specific pack is needed; every pack's license should be checked individually. Do not import Watch Dogs assets or recreate its proprietary map/characters.

## Validation requirements

- Run the Godot editor import/parse check and boot the main scene.
- Run the automated movement, touch-control, pause and hacking smoke test.
- Verify that city generation and all scripted network devices load without parse errors.
- Export the Android debug APK in CI and test it on the physical target phone before calling the build phone-verified.
