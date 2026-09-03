# Template Propagation Procedure

**Status:** Authored 2026-08-02 per Ruben's A1-1 ruling (repo-audit-plan-5-portfolio-base-template-2026-07-12.md).
**Root-cause context:** Repo audit #5 (2026-07-12) found no propagation mechanism,
manifest, or version pin existed anywhere in this repository — the root cause of
staleness found across every downstream target audited in the #3/#4 sequence (e.g.
the 2026-04-01 sync shipping a validator variant that no longer exists in this
template; the 2026-07-02 revision having no path to reach targets at all). This
document is the procedure half of that fix. `scripts/propagation-manifest.tsv` is
the pinned-hash half.

## Scope note — this document does not activate anything

This document describes HOW a template change would reach a target repo, if and
when that is authorized. **It does not itself authorize propagation to any
target.** Each target (currently NarrVoca-Personal, SportsChatPlus-V2) requires
its own separate, explicit (re-)registration or ruling before any sync dispatch
against it is executed. Writing this procedure is not a dispatch.

## The four-step lifecycle

### 1. Template change → bump pins in manifest (same change)

When any file listed in `scripts/propagation-manifest.tsv` is edited in this
template repo:

1. Recompute that file's SHA-256.
2. Update its `sha256_live` cell in the manifest, in the **same** change/commit
   scope as the file edit — never a separate follow-up step.
3. Re-derive `status`: `PINNED` if the new live hash is what you intend as the
   new baseline, or leave a `DRIFT` marker only transiently while a change is
   in flight and not yet ratified.
4. If the file's MIRROR/ADAPT role changes, update the `role` column and state
   the reason in the manifest's header comments or the authoring session log.

A template file with no manifest row is not propagation-governed — adding a new
mirror-governed file means adding its row here first.

### 2. Bounded, Ruben-ratified per-target sync dispatch

Propagation to a target is never automatic and never triggered by the manifest
alone. For each target:

- Ruben authorizes a bounded dispatch, scoped explicitly to the manifest rows
  being synced (file list, not "sync everything").
- The dispatch copies only `role: MIRROR` files verbatim. `role: ADAPT` files
  are never copied verbatim — see the per-target adaptation note below.
- No git commands are used to perform the sync (standing constraint — this
  repo and its targets forbid agent-run git).
- Target-local customizations (e.g. that target's own `.claude/hooks/hooks.md`
  content beyond the mirrored governance frame) are never overwritten by a
  MIRROR-role sync.

### 3. Post-sync verification: target hashes against pins

After a sync dispatch completes:

1. Recompute SHA-256 for every synced file on the target side.
2. Compare against the manifest's `sha256_live` pins recorded in this template
   repo at dispatch time (not the target's own prior hash).
3. Any mismatch halts and is reported — it is never silently reconciled by
   re-copying or by adopting the target's hash into the template's manifest.
4. A clean verification (all synced files match pins) is the only condition
   under which the sync is considered complete.

### 4. No manifest entry → no propagation

If a file is not a row in `scripts/propagation-manifest.tsv`, it is not
propagation-governed and must not be included in a sync dispatch, regardless of
whether it "looks like" it should mirror. Add the row (step 1) first.

## Per-target adaptation note: `.env.example`

`.env.example` in this template is not itself a manifest row (it is
project-bootstrap scaffolding, not a mirror-governed governance/tooling file),
but it illustrates the general MIRROR-vs-ADAPT split for any file that does
carry environment-specific content: when a MIRROR-role governance file
references or depends on an environment file, each target adapts the reference
to its own local convention — e.g. `.env.example` in this template corresponds
to `.env.local.example` (or whatever naming convention that target already
uses) on the target side. The propagation dispatch must translate the filename
reference per-target rather than copying the template's literal filename.

## Stop conditions

- No manifest entry for a file → do not propagate it.
- Pin mismatch discovered during verification → halt and report; do not
  silently adopt either side's hash.
- No git commands, ever, on either surface.
- No sync dispatch without Ruben's explicit per-target ratification.
- A target's local customizations outside the MIRROR-governed regions are
  never overwritten.

## Related

- `scripts/propagation-manifest.tsv` — the pinned file list this procedure
  operates against.
- `docs/template-mirror.md` — the TEMPLATE-MIRROR convention (SECTION12 +
  FOOTER regions in `CLAUDE.md`) that MIRROR-role propagation of `CLAUDE.md`
  itself must respect.
- `6_control/repo-audit-5-portfolio-base-template-2026-07-12.md` — the audit
  and Baseline Pin Table this manifest was seeded from.
