# VEIL CIRCUIT — City District Roadmap

## Design target

VEIL CIRCUIT is an original, mobile-first stealth-and-hacking game. The design reference is the systemic gameplay of open-world hacking games: the city is a tool, connected devices create opportunities, and a player can choose stealth, distraction, or a direct escape. This project does not copy Watch Dogs characters, story, map, logos, UI, audio, or proprietary assets.

The official Watch Dogs description highlights manipulating traffic lights, trains, drawbridges, electrical infrastructure, and other connected city systems. These are useful genre references, not a promise that every system already exists in VEIL CIRCUIT.

## Current district slice

- A compact 4×4-block city district generated from primitive geometry.
- Intersecting roads, sidewalks, lane markings, varied low-poly buildings, and a central junction.
- Batched MultiMesh visuals for roads, sidewalks, lane marks, lamps, and building exteriors to reduce draw calls.
- Collision bodies for the ground and buildings.
- Four terminal locations linked to separate security lights, so successful terminal hacks disable the linked light.
- A small number of guards to keep the district playable on low-end Android hardware.
- The existing touch movement, sprint, crouch, interact, pause, and circuit-hacking loop remains the foundation.

## Feature roadmap

### Phase A — Reliable core (current priority)
- Fix touch input and remove expensive work from repeated puzzle taps.
- Keep camera look independent from the movement joystick.
- Validate movement, terminal interaction, puzzle completion/failure, guard behavior, and pause/resume in automated smoke tests.
- Build a debug APK and test it on a real Android device before calling the release device-verified.

### Phase B — Hacking sandbox
- Security cameras: switch camera feeds and use them to scout routes.
- Distractable devices: hack a phone/speaker/alarm to pull a guard away.
- Traffic signal control: create a temporary traffic stop or safe crossing; avoid full vehicle physics until performance is measured.
- Network battery/cooldown: powerful hacks consume energy and recover over time.
- Clear hack prompts, range checks, cooldown indicators, and failure feedback.

### Phase C — Stealth and mission loop
- Guard patrol routes, vision checks, suspicion, investigation, search, and alert recovery.
- Mission objectives with optional routes: disable security, reach a data point, extract, and escape.
- Checkpoints, objective markers, mission results, and local save/progression.
- Sound distractions and simple takedown/avoidance rules, only after core stealth is stable.

### Phase D — Compact open-world systems
- Expand the district by streamed/loaded chunks rather than one enormous scene.
- Add an original vehicle prototype only after touch driving and collision are tested.
- Add a chase/wanted level, safehouses, side activities, and upgrades in small increments.
- Profile memory, draw calls, physics time, frame pacing, and APK size on the target phone after each expansion.

## Performance rules

- Target stable 30 FPS on a low-end Android phone; measure rather than assume.
- Use Godot's Compatibility renderer, low-poly meshes, shared materials, MultiMesh batching, limited real-time lights, and disabled real-time shadows by default.
- Avoid per-frame scene searches, per-tap texture generation, unnecessary physics bodies, and unbounded NPC counts.
- Prefer offline/local gameplay and free/open-source tooling. Do not introduce paid APIs, subscriptions, or services.

## Free asset policy

Use original procedural geometry first. If external assets are added, verify the exact pack's license and include its license/credit in CREDITS.md. Kenney's per-pack CC0 assets are one option; not every bundled marketplace collection is necessarily free, so use only packs explicitly marked free/CC0. Audio and fonts must be checked separately.

## Definition of done for each feature

1. It has a clear in-game interaction and feedback.
2. It works with touch controls and does not steal camera gestures.
3. It has a test or a documented manual test.
4. It does not regress the existing movement/hacking/pause loop.
5. Its performance impact is measured on the debug build; automated CI alone is not proof of physical-device performance.
