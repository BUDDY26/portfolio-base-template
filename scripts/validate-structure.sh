#!/usr/bin/env bash
# =============================================================================
# validate-structure.sh — Repository Structure Validator (state-aware)
#
# Purpose:
#   Checks that the repository conforms to the portfolio-base template standard.
#   Prints a pass/fail report. Exits 0 on pass, 1 on failure.
#
#   Placeholder token names and categories are read from scripts/template-tokens.tsv,
#   which is the single source of truth. This script keeps no independent token list.
#
# Usage:
#   bash scripts/validate-structure.sh
#   bash scripts/validate-structure.sh --strict   # fail on warnings too
#
# Requires: Bash 4+ (uses associative arrays).
#   Windows: Git Bash (Bash 4+), WSL (Bash 4+), or another environment providing Bash 4+.
# =============================================================================

set -euo pipefail

# ── Bash version guard (associative arrays require Bash 4+) ────────────────────
if [ -z "${BASH_VERSINFO:-}" ] || [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
  echo "ERROR: This script requires Bash 4 or newer (it uses associative arrays)." >&2
  echo "       Use Git Bash (Bash 4+), WSL (Bash 4+), or another environment providing Bash 4+." >&2
  exit 1
fi

STRICT=false
[[ "${1:-}" == "--strict" ]] && STRICT=true

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

FAILURES=0
WARNINGS=0

pass()  { echo -e "  ${GREEN}\xE2\x9C\x93${RESET}  $*"; }
fail()  { echo -e "  ${RED}\xE2\x9C\x97${RESET}  $*"; FAILURES=$((FAILURES + 1)); }
warn()  { echo -e "  ${YELLOW}\xE2\x9A\xA0${RESET}  $*"; WARNINGS=$((WARNINGS + 1)); }
header(){ echo -e "\n${BOLD}$*${RESET}"; echo "$(printf '─%.0s' {1..50})"; }

TOKENS_TSV="scripts/template-tokens.tsv"

# ── The single exclusion set ──────────────────────────────────────────────────
# Files that document token *examples* rather than containing active template
# placeholders. Defined ONCE here and used identically by the repository-vs-taxonomy
# equality check and the unresolved-placeholder classification check.
TOKEN_EXCLUDE_BASENAMES=( "TEMPLATE_USAGE.md" )

# Print the sorted, unique set of placeholder tokens found in *active* template
# sources (applying the single exclusion set above). Bare names, no braces.
scan_repo_tokens() {
  local excl=() b
  for b in "${TOKEN_EXCLUDE_BASENAMES[@]}"; do excl+=( "--exclude=$b" ); done
  grep -rEoh \
      --include='*.md' --include='*.markdown' --include='*.yml' --include='*.yaml' --include='*.sh' \
      "${excl[@]}" \
      --exclude-dir=.git --exclude-dir=.venv --exclude-dir=node_modules \
      "\{\{[A-Z_0-9]+\}\}" . 2>/dev/null | sed 's/[{}]//g' | sort -u || true
}

# ── Lifecycle state ───────────────────────────────────────────────────────────
BOOTSTRAPPED=false
[[ -f ".bootstrap-complete" ]] && BOOTSTRAPPED=true

# ── Load & validate the token taxonomy ────────────────────────────────────────
header "Token Taxonomy"

declare -A CAT
TAXONOMY_OK=true

if [[ ! -f "$TOKENS_TSV" ]]; then
  fail "$TOKENS_TSV  ← MISSING (required single source of truth for tokens)"
  TAXONOMY_OK=false
else
  # Malformed rows: non-comment, non-blank lines whose field count != 3 or with an empty token.
  MALFORMED=$(awk -F'\t' '
    /^[[:space:]]*#/ { next } /^[[:space:]]*$/ { next }
    (NF != 3 || $1 == "") { c++ } END { print c+0 }' "$TOKENS_TSV")
  # Unknown categories: field 2 not one of identity/deferred/meta.
  BADCAT=$(awk -F'\t' '
    /^[[:space:]]*#/ { next } /^[[:space:]]*$/ { next }
    ($2 != "identity" && $2 != "deferred" && $2 != "meta") { c++ } END { print c+0 }' "$TOKENS_TSV")
  # Duplicate token names.
  DUPES=$(awk -F'\t' '
    /^[[:space:]]*#/ { next } /^[[:space:]]*$/ { next }
    { seen[$1]++ } END { for (t in seen) if (seen[t] > 1) printf "%s(x%d) ", t, seen[t] }' "$TOKENS_TSV")

  if [[ "$MALFORMED" -gt 0 ]]; then
    fail "Taxonomy has $MALFORMED malformed row(s) (expected TOKEN<TAB>CATEGORY<TAB>NOTE)"
    TAXONOMY_OK=false
  fi
  if [[ "$BADCAT" -gt 0 ]]; then
    fail "Taxonomy has $BADCAT row(s) with an unknown category (allowed: identity, deferred, meta)"
    TAXONOMY_OK=false
  fi
  if [[ -n "$DUPES" ]]; then
    fail "Taxonomy has duplicate token name(s): $DUPES"
    TAXONOMY_OK=false
  fi

  # Load rows into CAT[token]=category (first occurrence; duplicates already flagged above).
  while IFS=$'\t' read -r tok cat _note; do
    [[ "$tok" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$tok" ]] && continue
    case "$cat" in identity|deferred|meta) [[ -z "${CAT[$tok]:-}" ]] && CAT["$tok"]="$cat" ;; esac
  done < "$TOKENS_TSV"

  if [[ "$TAXONOMY_OK" == "true" ]]; then
    ID_CT=0; DEF_CT=0; META_CT=0
    for t in "${!CAT[@]}"; do
      case "${CAT[$t]}" in
        identity) ID_CT=$((ID_CT+1));;
        deferred) DEF_CT=$((DEF_CT+1));;
        meta)     META_CT=$((META_CT+1));;
      esac
    done
    pass "Taxonomy loaded: ${#CAT[@]} tokens (identity=$ID_CT deferred=$DEF_CT meta=$META_CT)"
  fi
fi

# ── Required files (always required) ──────────────────────────────────────────
header "Required Files"

REQUIRED_FILES=(
  "CLAUDE.md"
  "README.md"
  ".gitignore"
  ".env.example"
  ".claude/skills/entry-protocol.md"
  ".claude/skills/code-review.md"
  ".claude/skills/refactor-playbook.md"
  ".claude/skills/documentation.md"
  ".claude/skills/qa-checklist.md"
  ".claude/skills/release-procedure.md"
  ".claude/hooks/hooks.md"
  "docs/architecture.md"
  "docs/implementation-plan.md"
  "docs/adr/ADR-001-template.md"
  "docs/qa/qa-plan.md"
  "docs/qa/QA.md"
  "docs/runbooks/operations.md"
  "scripts/bootstrap.sh"
  "scripts/validate-structure.sh"
  "scripts/template-tokens.tsv"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [[ -f "$f" ]]; then pass "$f"; else fail "$f  ← MISSING"; fi
done

# ── Lifecycle-specific files ──────────────────────────────────────────────────
header "Template Lifecycle"

if [[ "$BOOTSTRAPPED" == "false" ]]; then
  echo "  State: PRE-BOOTSTRAP (.bootstrap-complete absent)"
  if [[ -f "TEMPLATE_README.md" ]]; then
    pass "TEMPLATE_README.md present (will be promoted to README.md by bootstrap)"
  else
    fail "TEMPLATE_README.md  ← MISSING (required before bootstrap)"
  fi
else
  echo "  State: POST-BOOTSTRAP (.bootstrap-complete present)"
  if [[ -f "docs/TEMPLATE_USAGE.md" ]]; then
    pass "docs/TEMPLATE_USAGE.md present (template instructions preserved)"
  else
    fail "docs/TEMPLATE_USAGE.md  ← MISSING (bootstrap must preserve template usage)"
  fi
  if [[ -f "TEMPLATE_README.md" ]]; then
    fail "TEMPLATE_README.md still present after bootstrap  ← lifecycle inconsistency"
  else
    pass "TEMPLATE_README.md removed after promotion"
  fi
fi

# ── Required directories ──────────────────────────────────────────────────────
header "Required Directories"

REQUIRED_DIRS=(
  "src" "tests" "tests/unit" "tests/integration"
  "docs" "docs/adr" "docs/qa" "docs/runbooks"
  "scripts" ".claude/skills" ".claude/hooks" ".github/workflows"
)

for d in "${REQUIRED_DIRS[@]}"; do
  if [[ -d "$d" ]]; then pass "$d/"; else fail "$d/  ← MISSING"; fi
done

# ── CI/CD files (recommended) ─────────────────────────────────────────────────
header "CI/CD Files"

CI_FILES=(
  ".github/workflows/ci.yml"
  ".github/ISSUE_TEMPLATE/bug-report.md"
  ".github/ISSUE_TEMPLATE/feature-request.md"
  ".github/pull_request_template.md"
  ".github/dependabot.yml"
)

for f in "${CI_FILES[@]}"; do
  if [[ -f "$f" ]]; then pass "$f"; else warn "$f  ← missing (recommended)"; fi
done

# ── License policy (post-bootstrap only) ──────────────────────────────────────
if [[ "$BOOTSTRAPPED" == "true" ]]; then
  header "License Policy"
  LICENSE_SEL=$(awk -F': ' '/^license:/ { print $2; exit }' .bootstrap-complete 2>/dev/null || true)
  LICENSE_SEL=${LICENSE_SEL//[$'\r\n']/}
  case "$LICENSE_SEL" in
    MIT)
      if [[ -f "LICENSE" ]] && grep -q "MIT License" LICENSE && grep -q "Permission is hereby granted" LICENSE; then
        pass "LICENSE present and matches selection: MIT"
      else
        fail "Selection is MIT but LICENSE is missing or not valid MIT text"
      fi ;;
    Apache-2.0)
      if [[ -f "LICENSE" ]] && grep -q "Apache License" LICENSE && grep -q "Version 2.0" LICENSE; then
        pass "LICENSE present and matches selection: Apache-2.0"
      else
        fail "Selection is Apache-2.0 but LICENSE is missing or not valid Apache-2.0 text"
      fi ;;
    None)
      if [[ -f "LICENSE" ]]; then
        warn "Selection recorded as None but a LICENSE file exists (verify this is intentional)"
      else
        pass "Selection is None: no LICENSE required"
      fi ;;
    "") warn "No license selection recorded in .bootstrap-complete (cannot verify license policy)" ;;
    *)  warn "Unrecognized license selection '$LICENSE_SEL' in .bootstrap-complete" ;;
  esac
