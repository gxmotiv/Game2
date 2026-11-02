# VEIL CIRCUIT — Copilot Instructions

You are contributing to VEIL CIRCUIT, an original mobile-first 2.5D stealth/hacking game built with Godot 4.3 and GDScript.

## Non-negotiable project constraints
- Target: low-end Android, including 4 GB RAM and PowerVR-class mobile GPUs.
- Renderer: Godot Compatibility (GLES3); landscape; offline-first.
- Budget: ₹0. Use Godot built-ins and genuinely free/open-source assets with verified per-asset licences. No paid services, paid assets, API keys, subscriptions, ads, tracking, or required runtime downloads.
- Do not copy Watch Dogs maps, characters, logos, story, UI, music, or proprietary assets. Build original settings, characters and systems.
- Do not claim a feature is implemented unless code and a test or reproducible manual check demonstrate it.

## Engineering workflow
1. Research the existing scene tree, scripts, project settings and tests before editing. Trace callers and signal connections.
2. Write a short plan with files to change, risks, acceptance criteria and a rollback path.
3. Prefer a failing test or reproducible bug report before implementation. Make the smallest coherent change.
4. Run Godot headless import/parse checks, relevant gameplay smoke tests and Android export checks where available.
5. Review the final diff for regressions, unused code, mobile performance, input behavior and licence/attribution accuracy.
6. Report exact commands and results. Separate passed, failed, skipped and not-run checks. Never claim physical-device testing from CI.

## Godot and performance rules
- Stay compatible with Godot 4.3 APIs; do not silently upgrade the engine.
- Prefer MultiMesh for repeated decorative geometry and shared materials for repeated surfaces.
- Avoid per-frame allocations, unnecessary nodes, excessive draw calls, real-time shadows, expensive screen-space effects and large texture imports.
- Profile before increasing resolution, texture sizes, lighting, particles, fog or scene density.
- Preserve touch joystick, camera-look, sprint, crouch, interact and pause controls.
- Do not alter collision layers, input actions, camera ownership, movement tuning, export settings or project renderer without explaining why and adding checks.
- Keep important gameplay feedback readable on a small phone screen.

## Quality gates
- Bug fixes need a regression test or clear manual reproduction/verification steps.
- New gameplay systems need success, failure, cooldown/state-reset and touch-input coverage.
- Visual changes need a low-end fallback and a performance rationale.
- Asset additions need source URL, exact licence, creator/name when required, import settings and size notes in CREDITS.md.
- Never store secrets in the repository or logs.

## Collaboration and reporting
- Work on a feature branch; do not push directly to main.
- Keep changes focused and open a PR with summary, tests, risks and screenshots/video when useful.
- Do not merge a PR or delete user work without explicit approval.
- If a tool, asset, runtime, device or permission is unavailable, say so plainly and give the next verifiable step.
- At the end report: changed files, behavior added, checks run with results, known limitations, and exact commit/PR link.

## Review standard
Prioritise correctness and playable game feel over feature count. Challenge assumptions, inspect actual source and tests, and identify missing evidence. A polished compact mission is more valuable than an unfinished open world.