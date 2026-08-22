#!/usr/bin/env bash
# Framework prompt lint: word budgets, forbidden references, frontmatter,
# referenced-path existence, and per-phase composed prompt budgets.
set -u
cd "$(dirname "$0")/../.."

FAIL=0
err() { echo "LINT FAIL: $*"; FAIL=1; }

words() { wc -w <"$1" | tr -d ' '; }

budget() { # budget <max> <file...>
  local max=$1; shift
  for f in "$@"; do
    [ -f "$f" ] || continue
    local w; w=$(words "$f")
    [ "$w" -le "$max" ] || err "$f: $w words (budget $max)"
  done
}

# --- Word budgets per file class ---------------------------------------
budget 950 .claude/skills/*/SKILL.md
budget 900 .claude/agents/*.md
budget 300 .prospect/prompts/*/*.md
budget 500 .prospect/templates/spec.template.md .prospect/templates/tasks.template.md \
           .prospect/templates/docs-index.template.md .prospect/templates/decision.template.md \
           .prospect/templates/fix.template.md
budget 250 .prospect/templates/spec-mini.template.md
budget 400 standards/global/scenario-guidelines.md
budget 400 standards/global/validation-calibration.md
budget 800 standards/global/testing.md standards/global/git-workflow.md
budget 1000 standards/global/code-quality.md standards/global/architecture-principles.md

# --- Composed prompt budget per matrix row -----------------------------
# Every resolved phase prompt (its fragment list summed) stays under 1100
# words — the per-invocation surface, which is what a phase actually pays.
while IFS=$'\t' read -r wtype rigors phase fragments; do
  case "$wtype" in \#*|'') continue ;; esac
  total=0
  IFS=',' read -ra FR <<< "$fragments"
  for frag in "${FR[@]}"; do
    f=".prospect/prompts/$frag"
    if [ ! -f "$f" ]; then
      err "matrix $wtype/$rigors/$phase references missing fragment: $frag"
      continue
    fi
    total=$((total + $(words "$f")))
  done
  [ "$total" -le 1100 ] || err "matrix $wtype/$rigors/$phase composes to $total words (budget 1100)"
done < .prospect/prompts/matrix.tsv

# --- Total prompt surface ----------------------------------------------
TOTAL=0
for f in .claude/skills/*/SKILL.md .claude/agents/*.md .prospect/prompts/*/*.md \
         .prospect/templates/*.md standards/global/*.md; do
  [ -f "$f" ] && TOTAL=$((TOTAL + $(words "$f")))
done
[ "$TOTAL" -le 14500 ] || err "total prompt surface: $TOTAL words (budget 14500)"
echo "total prompt surface: $TOTAL words"

# --- Forbidden references (removed tools/components, stale paths) -------
FORBIDDEN='TeamCreate|TeamDelete|sdd-test-writer|sdd-implementer|sdd-refactorer|sdd-verifier|sdd-start-issue|sdd-initiate|sdd-shape|sdd-specify|specs/implemented|specs/_templates'
# --- Process-history phrases (prompts must be final-state) --------------
HISTORY='previously|no longer|changed from|used to be|instead of the old|replaces the'

for f in .claude/skills/*/SKILL.md .claude/agents/*.md .claude/workflows/*.js \
         .prospect/prompts/*/*.md .prospect/templates/*.md .prospect/autonomy.md \
         standards/global/*.md product/*.template.md CLAUDE.md README.md; do
  [ -f "$f" ] || continue
  if grep -nEw "$FORBIDDEN" "$f" >/dev/null 2>&1; then
    err "$f references a removed component or stale path:"
    grep -nEw "$FORBIDDEN" "$f" | head -5
  fi
  if grep -inE "\b($HISTORY)\b" "$f" >/dev/null 2>&1; then
    err "$f contains process-history phrasing:"
    grep -inE "\b($HISTORY)\b" "$f" | head -5
  fi
done

# --- Frontmatter: every skill and agent declares name + description ------
for f in .claude/skills/*/SKILL.md .claude/agents/*.md; do
  [ -f "$f" ] || continue
  head -1 "$f" | tr -d '\r' | grep -q '^---$' || err "$f: missing frontmatter"
  grep -q '^name:' "$f" || err "$f: missing 'name:' in frontmatter"
  grep -q '^description:' "$f" || err "$f: missing 'description:' in frontmatter"
done

# --- Referenced framework paths must exist -------------------------------
for f in .claude/skills/*/SKILL.md .claude/agents/*.md .prospect/prompts/*/*.md CLAUDE.md; do
  [ -f "$f" ] || continue
  for ref in $(grep -oE '(standards/global|\.prospect/templates|\.prospect/scripts|\.prospect/prompts)/[A-Za-z0-9._-]+\.(md|sh|tsv)' "$f" | sort -u); do
    # ui-design.md and gate scripts are generated per project
    case "$ref" in *ui-design.md) continue ;; esac
    [ -f "$ref" ] || err "$f references missing file: $ref"
  done
done

if [ "$FAIL" -eq 0 ]; then
  echo "framework lint: PASS"
else
  echo "framework lint: FAIL"
  exit 1
fi
