# portfolio-base-template

> A reusable GitHub **template repository** for professional software engineering
> projects. New project repositories are created from this template, then
> initialized with a bootstrap script and a set of Claude Code skills.

> **Note:** This file documents how to *use the template*. After you run
> `scripts/bootstrap.sh`, this file is preserved as `docs/TEMPLATE_USAGE.md`,
> and the project-facing README (`TEMPLATE_README.md`) is promoted to `README.md`.

---

## What This Template Includes

| Category | What's Included |
|----------|----------------|
| **Claude Code** | `CLAUDE.md` operating guide, 6 skills, 6 documented hook conventions |
| **CI/CD** | GitHub Actions pipeline (lint + test + structure validation + security scan) |
| **Documentation** | Architecture doc, ADR template, implementation-plan template, QA plan + audit record, operations runbook |
| **Source structure** | `src/`, `tests/unit/`, `tests/integration/` (empty, ready to populate) |
| **Automation** | `bootstrap.sh` (fills identity tokens, promotes README, selects license), `validate-structure.sh` (state-aware validator), `template-tokens.tsv` (token source of truth) |

---

## Using This Template

### 1. Create a repository from the template (GitHub)

1. Click **Use this template → Create a new repository** at the top of this page.
2. Name the repository in kebab-case and choose visibility.
3. Clone your new repository locally.

### 2. Bootstrap it

```bash
cd your-new-repo
bash scripts/bootstrap.sh
```

> **Windows:** the `.sh` scripts require **Bash 4+** — Git Bash providing Bash 4+,
> WSL providing Bash 4+, or another environment providing Bash 4+ (they use
> associative arrays). They will not run in `cmd.exe` or PowerShell directly.

`bootstrap.sh` will:

1. Prompt for project identity values (name, description, language, commands, …).
2. Offer a **license** choice — **MIT**, **Apache-2.0**, or **None** (default: None).
   For MIT/Apache-2.0 a complete `LICENSE` file is generated locally.
3. Fill every **identity** placeholder token throughout the repository.
   Deferred tokens (implementation plan, QA records, releases) are intentionally
   left for later; meta tokens are never replaced.
4. Preserve these template-usage instructions as `docs/TEMPLATE_USAGE.md`.
5. Promote `TEMPLATE_README.md` to the root `README.md`, then remove the scaffold.
6. Record the outcome in `.bootstrap-complete` and run the strict structure
   validator as a final gate.

### 3. Validate at any time

```bash
bash scripts/validate-structure.sh          # ordinary
bash scripts/validate-structure.sh --strict # fail on warnings too
```

---

## Placeholder Tokens

The template uses double-brace placeholder tokens (bare names wrapped in double
braces). **The single source of truth for token names and categories is
[`scripts/template-tokens.tsv`](scripts/template-tokens.tsv)** — do not maintain a
second list elsewhere. Every token is classified as:

- **identity** — filled once during bootstrap (project name, language, commands, …).
- **deferred** — filled later when the associated work product is authored
  (implementation-plan tasks, QA audit dates, release versions).
- **meta** — literal instructional syntax that is never replaced.

Both `bootstrap.sh` and `validate-structure.sh` read this file. The strict
validator fails on unresolved **identity** tokens but allows **deferred** and
**meta** tokens to remain.

---

## Directory Structure

```
portfolio-base-template/
├── CLAUDE.md                          # Claude Code operating guide
├── README.md                          # This file (template usage) → docs/TEMPLATE_USAGE.md after bootstrap
├── TEMPLATE_README.md                 # Project README scaffold → promoted to README.md by bootstrap
├── .env.example                       # Environment variable reference (stack-neutral)
├── .gitignore                         # Python + Node + IDE + OS (+ .claude/settings.local.json)
│
├── .claude/
│   ├── skills/
│   │   ├── entry-protocol.md          # Mandatory read-only startup scan
│   │   ├── code-review.md             # Severity-labeled review
│   │   ├── refactor-playbook.md       # Proposal-first refactoring
│   │   ├── documentation.md           # Docstrings + docs generation
│   │   ├── qa-checklist.md            # QA audit (QA agent ≠ coding agent)
│   │   └── release-procedure.md       # Pre-release checklist
│   └── hooks/
│       └── hooks.md                   # 6 voluntary behavioral conventions (not harness-enforced)
│
├── docs/
│   ├── architecture.md
│   ├── implementation-plan.md
│   ├── adr/
│   │   └── ADR-001-template.md
│   ├── qa/
│   │   ├── qa-plan.md
│   │   ├── QA.md                      # Permanent QA audit record
│   │   └── optional/
│   │       └── web-ui-coverage-matrix.md   # Optional — web-UI projects only
│   └── runbooks/
│       └── operations.md
│
├── scripts/
│   ├── bootstrap.sh                   # First-time setup + identity fill + README promotion + license
│   ├── validate-structure.sh          # State-aware structure + token validator
│   └── template-tokens.tsv            # Token taxonomy (single source of truth)
│
├── src/                               # Application source (populate after bootstrap)
├── tests/
│   ├── unit/
│   └── integration/
│
└── .github/
    ├── workflows/
    │   └── ci.yml                     # Lint + test + validate-structure + security scan
    ├── ISSUE_TEMPLATE/
    │   ├── bug-report.md
    │   └── feature-request.md
    ├── pull_request_template.md
    └── dependabot.yml
```

---

## Claude Code Workflow

Open the repository in Claude Code and say:

> **"Run the entry protocol"**

Claude scans the repository read-only, builds a summary, and proposes prioritized
work — without touching code until you approve.

### Available Skills

| Say this… | Skill | Claude will… |
|-----------|-------|--------------|
| `"Run the entry protocol"` | `entry-protocol.md` | Scan, summarize, and propose work |
| `"Review this file"` | `code-review.md` | Structured review with severity ratings |
| `"Refactor this"` | `refactor-playbook.md` | Safe, proposal-first refactoring |
| `"Document this"` | `documentation.md` | Docstrings, README, architecture docs |
| `"Run QA"` | `qa-checklist.md` | Test-coverage and portfolio-readiness audit |
| `"Prepare a release"` | `release-procedure.md` | Pre-release checklist and report |

### Hooks

`.claude/hooks/hooks.md` documents six guardrails (format reminder, delete guard,
test reminder, sensitive-directory guard, no-secrets, proposal-before-refactor).
These are **voluntary behavioral conventions**, not automatic or harness-enforced
controls — Claude follows them because it reads the file. No `.claude/settings.json`
exists in this template; the only settings file present is `.claude/settings.local.json`
(permissions only). To enforce any of them at the harness level, add a `hooks` block
to a settings file.

---

## How to Enable This as a GitHub Template

1. Push this repository to GitHub.
2. Go to **Settings → General**.
3. Check **Template repository**.
4. The **"Use this template"** button now appears on the repository page.

---

*Built as part of a professional software engineering portfolio system.*
