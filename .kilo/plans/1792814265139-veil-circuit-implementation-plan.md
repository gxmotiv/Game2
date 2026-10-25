# VEIL CIRCUIT — Minimal Recovery Plan for Android Export

## Problem Statement
Android export fails with generic "configuration errors" despite GDScript fixes. Latest workflow run (40174995096) fails with "workflow file issue" - likely GDScript escaping in YAML heredoc.

## Root Cause
Validation script embedded as inline GDScript heredoc in YAML causes escaping issues:
- GDScript regex `(\\.[a-z0-9_]*)*` contains backslashes
- YAML heredoc + bash heredoc + GDScript escaping = fragile
- Generic "configuration errors" suggests validation script fails silently

## Minimal Fix (Single Commit)

### Files to Change

| File | Change |
|------|--------|
| `.github/workflows/android-build.yml` | Replace inline validation script with `godot --script res://scripts/validate_export.gd` |
| `scripts/validate_export.gd` | **NEW** - Move validation script from inline heredoc to committed file |

### Changes Detail

**File: `.github/workflows/android-build.yml`**
```yaml
# REPLACE the "Validate export preset" step (lines ~122-240) with:
- name: Validate export preset
  run: |
    # Validation script is committed at scripts/validate_export.gd
    godot --headless --script res://scripts/validate_export.gd 2>&1
```

**File: `scripts/validate_export.gd` (NEW)**
```gdscript
extends SceneTree

func _init():
    # [Same validation logic as inline script, but without escaping issues]
    # [Full validation logic preserved from current workflow]
    quit(0)
```

### Why This Works
- ✅ Eliminates YAML heredoc + bash heredoc + GDScript escaping chain
- ✅ Script is version-controlled, debuggable, testable locally
- ✅ Eliminates the "workflow file issue" class of errors
- ✅ No GDScript escaping in bash heredoc + YAML

## Validation Plan

1. **Local syntax check:** `godot --headless --check-only --path /workspace/app` (already passes)
2. **Script class registration:** `godot --headless --script-classes` (already passes)
3. **YAML syntax:** `yamllint .github/workflows/android-build.yml` (or `python -c "import yaml; yaml.safe_load(...)"`)
4. **Push & monitor** GitHub Actions run on `kilo/airy-chime-uvv`

## Rollback Plan
If validation fails, revert to commit `8578f7d` (last known working workflow syntax) and debug validation script locally.

## Risk Assessment
- **Risk:** LOW - Only moves existing validation logic to a file
- **Impact:** HIGH - Unblocks Android export debugging
- **Scope:** 2 files changed, no gameplay code touched

---

## Open Questions (Need Your Decision)

1. **Add `--verbose` to export command?** Low risk, adds diagnostic output. (Recommended: YES)
2. **Keep `if-no-files-found: error` on artifact upload?** Prevents false success. (Current: YES)
3. **Run `godot --headless --check-only` as explicit workflow step?** Explicit validation gate. (Recommended: YES)

---

*Ready for implementation upon approval. Will create `scripts/validate_export.gd` and update workflow in single commit.*