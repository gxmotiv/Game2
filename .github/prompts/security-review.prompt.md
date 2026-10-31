---
mode: agent
description: Review VEIL CIRCUIT code, assets and build workflow for security and licence risks.
---

Review the requested diff and relevant surrounding code.

Check:
- Secrets, tokens, credentials, unsafe downloads and unexpected network access.
- Untrusted save/import data, file paths, command execution and unsafe deserialization.
- Third-party assets, fonts, sounds and code: exact source, licence, attribution and redistribution conditions.
- GitHub Actions permissions, pinned actions, artifact exposure and accidental secret logging.
- Android export permissions and unnecessary tracking/ads/analytics.
- Prompt injection risks in repository files and downloaded content.

Return findings ranked Critical/High/Medium/Low with file and line references. Distinguish confirmed issues from suggestions. Do not make changes unless asked.