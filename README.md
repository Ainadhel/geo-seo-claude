<p align="center">
  <img src="assets/banner.svg" alt="GEO-SEO Claude Code Skill" width="900"/>
</p>

<p align="center">
  <strong>GEO-first, SEO-supported.</strong> Optimize websites for AI-powered search engines<br/>
  (ChatGPT, Claude, Perplexity, Gemini, Google AI Overviews) while maintaining traditional SEO foundations.
</p>

<p align="center">
  AI search is eating traditional search. This tool optimizes for where traffic is going, not where it was.
</p>

---

## Star History

<a href="https://www.star-history.com/#zubair-trabzada/geo-seo-claude&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/star-history-dark.svg">
    <img alt="Star History Chart" src="assets/star-history.svg">
  </picture>
</a>

---

## Why GEO Matters (2026)

| Metric | Value |
|--------|-------|
| GEO services market | $850M+ (projected $7.3B by 2031) |
| AI-referred traffic growth | +527% year-over-year |
| AI traffic conversion rate vs organic | 4.4x higher |
| Gartner: search traffic drop by 2028 | -50% |
| Brand mentions vs backlinks for AI | 3x stronger correlation |
| Marketers investing in GEO | Only 23% |

---

## Quick Start

> **Ported fork.** This repository runs under OpenCode from a local clone. The skills are read from
> `.agents/skills/`, there is no install into `~/.claude/`, and nothing is written outside the
> working folder. See [`docs/PORTAGE-OPENCODE.md`](docs/PORTAGE-OPENCODE.md).

### Windows (PowerShell)

```powershell
git clone https://github.com/Ainadhel/geo-seo-claude.git
cd geo-seo-claude
.\install-win.ps1
```

### macOS / Linux

```bash
git clone https://github.com/Ainadhel/geo-seo-claude.git
cd geo-seo-claude
./install.sh
```

### Windows under Git Bash

Only if you already have Git Bash. On Windows, `install-win.ps1` is the supported path.

```bash
./install-win.sh
```

There is no `curl | bash` installer. The bootstrap runs from your clone, in place.

### Requirements

