# Getting Started

> **Ported fork.** This file documents the OpenCode port, where the toolkit runs from a
> local clone instead of an install into `~/.claude/`. There is no global install step and
> nothing is written outside the working folder. See [PORTAGE-OPENCODE.md](PORTAGE-OPENCODE.md)
> for the full picture.

## Prerequisites

| Requirement | Why it's needed |
|---|---|
| Python 3.8+ | Runs the utility scripts (page fetching, citability scoring, PDF generation, etc.) |
| OpenCode | The skills are loaded from `.agents/skills/` and invoked as skills |
| Git | Clone / update the repository |
| Playwright (optional) | Enables screenshot capture; install separately after the main install |

---

## Installation

### Windows (PowerShell) — the supported path

```powershell
git clone https://github.com/Ainadhel/geo-seo-claude.git
cd geo-seo-claude
.\install-win.ps1
```

The installer creates a virtual environment **inside the working folder** at `.venv\`, installs
`requirements.txt` plus `pytest` into it, and creates the local data directory `.data\geo-prospects\`.
Nothing is written to your user profile.

### macOS / Linux

```bash
git clone https://github.com/Ainadhel/geo-seo-claude.git
cd geo-seo-claude
./install.sh
```

Same result, POSIX layout: the venv interpreter is `.venv/bin/python3` instead of
`.venv/Scripts/python.exe`.

### What the installer does

- Leaves the skills where they already are, in `.agents/skills/geo/` and `.agents/skills/geo-*/`
- Leaves the 5 subagent definitions in `agents/`
- Creates the project-local venv at `.venv/` (with `uv` if available, else stdlib `venv` + `pip`)
- Installs `requirements.txt` and `pytest` into that venv
- Creates the prospect data directory `.data/geo-prospects/`
- Optionally installs the Playwright Chromium browser for screenshots

---

## Verify the Install

From the repository root, confirm the venv interpreter answers and the tests pass:

```powershell
.\.venv\Scripts\python.exe -m pytest tests/ -q
```

Then, in OpenCode, run the skill:

```
/geo quick https://example.com
```

If the skill is wired up correctly you get a 60-second GEO visibility snapshot. OpenCode reads
skills at startup, so restart the session after any file added under `.agents/skills/`.

To confirm the files landed in the right place:

```powershell
Get-ChildItem .agents\skills | Select-Object -ExpandProperty Name
Get-ChildItem agents | Select-Object -ExpandProperty Name
```

---

## Your First Audit

### Quick path — 60-second snapshot

```
/geo quick https://yoursite.com
```

Returns a high-level GEO visibility score and the top issues. Good for a first look or a fast client check.

### Full path — complete audit

```
/geo audit https://yoursite.com
```

Launches 5 parallel subagents covering AI visibility, platform optimization, technical SEO, content quality, and structured data. Produces a prioritized action plan with a composite GEO score (0–100).

The full audit takes several minutes depending on the site. See [scoring-methodology.md](scoring-methodology.md) for how the score is calculated and [commands-reference.md](commands-reference.md) for all available commands.

---

## Troubleshooting

**Python not found during install**
- Symptom: installer exits with `Python 3.8+ is required but not found`
- Cause: Python is not installed or not on `PATH`
- Fix: install from [python.org](https://www.python.org/downloads/); on Windows check "Add Python to PATH" during setup; then reopen your terminal

**Claude Code CLI not found**
- Symptom: installer warns `Claude Code CLI not found in PATH`
- Cause: `claude` is not installed or not on `PATH`
- Fix: `npm install -g @anthropic-ai/claude-code`; confirm with `claude --version`

**Skills not showing up in Claude Code**
- Symptom: `/geo quick` produces "unknown command" or no response
- Cause: Claude Code reads skills at startup; it won't see files added after launch
- Fix: fully quit and reopen Claude Code

**Permission denied on `./install.sh`**
- Symptom: `bash: ./install.sh: Permission denied`
- Cause: execute bit not set
- Fix: `chmod +x install.sh && ./install.sh`

**Wrong shell on Windows**
- Symptom: `curl` not recognized, or script syntax errors
- Cause: running `install-win.sh` in PowerShell or Command Prompt
- Fix: use Git Bash only — right-click the folder, "Open Git Bash here"

**Playwright not available / screenshots missing**
- Symptom: screenshot-related steps silently skip or error
- Cause: Playwright was skipped during install (non-interactive or answered no)
- Fix: install it manually:
  ```powershell
  .\.venv\Scripts\python.exe -m playwright install chromium
  ```

**Python dependencies failed during install**
- Symptom: installer prints `Some Python dependencies failed to install`
- Cause: pip error (network, permissions, or virtualenv conflict)
- Fix: run manually from the repository root:
  ```powershell
  .\.venv\Scripts\python.exe -m pip install -r requirements.txt
  ```

---

## Uninstall

There is nothing installed outside the working folder, so uninstalling is a local operation.

### Virtual environment and runtime data

```powershell
Remove-Item -Recurse -Force .venv
Remove-Item -Recurse -Force .data
```

The prospect data directory `.data/geo-prospects/` holds client pipeline data, so it is never
deleted automatically. Remove it by hand once you are sure you no longer need it:

```powershell
Remove-Item -Recurse -Force .data\geo-prospects
```

If you want to go back to the upstream layout (sub-skills in `skills/`, orchestrator in `geo/`,
install into `~/.claude/`), read the reconciliation procedure in
[PORTAGE-OPENCODE.md](PORTAGE-OPENCODE.md) first.

---

See also: [architecture.md](architecture.md) | [commands-reference.md](commands-reference.md) | [scoring-methodology.md](scoring-methodology.md) | [skills-and-agents.md](skills-and-agents.md)
