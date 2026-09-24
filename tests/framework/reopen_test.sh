#!/usr/bin/env bash
# Tests for .prospect/scripts/sdd-reopen.sh — scoped phase reopening.
# Each test builds a disposable repo copy with a synthetic spec folder and
# asserts the ledger, the partial invalidation, and the exit codes.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
TESTS=0
F=2026-01-01-aa

t() { TESTS=$((TESTS + 1)); echo "  · $1"; }
err() { echo "    FAIL: $1"; FAIL=1; }

make_repo() {
  local dir
  dir="$(mktemp -d)"
  cp -r "$REPO_ROOT/.prospect" "$dir/.prospect"
  mkdir -p "$dir/specs/active"
  echo "$dir"
}

# make_spec <repo> <work-type> <rigor> — approved spec in folder $F
make_spec() {
  mkdir -p "$1/specs/active/$F"
  printf -- '---\nid: SPEC-T\nwork-type: %s\nrigor: %s\napproved: 2026-01-02\n---\n\n# Spec\n' \
    "$2" "$3" > "$1/specs/active/$F/spec.md"
}

# seed_tasks <repo> — three tasks, two ticked, with scenario lines
seed_tasks() {
  cat > "$1/specs/active/$F/tasks.md" <<'EOF'
# Tasks

## Phase 1: Core

- [x] T01 [P] first — src/a
      Scenarios: FR-1.1-S1, FR-1.1-S2
- [x] T02 second — src/b
      Scenarios: FR-1.2-S1
      Depends on: T01
- [x] T03 third — src/c
      Scenarios: FR-1.3-S1
EOF
}

reopen() { # reopen <repo> [args...]
  local repo="$1"; shift
  (cd "$repo" && bash .prospect/scripts/sdd-reopen.sh "$@" 2>&1)
}

phases() { grep -oE 'phase: [a-z]+' "$1/specs/active/$F/reopen.md" | sed 's/phase: //' | tr '\n' ' '; }

# ── usage and guards ─────────────────────────────────────────────────────

t "a missing spec folder exits 2"
R="$(make_repo)"
reopen "$R" nope specify --reason x >/dev/null
[ $? -eq 2 ] || err "expected exit 2 for a missing folder"

t "a missing reason exits 2"
R="$(make_repo)"; make_spec "$R" feature medium
reopen "$R" "$F" specify >/dev/null
[ $? -eq 2 ] || err "expected exit 2 without --reason"

t "a phase without a matrix cell for the spec exits 3 and writes nothing"
R="$(make_repo)"; make_spec "$R" feature low
reopen "$R" "$F" tasks --reason x >/dev/null
[ $? -eq 3 ] || err "feature/low/tasks has no cell, expected exit 3"
[ -f "$R/specs/active/$F/reopen.md" ] && err "ledger written despite exit 3"
R="$(make_repo)"; make_spec "$R" fix medium
reopen "$R" "$F" architect --reason x >/dev/null
[ $? -eq 3 ] || err "fix has no architect phase, expected exit 3"

# ── ledger ───────────────────────────────────────────────────────────────

t "reopening specify enqueues the downstream stages that own artifacts, in order"
R="$(make_repo)"; make_spec "$R" feature high; seed_tasks "$R"
echo '# Architecture' > "$R/specs/active/$F/architecture.md"
OUT="$(reopen "$R" "$F" specify --scope FR-1.2-S1 --reason "missing edge case")"; RC=$?
[ $RC -eq 0 ] || err "expected exit 0, got $RC: $OUT"
[ "$(phases "$R")" = "specify architect tasks " ] || err "stages: $(phases "$R")"
grep -q '^- \[open\] R1 · phase: specify · scope: FR-1.2-S1 · reason: missing edge case · at: 20' \
  "$R/specs/active/$F/reopen.md" || err "entry format: $(cat "$R/specs/active/$F/reopen.md")"
grep -q '^- \[open\] R3 · phase: tasks' "$R/specs/active/$F/reopen.md" || err "entries are not numbered per stage"

t "architect is not enqueued without architecture.md"
R="$(make_repo)"; make_spec "$R" feature medium; seed_tasks "$R"
reopen "$R" "$F" specify --reason x >/dev/null
[ "$(phases "$R")" = "specify tasks " ] || err "stages: $(phases "$R")"

t "decision specify enqueues decide; fix specify enqueues nothing more"
R="$(make_repo)"; make_spec "$R" decision medium
echo '# Decisions' > "$R/specs/active/$F/decision-record.md"
reopen "$R" "$F" specify --reason x >/dev/null
[ "$(phases "$R")" = "specify decide " ] || err "decision stages: $(phases "$R")"
R="$(make_repo)"; make_spec "$R" fix medium
echo 'S1 -> t' > "$R/specs/active/$F/test-map.md"
reopen "$R" "$F" specify --reason x >/dev/null
[ "$(phases "$R")" = "specify " ] || err "fix stages: $(phases "$R")"

