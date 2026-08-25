#!/usr/bin/env bash
# sdd-next.sh — Prospect pipeline resolver.
# Reads a spec folder's frontmatter and on-disk state, resolves the next
# phase, and emits the composed prompt for that phase from fragment files.
# The LLM never branches on work-type or rigor; this script does.
#
# Usage: sdd-next.sh [folder-name] [--phase <name>] [--explain]
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
    --phase) phase_override="${2:-}"; shift 2 ;;
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

case "$rigor" in
  low) bucket=low ;;
  medium) bucket=medium ;;
  high|xhigh|max) bucket=high ;;
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

# ── Phase detection ───────────────────────────────────────────────────────
phase=""
if [ -n "$phase_override" ]; then
  phase="$phase_override"
else
  case "$wtype" in
    feature)
      if [ -z "$approved" ]; then phase=specify
      elif [ "$bucket" = high ] && has_section_content spec.md "Architecture Delta" && ! has_file architecture.md; then phase=architect
      elif { [ "$rigor" = xhigh ] || [ "$rigor" = max ]; } && has_file architecture.md && ! has_discussion architecture.md; then phase=discuss
      elif [ "$rigor" = low ]; then
        if grep -q '^## Validation' "$SPEC"; then phase=complete; else phase=implement; fi
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
      elif has_unchecked_tasks; then phase=implement
      elif validation_pass; then phase=complete
      else phase=validate
      fi
      ;;
    fix)
      # test-map.md is the fix path's "implement has run" probe: the implement
      # fragment writes it with the regression mapping before any code changes.
      if [ -z "$approved" ]; then phase=specify
      elif validation_pass || grep -q '^## Validation' "$SPEC"; then phase=complete
      elif [ "$rigor" = low ]; then phase=implement
      elif ! has_file test-map.md; then phase=implement
      else phase=validate
      fi
      ;;
    docs)
      if validation_pass || grep -q '^## Published' "$SPEC"; then phase=complete; else phase=edit; fi
      ;;
    chore)
      if grep -q '^## Done' "$SPEC"; then phase=complete; else phase=work; fi
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

# The completion handoff depends on the project's review mode (CLAUDE.md
# setting `review-mode: solo | team`; default team).
if [ "$phase" = "complete" ]; then
  review_mode="$(grep -oE 'review-mode: *(solo|team)' "$ROOT/CLAUDE.md" 2>/dev/null | head -1 | sed 's/.*: *//')"
  review_mode="${review_mode:-team}"
  fragments="$fragments,shared/complete-$review_mode.md"
fi

# Unattended operation appends the autonomy addendum.
if [ "$auto" -eq 1 ]; then
  fragments="$fragments,shared/autonomy.md"
fi

echo "PROSPECT NEXT"
echo "folder: specs/active/$folder"
echo "work-type: $wtype"
echo "rigor: $rigor"
echo "phase: $phase"

if [ "$explain" -eq 1 ]; then
  echo "approved: ${approved:-no}"
  echo "fragments: $fragments"
  exit 0
fi

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
      -e "s|\${WORK_TYPE}|$wtype|g" "$f"
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
