#!/usr/bin/env bash
# sdd-next.sh — Prospect pipeline resolver.
# Reads a spec folder's frontmatter and on-disk state, resolves the next
# phase, and emits the composed prompt for that phase from fragment files.
# The LLM never branches on work-type or rigor; this script does.
#
# Usage: sdd-next.sh [folder-name] [--phase <name>] [--explain] [--auto]
# An open entry in the folder's reopen.md (see sdd-reopen.sh) runs before
# the disk-state probes.
# Exit codes: 0 resolved · 2 folder ambiguity/missing · 3 unknown type/cell
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROMPTS="$ROOT/.prospect/prompts"
MATRIX="$PROMPTS/matrix.tsv"
ACTIVE="$ROOT/specs/active"

folder=""
phase_override=""
explain=0
auto=0

while [ $# -gt 0 ]; do
  case "$1" in
    --phase)
      [ $# -ge 2 ] || { echo "--phase requires a phase name" >&2; exit 2; }
      phase_override="$2"; shift 2 ;;
    --explain) explain=1; shift ;;
    --auto) auto=1; shift ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) folder="$1"; shift ;;
  esac
done

# ── Locate the spec folder ────────────────────────────────────────────────
candidates=()
if [ -d "$ACTIVE" ]; then
  for d in "$ACTIVE"/*/; do
    [ -d "$d" ] || continue
    candidates+=("$(basename "$d")")
  done
fi

if [ -z "$folder" ]; then
  if [ ${#candidates[@]} -eq 0 ]; then
    echo "no active spec folder — run /sdd-start" >&2
    exit 2
  elif [ ${#candidates[@]} -gt 1 ]; then
    echo "multiple active spec folders — name one explicitly:" >&2
    printf '  %s\n' "${candidates[@]}" >&2
    exit 2
  fi
  folder="${candidates[0]}"
fi

DIR="$ACTIVE/$folder"
SPEC="$DIR/spec.md"
if [ ! -f "$SPEC" ]; then
  echo "$DIR has no spec.md — run /sdd-start" >&2
  exit 2
fi

# ── Frontmatter ───────────────────────────────────────────────────────────
fm() { # fm <key> — first frontmatter value for key
  awk -v k="$1" -F': *' 'NR>1 && /^---[[:space:]]*$/{exit} $1==k{print $2; exit}' "$SPEC" | tr -d '\r'
}

wtype="$(fm 'work-type')"; wtype="${wtype:-feature}"
rigor="$(fm 'rigor')"; rigor="${rigor:-medium}"
approved="$(fm 'approved')"

case "$wtype" in
  feature|decision|fix|docs|chore) ;;
  *) echo "unknown work-type: $wtype" >&2; exit 3 ;;
esac

# Rigor selects the phase bucket and the spec's scenario budget. The
# ceiling rises with rigor because more scenarios mean more surface to
# verify, and the higher tiers already pay for that verification.
case "$rigor" in
  low) bucket=low; scenario_budget=15 ;;
  medium) bucket=medium; scenario_budget=40 ;;
  high) bucket=high; scenario_budget=70 ;;
  xhigh) bucket=high; scenario_budget=110 ;;
  max) bucket=high; scenario_budget=160 ;;
  *) echo "unknown rigor: $rigor" >&2; exit 3 ;;
esac

# ── State probes ──────────────────────────────────────────────────────────
has_file() { [ -f "$DIR/$1" ]; }

has_unchecked_tasks() { grep -q '^- \[ \]' "$DIR/tasks.md" 2>/dev/null; }

# PASS must be the verdict's own value, not merely a word on the line.
validation_pass() { grep -qiE 'verdict:[^A-Za-z]*(\*\*)?PASS|^\*\*PASS' "$DIR/validation-report.md" 2>/dev/null; }

has_section_content() { # has_section_content <file> <heading> — section exists, non-empty, not "none"
  awk -v h="$2" '
    $0 ~ "^## "h { inside=1; next }
    inside && /^## / { exit }
    inside && NF { body = body $0 " " }
    END {
      gsub(/^[ \t]+|[ \t]+$/, "", body)
      if (length(body) > 0 && tolower(body) != "none") exit 0
      exit 1
    }' "$DIR/$1" 2>/dev/null
}

has_discussion() { grep -q '^## Discussion Findings' "$DIR/$1" 2>/dev/null; }

# A completion heading stamped into spec.md: bare, or followed by a
# separator or date ("## Validation — 2026-01-03") — never a longer title
# ("## Done criteria"). sdd-reopen matches the same pattern and marks the
# heading "(stale R<n>)", which no longer counts.
has_stamp() {
  grep -E "^## $1([[:space:]]*\$|[[:space:]]+(—|–|-|:|\(|[0-9]))" "$SPEC" | grep -qv '(stale '
}

# ── Phase detection ───────────────────────────────────────────────────────
# Precedence: --phase override, then the first open reopen-ledger entry,
# then the disk-state probes.
phase=""
reopen_entry="$(grep -m1 '^- \[open\] ' "$DIR/reopen.md" 2>/dev/null | tr -d '\r')"
if [ -n "$phase_override" ]; then
  phase="$phase_override"
  reopen_entry=""
elif [ -n "$reopen_entry" ]; then
  phase="$(printf '%s' "$reopen_entry" | sed -n 's/^- \[open\] R[0-9]* · phase: \([^ ]*\) · .*/\1/p')"
  [ -n "$phase" ] || { echo "malformed reopen entry: $reopen_entry" >&2; exit 3; }
