#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Portfolio Base Template Setup Script
#
# Purpose:
#   Fills project-identity placeholder tokens throughout the repository, promotes
#   the project README, and records a license choice. Run once immediately after
#   creating a repository from portfolio-base-template.
#
#   Token names and categories come from scripts/template-tokens.tsv (the single
#   source of truth). This script keeps no independent list of token names.
#   Only "identity" tokens are filled here. "deferred" tokens (implementation
#   plan, QA records, releases) and "meta" tokens are intentionally left as-is.
#
# Usage:
#   bash scripts/bootstrap.sh
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

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }
header()  { echo -e "\n${BOLD}$*${RESET}"; echo "$(printf '─%.0s' {1..60})"; }

TOKENS_TSV="scripts/template-tokens.tsv"

# ── Guards ────────────────────────────────────────────────────────────────────
[[ -f "CLAUDE.md" ]]          || error "Run this script from the repository root (where CLAUDE.md lives)."
[[ -f "$TOKENS_TSV" ]]        || error "Missing $TOKENS_TSV (token taxonomy)."
[[ ! -f ".bootstrap-complete" ]] || error "This repository is already bootstrapped (.bootstrap-complete exists). Aborting."
[[ -f "TEMPLATE_README.md" ]] || error "Missing TEMPLATE_README.md (the project README scaffold to promote)."
[[ -f "README.md" ]]          || error "Missing README.md (the template-usage instructions to preserve)."
[[ ! -e "LICENSE" ]]          || error "A LICENSE file already exists. It will not be overwritten. Review or remove it first, then re-run and select MIT, Apache-2.0, or None."

TODAY="$(date +%Y-%m-%d)"
YEAR="$(date +%Y)"

# ── sed-safe replacement ──────────────────────────────────────────────────────
# Escapes backslash, ampersand (whole-match in sed RHS), and the | delimiter.
replace_in_file() {
  local file="$1" token="$2" value="$3" esc
  esc=$(printf '%s' "$value" | sed -e 's/[\\&|]/\\&/g')
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s|{{${token}}}|${esc}|g" "$file"
  else
    sed -i "s|{{${token}}}|${esc}|g" "$file"
  fi
}

# Replace one identity token across all text files, preserving docs/TEMPLATE_USAGE.md
# (which intentionally documents token syntax) and skipping .git/.venv.
replace_all() {
  local token="$1" value="$2"
  while IFS= read -r -d '' file; do
    replace_in_file "$file" "$token" "$value"
  done < <(find . -type f \
      -not -path "./.git/*" -not -path "./.venv/*" \
      -not -path "./docs/TEMPLATE_USAGE.md" \
      \( -name "*.md" -o -name "*.markdown" -o -name "*.yml" -o -name "*.yaml" \
         -o -name "*.sh" -o -name "*.txt" -o -name "*.env" -o -name "*.example" \
         -o -name ".gitignore" \) -print0)
}

# ── License selection ─────────────────────────────────────────────────────────
LICENSE_CHOICE="None"
LICENSE_DISPLAY="No license specified"

choose_license() {
  echo ""
  echo "  Select a license for this project:"
  echo "    1) MIT"
  echo "    2) Apache-2.0"
  echo "    3) None  (default — no LICENSE file, unlicensed)"
  local lic
  read -rp "  Choice [1/2/3] (default 3): " lic
  case "${lic:-3}" in
    1|MIT|mit)              LICENSE_CHOICE="MIT";        LICENSE_DISPLAY="MIT" ;;
    2|Apache-2.0|apache|APACHE) LICENSE_CHOICE="Apache-2.0"; LICENSE_DISPLAY="Apache-2.0" ;;
    3|None|none|"")         LICENSE_CHOICE="None";       LICENSE_DISPLAY="No license specified" ;;
    *)  warn "Unrecognized choice '${lic}' — defaulting to None."
        LICENSE_CHOICE="None"; LICENSE_DISPLAY="No license specified" ;;
  esac
}

generate_license() {
  local author="${VAL[GITHUB_USERNAME]:-}"
  [[ -z "$author" ]] && author="${VAL[PROJECT_NAME]}"
  case "$LICENSE_CHOICE" in
    MIT)
      cat > LICENSE <<EOF
