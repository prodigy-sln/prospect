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

# awk counts a final line that carries no newline; wc -l would not.
lines() { awk 'END { print NR }' "$1"; }

# tasks.md: 60 lines
if [ -f "$DIR/tasks.md" ]; then
  n=$(lines "$DIR/tasks.md")
  [ "$n" -le 60 ] || err "tasks.md: $n lines (budget 60) — move rationale to the spec, lessons to docs/"
fi

# test-map.md: header + one line per mapping; no prose blocks (cap: 3 lines
# per mapped test, measured as total lines vs mapping lines)
if [ -f "$DIR/test-map.md" ]; then
  total=$(lines "$DIR/test-map.md")
  # grep -c already prints 0 on no match; the || only restores its exit code.
  maps=$(grep -cE '→|->' "$DIR/test-map.md") || maps=0
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

# find_registry <spec-folder> — the repo's specs/REGISTRY.md, located by
# walking up. Archived folders sit one level deeper than active ones, and
# the caller's working directory is not guaranteed to be the repo root.
find_registry() {
  local dir parent
  dir="$(cd "$1" && pwd)" || return 1
  while [ -n "$dir" ]; do
    [ -f "$dir/specs/REGISTRY.md" ] && { printf '%s\n' "$dir/specs/REGISTRY.md"; return 0; }
    parent="$(dirname "$dir")"
    [ "$parent" = "$dir" ] && return 1
    dir="$parent"
  done
  return 1
}

# REGISTRY.md: this spec's own entry ≤ 50 words. Entries are the lines
# carrying the '·' separator. Only the ones naming this spec are judged —
# the registry is append-only history, and a per-spec lint that failed on
# records written by earlier specs would be red for a reason the spec being
# completed cannot repair.
SPEC_NAME="$(basename "$DIR")"
REG="$(find_registry "$DIR")" || REG=""
if [ -n "$REG" ]; then
  while IFS= read -r line; do
    w=$(wc -w <<<"$line" | tr -d ' ')
    [ "$w" -le 50 ] || err "REGISTRY.md entry for $SPEC_NAME exceeds 50 words ($w)"
  done < <(grep -F '·' "$REG" | grep -F "$SPEC_NAME")
fi

if [ "$FAIL" -eq 0 ]; then
  echo "artifact lint: PASS"
else
  exit 1
fi
