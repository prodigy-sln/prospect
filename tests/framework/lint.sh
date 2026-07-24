#!/usr/bin/env bash
# Framework prompt lint: word budgets, forbidden references, frontmatter,
# and referenced-path existence for all prompt-surface files.
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
budget 700 .claude/skills/*/SKILL.md
budget 550 .claude/agents/*.md
budget 450 specs/_templates/spec.template.md specs/_templates/tasks.template.md specs/_templates/docs-index.template.md
budget 250 specs/_templates/spec-mini.template.md
budget 350 standards/global/scenario-guidelines.md
budget 350 standards/global/validation-calibration.md
budget 700 standards/global/code-quality.md standards/global/testing.md standards/global/git-workflow.md

# --- Total prompt surface ----------------------------------------------
TOTAL=0
for f in .claude/skills/*/SKILL.md .claude/agents/*.md specs/_templates/*.md \
         standards/global/*.md; do
  [ -f "$f" ] && TOTAL=$((TOTAL + $(words "$f")))
done
[ "$TOTAL" -le 10000 ] || err "total prompt surface: $TOTAL words (budget 10000)"
echo "total prompt surface: $TOTAL words"

# --- Forbidden references (removed tools/components, stale paths) -------
FORBIDDEN='TeamCreate|TeamDelete|sdd-test-writer|sdd-implementer|sdd-refactorer|sdd-verifier|sdd-start-issue|sdd-initiate|sdd-shape|sdd-specify|specs/implemented'
# --- Process-history phrases (prompts must be final-state) --------------
HISTORY='previously|no longer|changed from|used to be|instead of the old|replaces the'

for f in .claude/skills/*/SKILL.md .claude/agents/*.md .claude/workflows/*.js \
         specs/_templates/*.md standards/global/*.md product/*.template.md \
         CLAUDE.md README.md; do
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
for f in .claude/skills/*/SKILL.md .claude/agents/*.md CLAUDE.md; do
  [ -f "$f" ] || continue
  for ref in $(grep -oE '(standards/global|specs/_templates)/[A-Za-z0-9._-]+\.md' "$f" | sort -u); do
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