t "numbering continues across calls"
R="$(make_repo)"; make_spec "$R" feature medium
reopen "$R" "$F" implement --reason one >/dev/null
sed -i 's/\[open\]/[closed]/' "$R/specs/active/$F/reopen.md"
reopen "$R" "$F" implement --reason two >/dev/null
grep -q '^- \[open\] R2 · phase: implement · scope: all · reason: two' "$R/specs/active/$F/reopen.md" \
  || err "second call: $(cat "$R/specs/active/$F/reopen.md")"

# ── partial invalidation ─────────────────────────────────────────────────

t "only tasks whose scenarios intersect the scope are unticked"
R="$(make_repo)"; make_spec "$R" feature medium; seed_tasks "$R"
reopen "$R" "$F" specify --scope FR-1.2-S1 --reason x >/dev/null
T="$R/specs/active/$F/tasks.md"
grep -q '^- \[ \] T02 second — src/b — reopened R1$' "$T" || err "T02 not unticked: $(cat "$T")"
grep -q '^- \[x\] T01' "$T" || err "T01 must stay ticked"
grep -q '^- \[x\] T03' "$T" || err "T03 must stay ticked"
grep -q 'Depends on: T01' "$T" || err "task text was lost"

t "a requirement id in the scope covers its scenarios"
R="$(make_repo)"; make_spec "$R" feature medium; seed_tasks "$R"
reopen "$R" "$F" tasks --scope FR-1.1 --reason x >/dev/null
grep -q '^- \[ \] T01' "$R/specs/active/$F/tasks.md" || err "FR-1.1 did not cover T01"
grep -q '^- \[x\] T02' "$R/specs/active/$F/tasks.md" || err "T02 must stay ticked"

t "a whole-phase implement reopen unticks every task"
R="$(make_repo)"; make_spec "$R" feature medium; seed_tasks "$R"
reopen "$R" "$F" implement --reason x >/dev/null
grep -q '^- \[x\]' "$R/specs/active/$F/tasks.md" && err "ticked task survived: $(cat "$R/specs/active/$F/tasks.md")"

t "a whole-phase specify reopen leaves tasks to the amending phase"
R="$(make_repo)"; make_spec "$R" feature medium; seed_tasks "$R"
reopen "$R" "$F" specify --reason x >/dev/null
[ "$(grep -c '^- \[x\]' "$R/specs/active/$F/tasks.md")" -eq 3 ] || err "tasks were unticked"

t "the validation report moves to history"
R="$(make_repo)"; make_spec "$R" feature medium; seed_tasks "$R"
echo 'Verdict: PASS' > "$R/specs/active/$F/validation-report.md"
reopen "$R" "$F" implement --scope FR-1.3-S1 --reason x >/dev/null
[ -f "$R/specs/active/$F/validation-report.md" ] && err "report still in place"
grep -q PASS "$R/specs/active/$F/history/validation-report.R1.md" 2>/dev/null || err "report not in history"

t "scoped test-map lines are marked stale, near-miss ids are not"
R="$(make_repo)"; make_spec "$R" feature medium
printf 'FR-1.2-S1 → does b\nFR-1.2-S10 -> does c\nFR-1.1-S1 -> does a\n' > "$R/specs/active/$F/test-map.md"
reopen "$R" "$F" implement --scope FR-1.2-S1 --reason x >/dev/null
M="$R/specs/active/$F/test-map.md"
grep -q '^FR-1.2-S1 → does b (stale R1)$' "$M" || err "scoped line not marked: $(cat "$M")"
grep -q 'S10 -> does c$' "$M" || err "FR-1.2-S10 marked stale"
grep -q 'S1 -> does a$' "$M" || err "FR-1.1-S1 marked stale"

t "approved stays and a low-rigor validation stamp goes stale"
R="$(make_repo)"; make_spec "$R" feature low
printf '\n## Validation\n\n2026-01-03 gate green\n' >> "$R/specs/active/$F/spec.md"
reopen "$R" "$F" implement --reason x >/dev/null
S="$R/specs/active/$F/spec.md"
grep -q '^approved: 2026-01-02' "$S" || err "approved: removed"
grep -q '^## Validation (stale R1)$' "$S" || err "stamp not marked stale: $(cat "$S")"
sed -i 's/\[open\]/[closed]/' "$R/specs/active/$F/reopen.md"
OUT="$(cd "$R" && bash .prospect/scripts/sdd-next.sh --explain)"
echo "$OUT" | grep -q '^phase: implement' || err "stale stamp still completes: $(echo "$OUT" | grep '^phase:')"

echo ""
if [ $FAIL -eq 0 ]; then
  echo "reopen tests: PASS ($TESTS tests)"
else
  echo "reopen tests: FAIL"
  exit 1
fi
