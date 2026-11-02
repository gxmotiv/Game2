---
mode: agent
description: Reproduce a VEIL CIRCUIT bug, add a regression check, then implement the smallest fix.
---

Use a test-first workflow for the requested VEIL CIRCUIT change.

1. Inspect existing tests and reproduce the current behavior.
2. Add or update a regression test that fails for the reported bug, where feasible.
3. Run the focused test and record the actual failure.
4. Implement the smallest fix without unrelated refactors.
5. Run the focused test, gameplay smoke tests, Godot parse/import checks and Android export if available.
6. Review touch input, scene lifecycle, signals, null references and low-end performance.

If a test cannot be automated, provide precise phone/manual reproduction steps. Never report a test as passed if it was not run.