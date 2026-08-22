#!/usr/bin/env bash
# sdd-artifact-lint.sh — deterministic caps for generated spec artifacts.
# Called by project gates and by phases; exits non-zero with a compact
# failure list when an artifact exceeds its budget.
#
# Usage: sdd-artifact-lint.sh <spec-folder>   (e.g. specs/active/2026-...-name)
set -u

DIR="${1:-}"
[ -d "$DIR" ] || { echo "usage: sdd-artifact-lint.sh <spec-folder>" >&2; exit 2; }

FAIL=0
err() { echo "ARTIFACT LINT: $*"; FAIL=1; }

lines() { wc -l <"$1" | tr -d ' '; }

# tasks.md: 60 lines
if [ -f "$DIR/tasks.md" ]; then
  n=$(lines "$DIR/tasks.md")
  [ "$n" -le 60 ] || err "tasks.md: $n lines (budget 60) — move rationale to the spec, lessons to docs/"
fi

# test-map.md: header + one line per mapping; no prose blocks (cap: 3 lines
# per mapped test, measured as total lines vs mapping lines)
if [ -f "$DIR/test-map.md" ]; then
  total=$(lines "$DIR/test-map.md")
  maps=$(grep -c '→\|->' "$DIR/test-map.md" 2>/dev/null || echo 0)
  budget=$((maps * 3 + 10))
  [ "$total" -le "$budget" ] || err "test-map.md: $total lines for $maps mappings (budget $budget) — one line per mapping"
fi

# validation-report.md: 120 lines
if [ -f "$DIR/validation-report.md" ]; then
  n=$(lines "$DIR/validation-report.md")
  [ "$n" -le 120 ] || err "validation-report.md: $n lines (budget 120)"
fi

# requirements.md: 150 lines
if [ -f "$DIR/requirements.md" ]; then
  n=$(lines "$DIR/requirements.md")
  [ "$n" -le 150 ] || err "requirements.md: $n lines (budget 150)"
fi

# REGISTRY.md: every entry line ≤ 50 words
REG="$(dirname "$(dirname "$DIR")")/REGISTRY.md"
if [ -f "$REG" ]; then
  while IFS= read -r line; do
    w=$(echo "$line" | wc -w | tr -d ' ')
    [ "$w" -le 50 ] || err "REGISTRY.md entry exceeds 50 words ($w): ${line:0:60}…"
  done < <(grep -E '^[-\`]' "$REG" | grep '·')
fi

if [ "$FAIL" -eq 0 ]; then
  echo "artifact lint: PASS"
else
  exit 1
fi
