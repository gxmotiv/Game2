# VEIL CIRCUIT — Final Android Export Recovery Plan

## Problem Summary

**Confirmed Facts:**
- Script parse errors FIXED (verified locally with `godot --headless --check-only`)
- Previous fixes preserved: `scenes/main/main.gd` (Systems removed), `scripts/core/interaction.gd` (static removed), `scripts/utils/performance.gd` (unsupported OS APIs removed), `project.godot` (InteractionSystem autoload added)
- Android export fails with generic "configuration errors" - no specific validation errors visible

**Likely Root Cause:**
- GDScript heredoc in YAML workflow (`<<'ENDOFSCRIPT'`) causes "workflow file issue" - this is the most probable cause of "workflow file issue" failures
- Validation script uses editor-only APIs (`EditorExport`, `EditorSettings`) that don't work in `--headless --script` mode

**Unconfirmed:**
- Whether `--editor-settings` flag works in headless export
- Whether `EditorExport.validate_export_preset()` API exists in Godot 4.3

## Exact Changes Required

### Files to Modify (Only These)

| File | Action |
|------|--------|
| `.github/workflows/android-build.yml` | **Modify** - Remove validation step; fix export command |
| `export_presets.cfg` | **No change** (verify only) |

### Exact Workflow Diff

```diff
--- a/.github/workflows/android-build.yml
+++ b/.github/workflows/android-build.yml
@@ -119,131 +119,19 @@ jobs:
           echo "Export templates verified"
 
-      - name: Validate export preset
-        run: |
-          cat > /tmp/validate_export.gd <<'ENDOFSCRIPT'
-extends SceneTree
-
-func _init():
-    # Load the export preset
-    var preset = ProjectSettings.get_value("export/presets/0")
-    if not preset:
-        print("ERROR: No export preset found at index 0")
-        quit(1)
-    
-    # Check preset properties
-    print("Preset name: ", preset.get("name", "unknown"))
-    print("Preset platform: ", preset.get("platform", "unknown"))
-    
-    # Check package settings
-    var pkg_name = preset.get("package/unique_name", "")
-    var pkg_display = preset.get("package/name", "")
-    print("Package unique_name: ", pkg_name)
-    print("Package display name: ", pkg_display)
-    
-    if pkg_name.empty():
-        print("ERROR: package/unique_name is empty")
-    else:
-        # Validate package name format
-        if not pkg_name.match("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)*$"):
-            print("ERROR: Invalid package name format: ", pkg_name)
-    
-    if pkg_display.empty():
-        print("WARNING: package/name (display name) is empty")
-    
-    # Check Android-specific settings
-    var min_sdk = preset.get("android/min_sdk", 0)
-    var target_sdk = preset.get("android/target_sdk", 0)
-    var version_code = preset.get("android/version_code", 0)
-    var version_name = preset.get("android/version_name", "")
-    
-    print("Min SDK: ", min_sdk)
-    print("Target SDK: ", target_sdk)
-    print("Version code: ", version_code)
-    print("Version name: ", version_name)
-    
-    if min_sdk < 1:
-        print("ERROR: min_sdk must be >= 1")
-    if target_sdk < 1:
-        print("ERROR: target_sdk must be >= 1")
-    if target_sdk < min_sdk:
-        print("ERROR: target_sdk must be >= min_sdk")
-    if version_code <= 0:
-        print("ERROR: version_code must be > 0")
-    if version_name.empty():
-        print("ERROR: version_name is empty")
-    
-    # Check keystore
-    var debug_keystore = preset.get("android/keystore/debug", "")
-    var release_keystore = preset.get("android/keystore/release", "")
-    print("Debug keystore: '", debug_keystore, "'")
-    print("Release keystore: '", release_keystore, "'")
-    
-    # Check permissions
-    var perms = preset.get("android/permissions", [])
-    print("Permissions: ", perms)
-    
-    # Check editor settings for SDK/JDK paths
-    var sdk_path = EditorSettings.get_setting("export/android/sdk_path", "")
-    var jdk_path = EditorSettings.get_setting("export/android/jdk_path", "")
-    print("SDK path from editor settings: ", sdk_path)
-    print("JDK path from editor settings: ", jdk_path)
-    
-    if sdk_path.empty():
-        print("WARNING: export/android/sdk_path not set in editor settings")
-    if jdk_path.empty():
-        print("WARNING: export/android/jdk_path not set in editor settings")
-    
-    # Try to validate export preset using Godot's export API
-    var export = EditorExport.get_singleton()
-    if export:
-        var preset_list = export.get_export_presets()
-        print("Available presets: ", preset_list.size())
-        for i in range(preset_list.size()):
-            var p = preset_list[i]
-            print("Preset ", i, ": ", p.get("name", "unknown"), " platform: ", p.get("platform", "unknown"))
-        
-        # Try to get the Android export platform
-        var android_export = export.get_export_platform("Android")
-        if android_export:
-            print("Android export platform found")
-            # Get the preset index for "Android Debug"
-            var preset_idx = -1
-            for i in range(preset_list.size()):
-                if preset_list[i].get("name") == "Android Debug":
-                    preset_idx = i
-                    break
-            
-            if preset_idx >= 0:
-                print("Found Android Debug preset at index ", preset_idx)
-                # Validate the preset
-                var errors = android_export.validate_export_preset(preset_idx)
-                if errors.size() > 0:
-                    print("VALIDATION ERRORS:")
-                    for err in errors:
-                        print("  - ", err)
-                else:
-                    print("Preset validation passed!")
-            else:
-                print("ERROR: Android Debug preset not found")
-        else:
-            print("ERROR: Android export platform not found")
-    
-    quit(0)
-ENDOFSCRIPT
-          
-          # Run validation script
-          godot --headless --script /tmp/validate_export.gd 2>&1
-
       - name: Build Android Debug APK
         run: |
           set -e
           # Export with debug-level logging to capture configuration errors
           export GODOT_ANDROID_SDK_PATH="$HOME/android-sdk"
           export GODOT_ANDROID_JDK_PATH="$JAVA_HOME"
-          godot --headless --log-level=debug --export-release "Android Debug" build/android/veil_circuit_debug.apk --editor-settings $HOME/.config/godot/editor_settings-4.tres 2>&1
+          godot --headless --verbose --export-debug "Android Debug" build/android/veil_circuit_debug.apk 2>&1
           # Verify APK was created and is non-empty
           if [ ! -f build/android/veil_circuit_debug.apk ]; then
             echo "ERROR: APK not created. Godot export failed."
             exit 1
           fi
           if [ ! -s build/android/veil_circuit_debug.apk ]; then
             echo "ERROR: APK file is empty"
             exit 1
           fi
           ls -la build/android/
 
       - name: Upload APK artifact
```

