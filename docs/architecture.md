# Architecture & Design

The repository is structured to seamlessly provide GEO+SEO support by using the agent's tool
capabilities alongside subagents and python utility scripts.

> **Ported fork.** The skills live under `.agents/skills/`, which is where OpenCode reads them.
> Upstream keeps them in `skills/` and `geo/` and installs them into `~/.claude/`. The layout below
> is the ported one. See [PORTAGE-OPENCODE.md](PORTAGE-OPENCODE.md).

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
│   └── crm_dashboard.py           # Rich CLI over the prospect CRM
├── schema/                        # JSON-LD templates
│   ├── organization.json          # Organization schema (with sameAs)
│   ├── local-business.json        # LocalBusiness schema
│   ├── article-author.json        # Article + Person schema (E-E-A-T)
│   ├── software-saas.json         # SoftwareApplication schema
│   ├── product-ecommerce.json     # Product schema with offers
│   └── website-searchaction.json  # WebSite + SearchAction schema
├── install-win.ps1                # Windows / PowerShell bootstrap (primary)
├── install.sh                     # POSIX bootstrap
├── requirements.txt               # Python dependencies
├── .venv/                         # Project-local venv, not versioned
└── README.md                      # Main project view
```

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

### Data Storage

The CRM and reporting skills (`/geo prospect`, `/geo proposal`, `/geo compare`) store runtime data
in a project-local directory, inside the working folder:

```
.data/geo-prospects/
├── prospects.json              # Client/prospect pipeline data
├── proposals/                  # Generated proposal documents
│   └── <domain>-proposal-<date>.md
└── reports/                    # Monthly delta reports
    └── <domain>-monthly-<YYYY-MM>.md
```

This directory holds client data and is git-ignored. It is never deleted automatically: remove it
by hand once you no longer need your prospect data.