- Python 3.8+ (the target machine runs 3.14)
- OpenCode
- Git
- Optional: [`uv`](https://docs.astral.sh/uv/), used for a faster venv and dependency install
- Optional: Playwright (for screenshots)

### Isolated install

Python dependencies go into a virtual environment **inside the working folder**, at `.venv/`. Your
system Python is not touched, and the skills reference that interpreter directly, so the tool works
regardless of what `python` resolves to on your `PATH`.

| Platform | Venv interpreter |
|---|---|
| Windows | `.venv\Scripts\python.exe` |
| macOS / Linux | `.venv/bin/python3` |

Every command in the skills and agent files uses that path, for example:

```powershell
.\.venv\Scripts\python.exe scripts\fetch_page.py https://example.com
```

Run the test suite the same way:

```powershell
.\.venv\Scripts\python.exe -m pytest tests\ -q
```

The tests are pytest-style classes, so `unittest discover` does not collect them. The bootstrap
installs `pytest` into the venv for you.

---

## Commands

Use the skills in OpenCode:

| Command | What It Does |
|---------|-------------|
| `/geo audit <url>` | Full GEO + SEO audit with parallel subagents |
| `/geo quick <url>` | 60-second GEO visibility snapshot |
| `/geo citability <url>` | Score content for AI citation readiness |
| `/geo crawlers <url>` | Check AI crawler access (robots.txt) |
| `/geo llmstxt <url>` | Analyze or generate llms.txt |
| `/geo brands <url>` | Scan brand mentions across AI-cited platforms |
| `/geo platforms <url>` | Platform-specific optimization |
| `/geo schema <url>` | Structured data analysis & generation |
| `/geo technical <url>` | Technical SEO audit |
| `/geo content <url>` | Content quality & E-E-A-T assessment |
| `/geo report <url>` | Generate client-ready GEO report |
| `/geo report-pdf` | Generate professional PDF report with charts & visualizations |

---

## Architecture

```
geo-seo-claude/
├── .agents/skills/                # 15 specialized sub-skills + the orchestrator
│   ├── geo/SKILL.md               # Main skill orchestrator: commands & routing
│   ├── geo-audit/                 # Full audit orchestration & scoring
│   ├── geo-citability/            # AI citation readiness scoring
│   ├── geo-crawlers/              # AI crawler access analysis
│   ├── geo-llmstxt/               # llms.txt standard analysis & generation
│   ├── geo-brand-mentions/        # Brand presence on AI-cited platforms
│   ├── geo-platform-optimizer/    # Platform-specific AI search optimization
│   ├── geo-schema/                # Structured data for AI discoverability
│   ├── geo-technical/             # Technical SEO foundations
│   ├── geo-content/               # Content quality & E-E-A-T
│   ├── geo-report/                # Client-ready markdown report generation
│   ├── geo-report-pdf/            # Professional PDF report with charts
│   ├── geo-prospect/              # CRM-lite prospect pipeline management
│   ├── geo-proposal/              # Auto-generate client proposals
│   ├── geo-compare/               # Monthly delta tracking & progress reports
│   └── geo-update/                # Pull upstream changes into this layout
├── agents/                        # 5 parallel subagents
│   ├── geo-ai-visibility.md       # GEO audit, citability, crawlers, brands
│   ├── geo-platform-analysis.md   # Platform-specific optimization
│   ├── geo-technical.md           # Technical SEO analysis
│   ├── geo-content.md             # Content & E-E-A-T analysis
│   └── geo-schema.md              # Schema markup analysis
├── scripts/                       # Python utilities
│   ├── fetch_page.py              # Page fetching & parsing
│   ├── citability_scorer.py       # AI citability scoring engine
│   ├── brand_scanner.py           # Brand mention detection
│   ├── llmstxt_generator.py       # llms.txt validation & generation
│   ├── crm_dashboard.py           # Rich CLI over the prospect CRM
│   └── webapp/                    # Flask + HTMX CRM web UI
├── schema/                        # JSON-LD templates
│   ├── organization.json          # Organization schema (with sameAs)
│   ├── local-business.json        # LocalBusiness schema
│   ├── article-author.json        # Article + Person schema (E-E-A-T)
│   ├── software-saas.json         # SoftwareApplication schema
│   ├── product-ecommerce.json     # Product schema with offers
│   └── website-searchaction.json  # WebSite + SearchAction schema
├── templates/                     # geo-report-style.css + geo-report-template.html
├── install-win.ps1                # Windows / PowerShell bootstrap (primary)
├── install.sh                     # POSIX bootstrap
├── uninstall.sh                   # Removes .venv and, on request, .data
├── requirements.txt               # Python dependencies
├── .venv/                         # Project-local venv, not versioned
├── .data/geo-prospects/           # Prospect data, not versioned
├── reports/                       # Client deliverables, not versioned
└── README.md                      # This file
```

Upstream keeps the sub-skills in `skills/` and the orchestrator in `geo/`, then copies both into
`~/.claude/`. That layout is gone here on purpose: OpenCode reads `.agents/skills/` in place, so
copying is both unnecessary and a source of drift.

---

## Data Storage

The CRM and reporting skills (`/geo prospect`, `/geo proposal`, `/geo compare`) store runtime data
inside the working folder:

```
.data/geo-prospects/
├── prospects.json              # Client/prospect pipeline data
├── proposals/                  # Generated proposal documents
│   └── <domain>-proposal-<date>.md
└── reports/                    # Monthly delta reports
    └── <domain>-monthly-<YYYY-MM>.md
```

This directory holds client data and is git-ignored. It is never removed automatically, delete it
by hand once you no longer need your prospect data. The Python helpers read the same location and
honour a `GEO_PROSPECTS_DIR` environment variable if you need to point them elsewhere.

---

## How It Works

### Full Audit Flow

When you run `/geo audit https://example.com`:

1. **Discovery** — Fetches homepage, detects business type, crawls sitemap
2. **Parallel Analysis** — Launches 5 subagents simultaneously:
   - AI Visibility (citability, crawlers, llms.txt, brand mentions)
   - Platform Analysis (ChatGPT, Perplexity, Google AIO readiness)
   - Technical SEO (Core Web Vitals, SSR, security, mobile)
   - Content Quality (E-E-A-T, readability, freshness)
   - Schema Markup (detection, validation, generation)
3. **Synthesis** — Aggregates scores, generates composite GEO Score (0-100)
4. **Report** — Outputs prioritized action plan with quick wins

### Scoring Methodology

| Category | Weight |
|----------|--------|
| AI Citability & Visibility | 25% |
| Brand Authority Signals | 20% |
| Content Quality & E-E-A-T | 20% |
| Technical Foundations | 15% |
| Structured Data | 10% |
| Platform Optimization | 10% |

---

## Key Features

### Citability Scoring
Analyzes content blocks for AI citation readiness. Optimal AI-cited passages are 134-167 words, self-contained, fact-rich, and directly answer questions.

### AI Crawler Analysis
Checks robots.txt for 14+ AI crawlers (GPTBot, ClaudeBot, PerplexityBot, etc.) and provides specific allow/block recommendations.

### Brand Mention Scanning
Brand mentions correlate 3x more strongly with AI visibility than backlinks. Scans YouTube, Reddit, Wikipedia, LinkedIn, and 7+ other platforms.

### Platform-Specific Optimization
Only 11% of domains are cited by both ChatGPT and Google AI Overviews for the same query. Provides tailored recommendations per platform.

### llms.txt Generation
Generates the emerging llms.txt standard file that helps AI crawlers understand your site structure.

### Client-Ready Reports
Generates professional GEO reports in markdown or PDF format. PDF reports include score gauges, bar charts, platform readiness visualizations, color-coded tables, and prioritized action plans — ready to deliver to clients.

---

## Use Cases

- **GEO Agencies** — Run client audits and generate deliverables
- **Marketing Teams** — Monitor and improve AI search visibility
- **Content Creators** — Optimize content for AI citations
- **Local Businesses** — Get found by AI assistants
- **SaaS Companies** — Improve entity recognition across AI platforms
- **E-commerce** — Optimize product pages for AI shopping recommendations

---
## Uninstall

There is nothing installed outside the working folder, so uninstalling is a local operation.

```bash
./uninstall.sh
```

The script removes `.venv/` and asks before touching `.data/geo-prospects/`. It deliberately does
**not** delete the skills, agents or scripts: those are source files in this repository, and
removing them would destroy the working folder.

On Windows the equivalent is:

```powershell
Remove-Item -Recurse -Force .venv
Remove-Item -Recurse -Force .data   # only if you no longer need the prospect data
```

---

## Want to Turn This Into a Business?

The tool is free. Learning how to monetize it is where the community comes in.

**[Join the AI Workshop Community →](https://skool.com/aiworkshop)**

Inside you'll get:
- **Video walkthroughs** — Step-by-step setup, running audits, reading results
- **Client acquisition playbook** — How to find prospects, pitch GEO services, and close deals
- **Live office hours** — Bring your audit results, get direct help
- **GEO agency pricing & templates** — Proposal docs, cold outreach scripts, onboarding workflows

GEO agencies charge $2K–$12K/month. This tool does the audit. The community teaches you how to sell it.

---





## License

MIT License

---

## Contributing

Contributions welcome!

---

Built for the AI search era.