MIT License

Copyright (c) ${YEAR} ${author}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
      success "Generated MIT LICENSE (Copyright ${YEAR} ${author})."
      ;;
    Apache-2.0)
      cat > LICENSE <<'EOF'
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
EOF
      success "Generated Apache License 2.0 LICENSE."
      ;;
    None)
      info "No license selected — no LICENSE file created (project is unlicensed)."
      ;;
  esac
}

# ── Pass 1: collect identity values (no filesystem mutation yet) ──────────────
declare -A VAL

header "Portfolio Base — Bootstrap Setup"
echo "Answer the following. Press Enter to accept a default where offered."

while IFS=$'\t' read -r tok cat val <&3; do
  [[ "$tok" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$tok" ]] && continue
  [[ "$cat" != "identity" ]] && continue
  case "$val" in
    ASK_REQ:*)
      p="${val#ASK_REQ:}"
      read -rp "  ${p}: " ans
      [[ -z "$ans" ]] && error "${tok} cannot be empty."
      VAL["$tok"]="$ans" ;;
    ASK_DEFAULT_PROJECT:*)
      p="${val#ASK_DEFAULT_PROJECT:}"
      read -rp "  ${p} (default: ${VAL[PROJECT_NAME]}): " ans
      VAL["$tok"]="${ans:-${VAL[PROJECT_NAME]}}" ;;
    ASK:*)
      p="${val#ASK:}"
      read -rp "  ${p}: " ans
      VAL["$tok"]="$ans" ;;
    AUTO:date)   VAL["$tok"]="$TODAY" ;;
    AUTO:status) VAL["$tok"]="Active Development" ;;
    SPECIAL:license) choose_license; VAL["$tok"]="$LICENSE_DISPLAY" ;;
    NOTE:*)      VAL["$tok"]="${val#NOTE:}" ;;
    *) error "Unknown acquisition method for ${tok}: ${val}" ;;
  esac
done 3< "$TOKENS_TSV"

# ── Pass 2: mutation phase (transactional: snapshot + rollback on any failure) ─
#
# Before the first filesystem mutation we snapshot — outside the repository — every
# text file that may be modified, and record whether the files bootstrap may CREATE
# existed beforehand. A centralized EXIT/signal handler restores the pre-run state
# byte-for-byte on any error, signal, or failed validation, leaving no marker. On
# success the snapshot is discarded. No backup files are written inside the repo and
# no Git-based rollback is used.

SNAP="$(mktemp -d)"                 # system temp dir, outside the repository
SNAP_TREE="$SNAP/tree"
MANIFEST="$SNAP/manifest.txt"
MUTATION_STARTED=0
BOOT_DONE=0

# Pre-existence of files bootstrap may create (LICENSE and marker are guarded to be
# absent above; TEMPLATE_USAGE is normally absent). If present, they are restored
# from the snapshot instead of removed.
PRE_LICENSE=0; if [[ -e "LICENSE" ]]; then PRE_LICENSE=1; fi
PRE_MARKER=0;  if [[ -e ".bootstrap-complete" ]]; then PRE_MARKER=1; fi
PRE_USAGE=0;   if [[ -e "docs/TEMPLATE_USAGE.md" ]]; then PRE_USAGE=1; fi

take_snapshot() {
  mkdir -p "$SNAP_TREE"
  : > "$MANIFEST"
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#./}"
    mkdir -p "$SNAP_TREE/$(dirname "$rel")"
    cp -p "$f" "$SNAP_TREE/$rel"
    printf '%s\0' "$rel" >> "$MANIFEST"
  done < <(find . -type f \
      -not -path "./.git/*" -not -path "./.venv/*" \
      \( -name "*.md" -o -name "*.markdown" -o -name "*.yml" -o -name "*.yaml" \
         -o -name "*.sh" -o -name "*.txt" -o -name "*.env" -o -name "*.example" \
         -o -name ".gitignore" \) -print0)
}

