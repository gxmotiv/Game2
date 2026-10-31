# REA (Reverse Engineer Anything) setup for VEIL CIRCUIT

REA is an optional local MCP server/CLI for evidence-based inspection of software you own or are authorized to analyze. Official project: https://github.com/morluto/rea

## Important boundary

Adding this guide to GitHub does **not** install REA into a remote Codex session or register an MCP server. REA must be installed and registered in the actual agent environment that will use it. Do not claim REA tools are available until the agent can see them after restart.

For ordinary analysis of this complete Godot source repository, use normal source and test tools first. Use REA when inspecting a built APK, a Godot PCK, or behavior that source inspection alone does not establish.

## Latest setup in a Codex-capable terminal

1. Check that Node.js and npm are available. Current REA documentation requires a supported Node release (for example Node 22.23.4+ or 24.22.1+; check the official README for current requirements).
2. In the terminal for the **same environment that runs your coding agent**, run:

   ```sh
   npx -y rea-agents@latest setup --client codex
   ```

3. Review the setup plan and approve only the configuration changes you want. Do not run this in a random GitHub web page; GitHub's file editor is not a terminal.
4. Run the readiness check supported by the installed version (the official guide documents `npx -y rea-agents@latest doctor` / `rea doctor`).
5. Restart the Codex/agent session and inspect its available MCP tools. Only proceed with REA if its tools actually appear. If Codex setup syntax differs in the installed release, follow the official installation guide: https://github.com/morluto/rea/blob/main/docs/installation.md

REA setup can change the selected agent's configuration. Review the plan rather than assuming `--yes` authorizes every change. REA and package downloads may be free/open source, but setup requires internet access and Node/npm; additional analysis providers have their own requirements. Do not install paid or licensed tools for this zero-budget project.

## VEIL CIRCUIT investigation workflow

When REA is connected:
- Inspect the project's built APK and/or Godot `.pck` only when useful, and record which exact file/version was analyzed.
- For APK internals, REA's documented Android analysis requires JADX and a full JDK on a supported desktop OS. Do not assume APK decompilation will work on an Android phone or in a restricted cloud terminal.
- For live Android device logs, package/process inspection, or transfers, REA documents a caller-supplied ADB requirement. Use only a device the owner authorizes.
- Correlate every finding with source files, build SHA, test output, or runtime evidence. Label hypotheses as hypotheses.
- Use the evidence to fix our own game code, then rerun CI and tests. Never claim a real-phone test was performed unless it actually was.
- Do not reverse engineer third-party software without authorization or copy proprietary assets/code. For Watch Dogs-inspired mechanics, implement original equivalents using free/open-source assets with compatible licenses.

## Zero-budget policy

- No paid APIs, subscriptions, assets, decompilers, or surprise billing.
- REA's MIT-licensed project does not make third-party providers or tools free. Use built-in/free capabilities only; skip optional paid tools.
- If the environment cannot install or run REA, continue with repository inspection and automated tests, and clearly state that REA was not used.