else
  case "$wtype" in
    feature)
      if [ -z "$approved" ]; then phase=specify
      elif [ "$bucket" = high ] && has_section_content spec.md "Architecture Delta" && ! has_file architecture.md; then phase=architect
      elif { [ "$rigor" = xhigh ] || [ "$rigor" = max ]; } && has_file architecture.md && ! has_discussion architecture.md; then phase=discuss
      elif [ "$rigor" = low ]; then
        if has_stamp Validation; then phase=complete; else phase=implement; fi
      elif ! has_file tasks.md; then phase=tasks
      elif has_unchecked_tasks; then phase=implement
      elif validation_pass; then phase=complete
      else phase=validate
      fi
      ;;
    decision)
      if [ -z "$approved" ]; then phase=specify
      elif [ "$bucket" != low ] && ! has_discussion spec.md; then phase=discuss
      elif ! has_file decision-record.md; then phase=decide
      # Enforcement checks are the only tested deliverable; implement-checks
      # writes tasks.md, so a missing file means that phase has not run.
      elif has_section_content spec.md "Enforcement Checks" \
           && { ! has_file tasks.md || has_unchecked_tasks; }; then phase=implement
      elif validation_pass; then phase=complete
      else phase=validate
      fi
      ;;
    fix)
      # test-map.md is the fix path's "implement has run" probe: the implement
      # fragment writes it with the regression mapping before any code changes.
      if [ -z "$approved" ]; then phase=specify
      elif validation_pass; then phase=complete
      elif [ "$rigor" = low ]; then
        # Only the low path closes itself by stamping the spec; at medium+
        # the validate phase owns the verdict.
        if has_stamp Validation; then phase=complete; else phase=implement; fi
      elif ! has_file test-map.md; then phase=implement
      else phase=validate
      fi
      ;;
    docs)
      if validation_pass || has_stamp Published; then phase=complete; else phase=edit; fi
      ;;
    chore)
      if has_stamp Done; then phase=complete; else phase=work; fi
      ;;
  esac
fi

# ── Compose ───────────────────────────────────────────────────────────────
# Matrix rows carry an exact pipe-set of rigors (e.g. "high|xhigh|max").
fragments="$(tr -d '\r' < "$MATRIX" | awk -F'\t' -v t="$wtype" -v r="$rigor" -v p="$phase" '
  $1==t && $3==p {
    n = split($2, rs, "|")
    for (i = 1; i <= n; i++) if (rs[i] == r) { print $4; exit }
  }')"