### Additional Changes

**Add CI validation step** (insert after "Verify editor settings"):

```yaml
      - name: Validate project syntax
        run: |
          godot --headless --check-only --path "$GITHUB_WORKSPACE"
```

**Update Build Android Debug APK step** (exact replacement):

```yaml
      - name: Build Android Debug APK
        run: |
          set -e
          export GODOT_ANDROID_SDK_PATH="$HOME/android-sdk"
          export GODOT_ANDROID_JDK_PATH="$JAVA_HOME"
          godot --headless --verbose --export-debug "Android Debug" build/android/veil_circuit_debug.apk 2>&1
          if [ ! -f build/android/veil_circuit_debug.apk ]; then
            echo "ERROR: APK not created. Godot export failed."
            exit 1
          fi
          if [ ! -s build/android/veil_circuit_debug.apk ]; then
            echo "ERROR: APK file is empty"
            exit 1
          fi
          ls -la build/android/
```

**Keep all other steps unchanged:**
- SDK installation ✅
- Export template installation ✅  
- JDK setup ✅
- Editor settings generation ✅
- Artifact upload ✅
- APK info reporting ✅

### Files NOT Changed

| File | Status |
|------|--------|
| `export_presets.cfg` | No change (already correct) |
| `project.godot` | No change (already correct) |
| `scenes/main/main.gd` | No change (fixed) |
| `scripts/core/interaction.gd` | No change (fixed) |
| `scripts/utils/performance.gd` | No change (fixed) |
| `scripts/autoloads/*.gd` | No change (fixed) |
| All gameplay scripts | No change |

---

## Validation Plan (Exact Sequence)

| Step | Command | Environment | Pass Criteria |
|------|---------|-------------|---------------|
| 1 | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/android-build.yml'))"` | Local | Exit 0 |
| 2 | `godot --headless --check-only --path /workspace/app` | Local/CI | Exit 0 |
| 3 | `godot --headless --script-classes --path /workspace/app` | Local/CI | Exit 0, 20+ classes |
| 4 | GitHub Actions run completes "Build Android Debug APK" step | CI | Exit 0 |
| 5 | APK artifact `veil-circuit-debug-apk` uploaded | CI | Downloadable |
| 6 | APK size > 0 bytes | CI | `stat -c%s > 0` |

---

## Files Changed (Only These)

| File | Change |
|------|--------|
| `.github/workflows/android-build.yml` | Remove validation step; fix export command; add syntax check step |

**No other files modified.**

---

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| YAML syntax error | LOW | Validated with `yamllint` or `python -c "import yaml; yaml.safe_load(...)"` before push |
| Export still fails | MEDIUM | Verbose output will show specific errors; Godot 4.3 `--export-debug` is standard |
| `--editor-settings` removed | LOW | Headless export reads `project.godot` and `export_presets.cfg` directly |

---

## Verification Commands (Run Before Push)

```bash
# 1. YAML syntax
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/android-build.yml'))"

# 2. Godot project syntax (local)
godot --headless --check-only --path /workspace/app

# 3. Script classes (local)
godot --headless --script-classes --path /workspace/app
```

---

## Open Questions (Need Your Decision)

1. **Keep `--verbose` on export?** (Recommended: YES)
2. **Add explicit `godot --headless --check-only` as workflow step?** (Recommended: YES)
3. **Add `godot --headless --script-classes` as workflow step?** (Recommended: YES)

---

## Approval

**Ready for implementation upon approval.** The plan addresses all feedback:
- ✅ Heredoc labeled as *likely* cause (not confirmed)
- ✅ Only validation step removed, all other steps preserved
- ✅ Added `godot --headless --check-only` CI validation step
- ✅ `--export-debug --verbose` with exit code preserved
- ✅ APK non-empty verification before upload
- ✅ No unnecessary validation scripts
- ✅ No export preset changes without evidence
- ✅ Exact workflow diff provided
- ✅ All changes on `kilo/airy-chime-uvv`

**Waiting for approval to implement.**