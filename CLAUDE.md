# CLAUDE.md — Repository Memory File

> **READ THIS FIRST.** This is your operating guide for this repository.
> Do not modify any code, rename any files, or restructure any directories
> until you have completed the Repository Entry Protocol in
> `.claude/skills/entry-protocol.md`.

---

## 1. Project Identity

**Project Name:** `{{PROJECT_NAME}}`
**Purpose (WHY):** `{{PROJECT_DESCRIPTION}}`
**Status:** `{{STATUS}}`  <!-- Active Development | Maintenance | Portfolio | Archived -->
**Primary Language(s):** `{{LANGUAGE}}`
**Framework(s):** `{{FRAMEWORK}}`
**Owner / Portfolio:** `{{GITHUB_USERNAME}}`

---

## 2. Repository Map (WHAT)

```
{{REPO_TREE}}
```

<!-- Run `tree -L 3 --gitignore` and paste the output above after first scan -->

**Key Entry Points:**
- `{{ENTRY_POINT_1}}`
- `{{ENTRY_POINT_2}}`

**Configuration Files:**
- `.env.example` — environment variable reference (never commit `.env`)
- `{{CONFIG_FILE_2}}`

**Test Suite:**
- `tests/` — {{TEST_FRAMEWORK}}, run with `{{TEST_COMMAND}}`

---

## 3. Rules + Commands (HOW)

### ✅ Allowed Without Asking
- Read any file
- Improve documentation (docstrings, comments, README, CLAUDE.md)
- Fix formatting and style inconsistencies
- Add or improve inline comments
- Add new test files in `tests/`
- Update `.env.example` with new variable names (never values)

### ⚠️ Requires Explicit Approval Before Executing
- Renaming or moving any file or directory
- Changing function signatures or public APIs
- Adding, removing, or upgrading dependencies
- Modifying database schemas or migration files
- Editing files in `src/auth/`, `src/billing/`, or `infra/`
- Deleting any file
- Creating new top-level directories

### 🚫 Never Do
- Commit or push to any branch
- Execute `rm -rf` or any irreversible destructive command
- Modify `.env` files or embed secrets in source code
- Run `DROP TABLE`, truncate databases, or execute destructive SQL
- Merge branches or create releases

### Common Commands
```bash
# Install dependencies
{{INSTALL_COMMAND}}

# Run the application
{{RUN_COMMAND}}

# Run tests
{{TEST_COMMAND}}

# Run linter + formatter
{{LINT_COMMAND}}

# Validate repository structure
bash scripts/validate-structure.sh
```

---

## 4. Repository Governance Rules

Documentation is the source of truth for this repository. Code follows documentation — never the reverse.

### External Orchestration Boundary

An external orchestration system (such as Claude Cowork) may determine **what** task is being worked on and **when** work begins. This repository governs **how** implementation is performed. External orchestration does not override repository-level implementation constraints, permission tiers, or the authority hierarchy defined below. If an external system routes a task to this repository, the task is executed under this repository's rules.

### Authority Hierarchy

```
Paper / External Sources
         ↓
   Evidence Ledger
         ↓
 Architecture Document
         ↓
    ADR Decisions
         ↓
 Implementation Plan
         ↓
        Code
```

Each layer is authoritative over everything below it. If code and documentation disagree, documentation wins and the code must be corrected — or an explicit change request must be approved before documentation is updated.

### Layer Responsibilities

| Layer | Location | Role |
|-------|----------|------|
| External sources | Research papers, specs, reports | Primary evidence; facts extracted here are non-negotiable |
| Evidence ledger | `docs/evidence.md` *(if applicable)* | Confirmed facts extracted from external sources; separates evidence from assumptions |
| Architecture | `docs/architecture.md` | System design, component map, data flow |
| ADRs | `docs/adr/*.md` | Binding architectural decisions with documented rationale |
| Implementation plan | `docs/implementation-plan.md` *(if applicable)* | Coding order, module scope, deliverables |
| Code | `src/` | Implementation — must conform to all layers above |

### Rules

- ADRs are binding once accepted. Do not re-litigate an accepted ADR without creating a superseding one.
- The implementation plan defines what gets built and in what order. Code must follow it.
- An AI assistant must not modify ADRs or the implementation plan automatically.

### Conflict Resolution Protocol

If a conflict is discovered — the plan cannot be followed exactly as written — the assistant must:

1. **Report** the conflict: what the plan specifies vs. what the implementation requires.
2. **Explain** why the current plan cannot be followed exactly.
3. **Propose** a specific, minimal change to the plan or ADR.
4. **Wait** for explicit approval before modifying any documentation.

Do not silently deviate from the plan. Do not edit governance documents without completing this protocol.

---

## 5. Implementation Plan Authority

`docs/implementation-plan.md` is the authoritative coding guide for this repository when present.

### Status During Coding Passes

The implementation plan is **read-only during coding passes**. It defines what to build and in what order. An AI assistant must not edit it while implementing code — not to mark progress, not to add notes, not to correct phrasing.

### Progress Reporting

Report implementation progress in responses rather than by editing the file:

> "Completed: `src/config.py`, `src/data.py`. Next: `src/env.py`."

### Conflict Protocol

If a true implementation conflict is discovered during a coding pass:

1. **Stop** the current coding pass.
2. **Report** the conflict clearly: plan specification vs. what the code requires.
3. **Propose** a minimal, targeted change to the plan.
4. **Wait** for explicit approval.

Once approved: update the plan first, then update the code to match.

---

## 6. Architecture Summary

`{{ARCHITECTURE_SUMMARY}}`

> Full system design, component breakdown, and data flow are documented in
> `docs/architecture.md`. Key technical decisions are in `docs/adr/`.