if [ -z "$fragments" ]; then
  echo "no matrix entry for $wtype/$rigor/$phase" >&2
  exit 3
fi

# The completion handoff depends on the review mode: env
# PROSPECT_REVIEW_MODE, else the CLAUDE.md setting
# `review-mode: solo | team | harness`; default team.
if [ "$phase" = "complete" ]; then
  review_mode="${PROSPECT_REVIEW_MODE:-}"
  if [ -z "$review_mode" ]; then
    review_mode="$(grep -oE 'review-mode: *(solo|team|harness)' "$ROOT/CLAUDE.md" 2>/dev/null | head -1 | sed 's/.*: *//')"
  fi
  review_mode="${review_mode:-team}"
  case "$review_mode" in
    solo|team|harness) ;;
    *) echo "unknown review mode: $review_mode" >&2; exit 3 ;;
  esac
  fragments="$fragments,shared/complete-$review_mode.md"
fi

# A reopened phase amends its artifacts instead of writing them fresh.
if [ -n "$reopen_entry" ]; then
  fragments="$fragments,shared/reopen.md"
fi

# Unattended operation appends the autonomy addendum. PROSPECT_AUTONOMY
# names an alternative policy file (e.g. .prospect/autonomy-harness.md);
# a relative path is relative to the repo root, as the prompt reads it.
autonomy_policy=".prospect/autonomy.md"
if [ "$auto" -eq 1 ]; then
  if [ -n "${PROSPECT_AUTONOMY:-}" ]; then
    case "$PROSPECT_AUTONOMY" in
      /*|[A-Za-z]:[\\/]*) policy_file="$PROSPECT_AUTONOMY" ;;
      *) policy_file="$ROOT/$PROSPECT_AUTONOMY" ;;
    esac
    if [ ! -f "$policy_file" ] || [ ! -r "$policy_file" ]; then
      echo "PROSPECT_AUTONOMY is not a readable file: $PROSPECT_AUTONOMY" >&2
      exit 2
    fi
    autonomy_policy="$PROSPECT_AUTONOMY"
  fi
  fragments="$fragments,shared/autonomy.md"
fi

echo "PROSPECT NEXT"
echo "folder: specs/active/$folder"
echo "work-type: $wtype"
echo "rigor: $rigor"
echo "phase: $phase"

if [ "$explain" -eq 1 ]; then
  echo "approved: ${approved:-no}"
  echo "scenario-budget: $scenario_budget"
  echo "fragments: $fragments"
  [ -n "$reopen_entry" ] && echo "reopen: $reopen_entry"
  [ "$auto" -eq 1 ] && echo "autonomy: $autonomy_policy"
  exit 0
fi

# sed replacement text: escape the delimiter, backslash, and ampersand.
sed_esc() { printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'; }
reopen_sub="$(sed_esc "$reopen_entry")"
autonomy_sub="$(sed_esc "$autonomy_policy")"

echo "--- PROMPT ---"
IFS=',' read -ra FRAGS <<< "$fragments"
for frag in "${FRAGS[@]}"; do
  f="$PROMPTS/$frag"
  if [ ! -f "$f" ]; then
    echo "missing fragment: $frag" >&2
    exit 3
  fi
  sed -e "s|\${FOLDER}|specs/active/$folder|g" \
      -e "s|\${NAME}|$folder|g" \
      -e "s|\${RIGOR}|$rigor|g" \
      -e "s|\${SCENARIO_BUDGET}|$scenario_budget|g" \
      -e "s|\${WORK_TYPE}|$wtype|g" \
      -e "s|\${REOPEN}|$reopen_sub|g" \
      -e "s|\${AUTONOMY}|$autonomy_sub|g" "$f"
  echo ""
done

# ── Telemetry stamp ───────────────────────────────────────────────────────
METRICS="$DIR/metrics.md"
if [ ! -f "$METRICS" ]; then
  {
    echo "# Metrics: $folder"
    echo ""
    echo "| timestamp (UTC) | phase |"
    echo "|---|---|"
  } > "$METRICS"
fi
echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | $phase |" >> "$METRICS"

exit 0
