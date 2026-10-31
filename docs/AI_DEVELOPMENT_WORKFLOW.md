# VEIL CIRCUIT AI-Assisted Development Workflow

This project uses a deliberately small, repository-local workflow inspired by the open-source [Everything Claude Code (ECC)](https://github.com/affaan-m/ECC) engineering approach.

## What is integrated

- `.github/copilot-instructions.md`: project rules automatically supplied to GitHub Copilot Chat in VS Code/Codespaces.
- `.github/prompts/`: reusable plan, test-driven-development, security-review, build-fix and gameplay-review prompts.
- `.vscode/settings.json`: enables VS Code chat prompt files.

This is an **ECC-inspired Copilot Chat subset**, not a full ECC runtime installation. ECC's own support matrix describes Copilot Chat as instruction/prompt-file based; ECC hooks are not ported to Copilot Chat. Copilot CLI has additional skill/agent support, but that is a different interface.

## Recommended team workflow

1. **REA (when available):** inspect the built game/runtime, reproduce visible behavior, capture evidence and compare behavior against the intended design. REA is not assumed to be installed or connected merely because setup instructions exist.
2. **Copilot in Codespaces:** use `/plan` before substantial edits, then `/tdd` or `/build-fix` to implement and validate. Use `/gameplay-review` and `/security-review` before opening a PR.
3. **ChatGPT:** coordinate milestones, review diffs and test evidence, challenge unsupported claims, and check GitHub branches/PRs/CI. ChatGPT does not see the live Codespaces terminal unless its output is shared or exposed through a connected tool.
4. **GitHub Actions:** run reproducible Godot and Android checks. CI is not a substitute for testing on the target Android phone.
5. **Human device test:** install the APK, record FPS/stutters, heat, memory symptoms, touch-control behavior and screenshots. Feed reproducible findings back into an issue/PR.

## Safe operating rules

- Keep each feature on its own branch and use PRs.
- Do not let multiple agents edit the same branch/file concurrently.
- Treat generated plans and AI reviews as suggestions; inspect the actual diff.
- Do not merge automatically just because an AI says the work is complete.
- Never paste API keys, passwords, signing secrets or personal account data into prompts or commits.
- Keep the project offline-first and within the zero-budget policy.

## ECC upstream

ECC is MIT-licensed open source. This repository does not vendor the full ECC source tree or claim its hooks/agents are installed. Consult the upstream README and platform support matrix before enabling additional ECC components: https://github.com/affaan-m/ECC

## Definition of done for a game feature

A feature is done only when its player-visible behavior is implemented, regression checks pass, Android build succeeds, the diff is reviewed, and any required real-phone checks are recorded. State any missing evidence explicitly.