---

## 7. Known Issues / Sharp Edges

<!-- Fill this in after running the entry protocol. Examples below: -->
- `{{SHARP_EDGE_1}}` — e.g., `src/auth/` token logic is tightly coupled to legacy session model. Do not refactor without approval.
- `{{SHARP_EDGE_2}}` — e.g., `migrations/` must be applied in strict order. Never reorder.

---

## 8. Skills Available

| Skill | File | Purpose |
|-------|------|---------|
| Entry Protocol | `.claude/skills/entry-protocol.md` | **Run first** — mandatory scan before any changes |
| Code Review | `.claude/skills/code-review.md` | Structured review with severity-labeled findings |
| Refactor Playbook | `.claude/skills/refactor-playbook.md` | Safe, proposal-first refactoring workflow |
| Documentation | `.claude/skills/documentation.md` | Docstrings, README, architecture docs, ADRs |
| QA Checklist | `.claude/skills/qa-checklist.md` | Test coverage + portfolio readiness audit |
| Release Procedure | `.claude/skills/release-procedure.md` | Steps before tagging a version |

---

## 9. Hooks (Behavioral Conventions)

> These are **voluntary behavioral conventions**, not automatic or harness-enforced
> controls. They take effect only because Claude reads `.claude/hooks/hooks.md` and
> chooses to follow them. They are **not** executed by the harness unless separately
> configured as real hooks in `.claude/settings.json`. See `.claude/hooks/hooks.md`
> for the authoritative status.

| Hook | Trigger | Convention |
|------|---------|------------|
| `post-edit-format` | After editing `.py` / `.ts` / `.js` files | Suggest running formatter |
| `pre-delete-guard` | Before any file deletion | Halt and require explicit confirmation |
| `test-on-core-change` | After editing files in `src/` | Remind to run test suite |
| `block-sensitive-dirs` | Before modifying `auth/`, `billing/`, `infra/`, `migrations/` | Halt and require approval |
| `no-secrets-in-code` | Before writing string literals resembling keys/tokens | Replace with env variable pattern |
| `proposal-before-refactor` | Before renaming, moving, or changing signatures | Write proposal first |

---

## 10. Documentation Index

| Document | Location | Description |
|----------|----------|-------------|
| Architecture Overview | `docs/architecture.md` | Full system design and component breakdown |
| ADR Index | `docs/adr/` | All architectural decision records |
| Implementation Plan | `docs/implementation-plan.md` | Coding order and module scope (create when applicable) |
| QA Plan | `docs/qa/qa-plan.md` | Test strategy and coverage map |
| QA Audit Record | `docs/qa/QA.md` | Permanent record of QA audit findings and verification results |
| Operations Runbook | `docs/runbooks/operations.md` | Setup, deployment, and troubleshooting |
| API Reference | `docs/api-reference.md` | Endpoint documentation (create when applicable) |

---

## 11. Portfolio Context

**Target Audience:** Graduate admissions reviewers (UT Austin MSCS), software engineering employers
**Demonstrates:** `{{DEMONSTRATES}}`  <!-- e.g., REST API design, async processing, TDD -->
**Key Technical Decisions:** See `docs/adr/` for documented rationale
**Portfolio Repository:** Yes — maintain professional commit history and documentation standards

---

<!-- TEMPLATE-MIRROR:SECTION12:START -->
## 12. Agent Operating Constraints

These are mandatory operating constraints for Claude Code to prevent context loss, silent truncation errors, incorrect edits, incomplete search results, and unsafe multi-file execution. They apply to **all repositories** instantiated from this template.

### 12.1 Dead Code First

Before any structural refactor on large files:

- Remove unused imports, exports, props, and debug logs
- Perform cleanup as a separate change set
- Do NOT combine cleanup and refactor in the same pass

### 12.2 Batched Execution

For tasks touching multiple files:

- Break work into small batches (max ~5 files per batch)
- Complete and verify each batch before continuing
- State the batch plan before starting so the user can confirm grouping

### 12.3 Context Decay Awareness

- Do NOT rely on memory of file contents after long conversations
- Re-read files before editing when uncertain
- If context compaction may have fired, say so explicitly

### 12.4 File Read Limits

- Large files may be silently truncated when read
- Read files in chunks when necessary (state chunk boundaries explicitly)
- Never assume full file visibility from a single read

### 12.5 Tool Result Awareness

- Search results may be incomplete due to truncation
- Re-run searches with narrower scope if results look suspiciously small
- Never treat a small result set as definitively complete without scoped verification

### 12.6 Edit Integrity

For every edit:

1. Read the file immediately before editing
2. Apply the change
3. Re-read the file after editing to confirm the change applied correctly

If a re-read reveals the edit did not apply, diagnose the mismatch before retrying.

### 12.7 No Semantic Assumptions

- Search tools perform text matching only — not semantic code understanding
- Do NOT assume a single search caught all references
- On any rename, signature change, or symbol deletion: check direct calls, type references, string literals, dynamic imports, re-exports, test files, and config files separately

### 12.8 Rule Suspension

If the user explicitly states **"suspend rule X for this session"**, that rule is temporarily inactive until the user says **"restore rules"** or a new session begins. Rules may only be suspended by the user — do not self-suspend a rule because it is inconvenient.

<!-- TEMPLATE-MIRROR:SECTION12:END -->

---

<!-- TEMPLATE-MIRROR:FOOTER:START -->
*Last updated by Claude: `{{LAST_UPDATED}}`*
*Entry protocol completed: `no — run on first session`*
<!-- TEMPLATE-MIRROR:FOOTER:END -->