fi

# ── Placeholder token integrity (taxonomy-driven, lifecycle-aware) ────────────
header "Placeholder Token Integrity"

if [[ "$TAXONOMY_OK" != "true" ]]; then
  warn "Skipping token integrity checks — taxonomy is invalid (see above)"
else
  # One scan of active sources (single exclusion set), reused by every check below.
  REPO_TOKENS=$(scan_repo_tokens)

  declare -A INREPO
  UNRESOLVED_IDENTITY=""
  UNKNOWN_TOKENS=""
  if [[ -n "$REPO_TOKENS" ]]; then
    while IFS= read -r tok; do
      [[ -z "$tok" ]] && continue
      INREPO["$tok"]=1
      local_cat="${CAT[$tok]:-__UNKNOWN__}"
      case "$local_cat" in
        identity)      UNRESOLVED_IDENTITY+="$tok " ;;   # present but unfilled
        deferred|meta) : ;;                              # allowed to remain
        *)             UNKNOWN_TOKENS+="$tok " ;;        # not registered in taxonomy
      esac
    done <<< "$REPO_TOKENS"
  fi

  # (a) Unknown repository tokens fail in BOTH lifecycle states.
  if [[ -n "$UNKNOWN_TOKENS" ]]; then
    fail "Repository placeholder(s) absent from the taxonomy: $UNKNOWN_TOKENS"
  fi

  # (b) Pre-bootstrap only: enforce exact equality — no taxonomy-only tokens.
  if [[ "$BOOTSTRAPPED" == "false" ]]; then
    TAXONOMY_ONLY=""
    for tok in "${!CAT[@]}"; do
      [[ -z "${INREPO[$tok]:-}" ]] && TAXONOMY_ONLY+="$tok "
    done
    if [[ -n "$TAXONOMY_ONLY" ]]; then
      fail "Taxonomy token(s) not present in active template sources: $TAXONOMY_ONLY"
    fi
    if [[ -z "$UNKNOWN_TOKENS" && -z "$TAXONOMY_ONLY" ]]; then
      pass "Pre-bootstrap: repository token set equals taxonomy token set"
    fi
  else
    if [[ -z "$UNKNOWN_TOKENS" ]]; then
      pass "Post-bootstrap: all remaining placeholders are registered in the taxonomy"
    fi
  fi

  # (c) Unresolved identity tokens: warning (ordinary) / failure (strict).
  if [[ -n "$UNRESOLVED_IDENTITY" ]]; then
    warn "Unresolved identity tokens (must be filled): $UNRESOLVED_IDENTITY"
  fi
  echo "  (deferred and meta tokens are allowed to remain; example files ${TOKEN_EXCLUDE_BASENAMES[*]} are excluded)"
fi

# ── Bootstrap status ──────────────────────────────────────────────────────────
header "Bootstrap Status"

if [[ "$BOOTSTRAPPED" == "true" ]]; then
  pass "Bootstrap has been run"
  sed 's/^/      /' .bootstrap-complete
else
  warn "Bootstrap has not been run — run: bash scripts/bootstrap.sh"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "$(printf '─%.0s' {1..50})"
echo -e "${BOLD}Results:${RESET}"
echo -e "  Failures:  ${FAILURES}"
echo -e "  Warnings:  ${WARNINGS}"
echo ""

if [[ $FAILURES -gt 0 ]]; then
  echo -e "${RED}${BOLD}FAIL${RESET} — $FAILURES required check(s) failed."
  exit 1
elif [[ $WARNINGS -gt 0 && "$STRICT" == "true" ]]; then
  echo -e "${YELLOW}${BOLD}WARN${RESET} — $WARNINGS warning(s) in strict mode."
  exit 1
else
  echo -e "${GREEN}${BOLD}PASS${RESET} — Repository structure is valid."
  exit 0
fi
