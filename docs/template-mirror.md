# TEMPLATE-MIRROR Convention

**Status:** Authored 2026-08-02 per Ruben's A1-1 ruling (repo-audit-plan-5-portfolio-base-template-2026-07-12.md).
**Finding this closes:** Repo audit #5 (2026-07-12) found the TEMPLATE-MIRROR
comment markers present in `CLAUDE.md` (lines ~243, 302, 306, 309 at audit
time) but their semantics documented nowhere and consumed by no tool — the
markers presupposed a propagation mechanism that did not exist. This document
is that missing definition.

## What the markers are

`CLAUDE.md` contains two HTML-comment-delimited regions:

```
<!-- TEMPLATE-MIRROR:SECTION12:START -->
## 12. Agent Operating Constraints
...
<!-- TEMPLATE-MIRROR:SECTION12:END -->
```

and

```
<!-- TEMPLATE-MIRROR:FOOTER:START -->
*Last updated by Claude: `{{LAST_UPDATED}}`*
*Entry protocol completed: `no — run on first session`*
<!-- TEMPLATE-MIRROR:FOOTER:END -->
```

## Semantics

- **Content inside a `TEMPLATE-MIRROR:*:START`…`:END` pair is MIRROR content.**
  It propagates to every target repo **verbatim** — byte-for-byte, no
  per-target rewording, no per-target token substitution beyond the template's
  own standard `{{PLACEHOLDER}}` tokens (which each target fills at its own
  bootstrap time, not at propagation time).
- **Everything in `CLAUDE.md` outside those two regions is ADAPT content.**
  Targets may customize it (project identity fields, portfolio context,
  documentation index entries specific to that repo, etc.) and a propagation
  sync must never overwrite those sections wholesale.
- The two named regions today are:
  - **SECTION12** (`## 12. Agent Operating Constraints`) — the mandatory
    agent operating constraints (dead-code-first, batched execution, context
    decay awareness, file read limits, tool result awareness, edit integrity,
    no semantic assumptions, rule suspension). These apply identically to
    every repository instantiated from this template; they are not project
    -specific and must not drift target-to-target.
  - **FOOTER** — the `Last updated by Claude` / `Entry protocol completed`
    stamp lines at the end of `CLAUDE.md`. These are structurally identical
    across every target (same two fields, same format) even though their
    *values* are filled in per-repo at runtime — the mirrored part is the
    field structure/labels, not a frozen value.

## How this integrates with the propagation manifest

`CLAUDE.md` is a `role: MIRROR` row in `scripts/propagation-manifest.tsv`
(see `docs/propagation.md`). When `CLAUDE.md` is the file being synced to a
target:

1. The whole-file MIRROR classification governs sync eligibility (it is a
   manifest row at all).
2. Within the file, the TEMPLATE-MIRROR markers govern **which regions** of
   the synced content overwrite the target's existing `CLAUDE.md` verbatim
   (SECTION12, FOOTER structure) versus which regions a sync must leave
   untouched on the target side (everything else — the target's own §1
   Project Identity, §11 Portfolio Context values, any target-added
   documentation-index rows, etc.).
3. A future propagation tool that reads these markers should target ONLY the
   delimited regions for verbatim replacement and must never touch content
   outside them. No such tool exists today (per the audit finding); this
   document defines the contract such a tool — or a manual, Ruben-ratified
   sync — must follow in the meantime.

## Adding a new mirrored region

If a future template change needs a new verbatim-mirrored region elsewhere in
`CLAUDE.md` (or another MIRROR-role file):

1. Wrap it in a new `<!-- TEMPLATE-MIRROR:<NAME>:START -->` /
   `<!-- TEMPLATE-MIRROR:<NAME>:END -->` pair, `<NAME>` unique within the file.
2. Document the new region in this file (semantics, what it governs, why it
   must not drift target-to-target).
3. Confirm the containing file's manifest row / hash pin is bumped per
   `docs/propagation.md` step 1.

## Stop conditions

- A region without START/END markers is never treated as mirror content by
  inference — only explicitly delimited regions mirror verbatim.
- Marker regions are never partially propagated (e.g. mirroring only some
  lines within SECTION12); the whole delimited block moves as a unit.
- See `docs/propagation.md` for the full sync/verification lifecycle and its
  stop conditions.
