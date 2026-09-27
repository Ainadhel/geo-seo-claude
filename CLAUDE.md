# CLAUDE.md

This file provides guidance to any assistant (agent or human) working with code in this repository.
The name is historical: the file is kept because the upstream toolchain expects it, but the tool
that actually loads the skills here is **OpenCode**. See
[the portage section below](#portage-opencode-source-de-verite-de-loutillage-local).

## What this is

A **GEO-SEO analysis toolkit** distributed as a suite of skills + subagents + Python
scripts. "GEO" = Generative Engine Optimization — optimizing websites for AI search engines
(ChatGPT, Claude, Perplexity, Gemini, Google AI Overviews) rather than only traditional search.
Philosophy: **GEO-first, SEO-supported.**

This repository is the **source and the installation**. The skills are read in place from
`.agents/skills/`; there is no install step and nothing is written to the user profile. Audits are
run from this working folder and deliverables land in `reports/`, which is git-ignored so client
artefacts are never committed.

Deep documentation already lives in [`docs/`](docs/) — read it before large changes and keep it in
sync (per `CONTRIBUTING.md`):

| Topic | File |
|-------|------|
| What changed in the port, and how to reconcile upstream | `docs/PORTAGE-OPENCODE.md` |
| Component architecture & data flow | `docs/architecture.md` |
| Composite GEO Score weights & formulas | `docs/scoring-methodology.md` |
| Skills / agents / scripts / schemas map | `docs/skills-and-agents.md` |
| Every `/geo` subcommand | `docs/commands-reference.md` |

## Repository layout

| Path | Contents |
|------|----------|
| `.agents/skills/geo/SKILL.md` | Orchestrator — routes `/geo` subcommands, detects business type, fans out and synthesizes the audit |
| `.agents/skills/geo-*/` | 15 sub-skills (one `SKILL.md` each) — the reusable units and single-purpose subcommands |
| `agents/geo-*.md` | 5 parallel subagents launched during a full audit |
| `scripts/*.py` | Python analysis scripts (`fetch_page`, `citability_scorer`, `brand_scanner`, `llmstxt_generator`, `crm_dashboard`) |
| `scripts/webapp/` | Flask + HTMX CRM web UI (`app.py`) |
| `schema/*.json` | JSON-LD schema templates by business type |
| `templates/` | `geo-report-style.css` + `geo-report-template.html` for the PDF report |
| `docs/` | Long-form documentation (keep in sync with code) |
| `examples/` | Sample audit outputs, proposals, demo CRM data |
| `reports/` | Client deliverables, git-ignored |
| `tests/` | Test suite (see [Testing](#testing)) |
| `white-label/` | Agency rebranding config (`brand_config.py`, `brand.example.json`) |
| `install-win.ps1` / `install.sh` / `install-win.sh` / `uninstall.sh` | Bootstraps and cleanup |
| `.venv/` | Project-local virtual environment, git-ignored |
| `.data/geo-prospects/` | Prospect / proposal / report state, git-ignored |

## Architecture (in brief)

Three layers — see `docs/architecture.md` for the full picture:

1. **Orchestrator** (`.agents/skills/geo/SKILL.md`) routes subcommands, detects business type
   (SaaS / Local / E-commerce / Publisher / Agency / Other, which tailors recommendations), and
   for a full `/geo audit` fans out to subagents then synthesizes a composite **GEO Score (0-100)**.
2. **5 parallel subagents** (`agents/geo-*.md`) run simultaneously during an audit; each owns a
   slice (AI visibility, platform analysis, technical, content, schema) and writes a report section.
3. **15 sub-skills** (`.agents/skills/geo-*/`) are the reusable units the subagents invoke and the targets
   of single-purpose subcommands (`citability`, `crawlers`, `llmstxt`, …), plus the agency layer
   (`geo-prospect` CRM, `geo-proposal`, `geo-compare`, `geo-report-pdf`, `geo-update`).

**Two kinds of state:** audit deliverables are written to `reports/`; agency/CRM data persists under
`.data/geo-prospects/` (`prospects.json`, `audits/`, `proposals/`, `reports/`), which the Python
scripts and the Flask webapp read/write directly. Both honour a `GEO_PROSPECTS_DIR` environment
variable for the CRM data.

## Bootstrap / cleanup

`install-win.ps1` (Windows, the supported path), `install.sh` (POSIX) and `install-win.sh` (Git Bash)
provision the working folder **in place**. They create a Python venv at `.venv/` (using `uv` if
available, else stdlib `venv` + `pip`), install `requirements.txt` **and `pytest`**, and create
`.data/geo-prospects/`. They do not copy any file anywhere, and they do not rewrite script shebangs:
the skills reference the venv interpreter explicitly.

`uninstall.sh` removes `.venv/` and asks before touching `.data/`. It does not delete the skills,
agents or scripts, because those are source files in this repository.

## Running the scripts (from the repo)

Scripts print **JSON to stdout** so skills/agents can parse them — preserve that contract.

```powershell
# Windows / PowerShell
.\install-win.ps1
.\.venv\Scripts\python.exe -m playwright install chromium   # fetch_page.py uses Playwright for SSR/JS checks

.\.venv\Scripts\python.exe scripts\fetch_page.py <url>
.\.venv\Scripts\python.exe scripts\citability_scorer.py <url>
.\.venv\Scripts\python.exe scripts\brand_scanner.py "<brand name>"
.\.venv\Scripts\python.exe scripts\llmstxt_generator.py <url>
.\.venv\Scripts\python.exe scripts\crm_dashboard.py        # rich CLI over .data/geo-prospects
.\.venv\Scripts\python.exe scripts\webapp\app.py           # CRM web UI at http://localhost:5050
```

On macOS / Linux the venv interpreter is `.venv/bin/python3` and the separators are `/`. Use
forward slashes in commands either way: PowerShell accepts them on Windows.

## Testing

Tests are pytest-style classes (`tests/test_fetch_page_ssr.py`, using `unittest.mock`, no network).
`unittest discover` does not collect them, so run them with pytest (installed by the bootstrap):

```powershell
.\.venv\Scripts\python.exe -m pytest tests\ -q                                  # all tests
.\.venv\Scripts\python.exe -m pytest tests\test_fetch_page_ssr.py -k ssr_content # a single test
```

## Portage OpenCode, source de verite de l'outillage local

Since the port, this working folder is the single source of truth for the tooling. Concretely:

- **The OpenCode layout is the reference.** Skills live in `.agents/skills/`, agents in `agents/`,
  scripts in `scripts/`, the venv in `.venv/`, prospect data in `.data/geo-prospects/`. Do not
  reintroduce `skills/`, `geo/` or any `~/.claude` path, and do not reintroduce `allowed-tools` in
  the `SKILL.md` frontmatter.
- **`AGENTS.md` does not exist here and must not be created.** The equivalent file for an assistant
  working in this repo is this `CLAUDE.md`. Its name is a leftover from upstream and is kept on
  purpose; renaming it would break the upstream workflow it documents.
- **Every command in a skill or agent must work in PowerShell.** The upstream corpus assumes `curl`,
  `&&`, `sed -i` and `python3`. Use the local venv interpreter, and no `sed -i`.
- **Reconciling upstream is a documented operation, not an improvisation.** Read
  [`docs/PORTAGE-OPENCODE.md`](docs/PORTAGE-OPENCODE.md) first. A verbatim upstream copy will
  resurrect `skills/` and `geo/`, and will bring back the `allowed-tools` frontmatter field.

## Conventions

- **Docs stay in sync:** when changing code or behavior, update the matching file in `docs/`
  (a `CONTRIBUTING.md` requirement). Match existing structure and tone.
- **Commit messages:** imperative present tense, first line ≤ 72 chars, reference issues after.
- **Scripts → JSON stdout.** Keep the machine-readable output contract.
- **Encoding:** UTF-8 without BOM. Never write a file from PowerShell with `Set-Content`,
  `Out-File` or `>`: it corrupts accented characters. Use a file write tool or a Python script, then
  re-read an accented character to prove it survived.
- **No em dashes** in files you add or edit: the fork is public. Use a comma or rephrase.
- Some code and docstrings are in Italian (e.g. `scripts/crm_dashboard.py`) — match the language of
  the file you edit.
- Crawl quality gates (from `.agents/skills/geo/SKILL.md`): max 50 pages/audit, 30s fetch timeout, 1s delay between
  requests, max 5 concurrent, always respect robots.txt.
- Market-context stats and dates in `.agents/skills/geo/SKILL.md` / `README.md` are editorial point-in-time content,
  not code.
- White-labeling for agencies is driven by `white-label/` — don't hardcode brand strings that belong
  in `brand.example.json`.