rollback() {
  # Restore every snapshotted file byte-for-byte (recreates deleted/overwritten files).
  if [[ -f "$MANIFEST" ]]; then
    local rel
    while IFS= read -r -d '' rel; do
      mkdir -p "$(dirname "$rel")"
      cp -p "$SNAP_TREE/$rel" "$rel"
    done < "$MANIFEST"
  fi
  # Remove files bootstrap created that did not exist before this run.
  if [[ "$PRE_USAGE"   -eq 0 ]]; then rm -f "docs/TEMPLATE_USAGE.md"; fi
  if [[ "$PRE_LICENSE" -eq 0 ]]; then rm -f "LICENSE"; fi
  if [[ "$PRE_MARKER"  -eq 0 ]]; then rm -f ".bootstrap-complete"; fi
}

cleanup() {
  local rc=$?
  set +e                            # rollback must run to completion regardless
  if [[ "$BOOT_DONE" -eq 1 ]]; then
    rm -rf "$SNAP" 2>/dev/null
  else
    if [[ "$MUTATION_STARTED" -eq 1 ]]; then
      echo -e "${RED}[ROLLBACK]${RESET} Failure or interruption after mutation — restoring pre-bootstrap state..." >&2
      rollback
    fi
    rm -rf "$SNAP" 2>/dev/null
    [[ $rc -eq 0 ]] && rc=1
  fi
  exit $rc
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

take_snapshot
MUTATION_STARTED=1                  # from here, any failure triggers rollback

# README lifecycle
header "Promoting project README"
cp "README.md" "docs/TEMPLATE_USAGE.md"        # preserve template-usage instructions
cp "TEMPLATE_README.md" "README.md"            # promote project scaffold to root README
rm -f "TEMPLATE_README.md"                     # retire the scaffold
[[ -f "README.md" ]]               || error "README lifecycle failed: README.md missing after promotion."
[[ -f "docs/TEMPLATE_USAGE.md" ]]  || error "README lifecycle failed: docs/TEMPLATE_USAGE.md missing."
[[ ! -f "TEMPLATE_README.md" ]]    || error "README lifecycle failed: TEMPLATE_README.md still present."
success "README promoted; template usage preserved in docs/TEMPLATE_USAGE.md."

# Fill identity tokens only (deferred/meta untouched)
header "Filling identity placeholders"
FILLED=0
while IFS=$'\t' read -r tok cat _val; do
  [[ "$tok" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$tok" ]] && continue
  [[ "$cat" != "identity" ]] && continue
  replace_all "$tok" "${VAL[$tok]}"
  FILLED=$((FILLED + 1))
done < "$TOKENS_TSV"
success "Filled ${FILLED} identity tokens (deferred and meta tokens left untouched)."

# License file
header "License"
generate_license

# Completion marker (records license selection for the validator)
{
  echo "bootstrapped_on: $TODAY"
  echo "project: ${VAL[PROJECT_NAME]}"
  echo "github_username: ${VAL[GITHUB_USERNAME]:-}"
  echo "license: $LICENSE_CHOICE"
} > .bootstrap-complete

# Final validation gate — failure triggers full rollback via the trap
header "Validating repository structure (strict)"
if ! bash scripts/validate-structure.sh --strict; then
  error "Post-bootstrap validation failed. Rolling back."
fi

BOOT_DONE=1                         # success: keep bootstrapped state, discard snapshot
rm -rf "$SNAP" 2>/dev/null || true

# ── Next steps ────────────────────────────────────────────────────────────────
header "Bootstrap complete ✓"
echo ""
echo -e "${BOLD}Identity is filled and the license is set. Next, fill in project content:${RESET}"
echo ""
echo "  1. CLAUDE.md — architecture summary (Section 6) and sharp edges (Section 7)"
echo "  2. README.md — replace the guidance notes with real features and prerequisites"
echo "  3. docs/architecture.md — your system design"
echo "  4. docs/adr/ — copy ADR-001-template.md to record your first real decision"
echo "  5. docs/implementation-plan.md — filled later via the roadmap step (deferred tokens)"
echo "  6. src/ and tests/ — your source and tests"
echo "  7. .env.example — your project's environment variables"
echo ""
echo "  Then, in your first Claude Code session, say:"
echo -e "     ${BOLD}\"Run the entry protocol\"${RESET}"
echo ""
success "Repository '${VAL[PROJECT_NAME]}' is ready."
