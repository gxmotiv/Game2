---
mode: agent
description: Diagnose and fix VEIL CIRCUIT Godot import, runtime, CI or Android export failures.
---

First identify the failing command and exact log evidence. Reproduce the failure with the narrowest available command.

Check Godot version (must remain 4.3), project import, GDScript parse errors, shader compilation, missing resources, scene paths, Android SDK/JDK/export templates and workflow configuration.

Fix root causes, not symptoms. Avoid broad dependency or engine upgrades. Re-run the failed step and the closest regression tests. Report the exact error before and after, commands run, and anything still unverified. CI success is not proof of physical-device performance.