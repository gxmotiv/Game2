---
name: reverse-engineer-anything
description: Use REA (Reverse Engineer Anything) when investigating a built APK, Godot PCK, or behavior requiring binary/runtime evidence. Do not use it for ordinary analysis of complete source code. Never claim REA was used unless its MCP tools are available and actually invoked.
---

# REA workflow for VEIL CIRCUIT

1. First check whether the active agent session actually exposes REA MCP tools. Do not assume that a GitHub guide means REA is installed.
2. If REA tools are absent, tell the user plainly and continue with normal source inspection/tests; do not claim REA findings.
3. If available, analyze only the user's own VEIL CIRCUIT APK/PCK or other authorized artifacts. Record the exact artifact/build SHA and the evidence returned.
4. Distinguish observed facts, source-derived facts, calculations, and hypotheses. Never present a hypothesis as a confirmed bug.
5. Apply findings to our own code, then rerun relevant automated tests and CI. Physical Android performance/controls still require the user's device test or an actual connected-device test.
6. Honor the zero-budget constraint: do not introduce paid services, commercial decompilers, paid assets, API keys, or billable dependencies.
7. For APK decompilation, verify documented requirements first (REA's current docs specify JADX and a full JDK on supported desktop OSes). For Android runtime inspection, verify ADB is available and the device is authorized.
8. Prefer the official setup guide: https://github.com/morluto/rea/blob/main/docs/installation.md
