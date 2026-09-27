# Frequently Asked Questions

---

## General

### What is GEO and how is it different from SEO?

SEO (Search Engine Optimization) targets ranking in traditional search engines like Google's blue-link results. GEO (Generative Engine Optimization) targets visibility inside AI-generated answers from systems like ChatGPT, Perplexity, Claude, Gemini, and Google AI Overviews. The two disciplines overlap — technical foundations and content quality matter for both — but GEO adds concerns specific to AI retrieval: citability scoring, brand mention density, llms.txt, and entity recognition across AI-cited platforms.

### Is this a paid tool or service?

The tool itself is free and MIT-licensed. It runs entirely within your own Claude Code session using your existing Anthropic subscription. There is no separate API key, usage meter, or subscription for the skill bundle itself.

### Who is this for?

GEO agencies running client audits, in-house marketing teams monitoring AI search visibility, content creators optimizing individual pages for AI citations, and developers building or maintaining web properties who want actionable GEO and SEO feedback without a SaaS subscription.

### Does this replace my existing SEO stack?

No. It complements existing tools. The `/geo technical` command covers technical SEO foundations, but the tool does not replace crawlers like Screaming Frog, keyword research platforms, or rank trackers. Its primary value is the GEO layer — AI citability, crawler access, brand signals, and platform readiness — that most traditional SEO tools do not cover.

---

## Installation & Setup

### Why do I need Claude Code CLI?

The skill bundle is implemented as Claude Code slash commands. All commands (`/geo audit`, `/geo quick`, etc.) are routed through Claude Code's skill and agent system. The CLI is the runtime; without it, there is nothing to execute the skill files. Install it with `npm install -g @anthropic-ai/claude-code`.

### Can I run this on Windows without WSL?

Yes, and PowerShell is the supported shell in this fork. Run `.\install-win.ps1` from the repository root; it creates the project-local venv and the local data directory. No WSL and no Git Bash are needed. (`install-win.sh` still exists for anyone who does have Git Bash, but it is not the path documented here.)

### What does the installer actually do?

It checks for Git and Python 3.8+, then prepares the working folder in place. Specifically: it creates a virtual environment at `.venv/` inside the working folder, installs `requirements.txt` and `pytest` into it, and creates the prospect data directory `.data/geo-prospects/`. The skills are not copied anywhere, they already live where OpenCode reads them (`.agents/skills/`), and the 5 agent definitions stay in `agents/`. Nothing is written to `~/.claude/` or anywhere else in your user profile. If you run it interactively, it also offers to install the Playwright Chromium browser for screenshot support.

### Do I need Playwright?

Playwright is optional. The installer prompts you to install it (`.venv/Scripts/python.exe -m playwright install chromium`). Without it, screenshot-based features are unavailable but all other audit and analysis commands function normally. You can install it later at any time.

---

## Usage

### What is the difference between `/geo quick` and `/geo audit`?

`/geo quick` produces a 60-second inline visibility snapshot and writes no output file. It is useful for a fast read on a URL before committing to a full run. `/geo audit` is the full workflow: it fetches the site, detects the business type, launches 5 parallel subagents, aggregates scores across all categories, and writes a `GEO-AUDIT-REPORT.md` with a prioritized action plan. See [commands-reference.md](commands-reference.md) for the complete command list.

### Where does the composite GEO Score come from?

The score (0-100) is a weighted aggregate across six categories: AI Citability & Visibility (25%), Brand Authority Signals (20%), Content Quality & E-E-A-T (20%), Technical Foundations (15%), Structured Data (10%), and Platform Optimization (10%). See [scoring-methodology.md](scoring-methodology.md) for how individual signals within each category are measured.

### How do the parallel subagents work?

During a full audit, five subagents run simultaneously after the initial discovery phase: `geo-ai-visibility`, `geo-platform-analysis`, `geo-technical`, `geo-content`, and `geo-schema`. Each maps to an agent definition file in `agents/` and is responsible for a distinct slice of the analysis. OpenCode handles the parallel dispatch; the orchestrator then collects all five reports and synthesizes the composite score. See [architecture.md](architecture.md) for the full flow.

### Where is prospect, proposal, and report data stored?

Data from `/geo prospect`, `/geo proposal`, and `/geo compare` is written to `.data/geo-prospects/`, inside the working folder. The structure is:

```
.data/geo-prospects/
├── prospects.json
├── proposals/<domain>-proposal-<date>.md
└── reports/<domain>-monthly-<YYYY-MM>.md
```

This directory holds client pipeline data and is git-ignored. It is never deleted automatically; remove it by hand with `Remove-Item -Recurse -Force .data\geo-prospects` when you are sure you no longer need it. The Python helpers (`crm_dashboard.py`, the Flask webapp) read the same location, and honour a `GEO_PROSPECTS_DIR` environment variable if you need to point them elsewhere.

---

## Contributing

### How do I add a new sub-skill?

Create a new directory under `.agents/skills/` following the naming pattern `geo-<skill-name>/`. Add a `SKILL.md` inside it that defines the skill's name, description, and logic. If the skill should participate in the full audit, register it in the appropriate agent file under `agents/`. Follow the structure of an existing sub-skill such as `.agents/skills/geo-citability/` as a reference. See [skills-and-agents.md](skills-and-agents.md) for a map of how skills and agents relate.

### How do I test my changes before opening a PR?

Run `.\install-win.ps1` (or `./install.sh` on POSIX) from your local clone to provision the venv and the local data directory, then exercise the affected commands against a real URL. Verify that all status checks pass before submitting your pull request, as noted in `CONTRIBUTING.md`.

### Where do I report bugs or request features?

Open an issue on GitHub. For bugs, include a clear description, the URL you were auditing if relevant, and any error output. For feature requests, explain the use case and why it matters. Search existing issues first to avoid duplicates. Both are tracked under the repository's Issues tab.

---

## Limitations

### Can this tool guarantee AI citations or rankings?

No. The tool audits signals that correlate with AI visibility and provides recommendations to improve them, but no tool can guarantee that any AI system will cite or surface a specific domain. AI retrieval is probabilistic and varies by query, platform, and model version.

### Does it submit anything to third-party services?

The skill uses `WebFetch` and `Bash` (via `curl`) to fetch the URLs you provide, and the brand mention scanner checks publicly accessible platforms (YouTube, Reddit, Wikipedia, LinkedIn, and others) for brand signals. No audit data is sent to any Anthropic-operated or third-party analytics endpoint. Your data stays within your Claude Code session and your local filesystem.
