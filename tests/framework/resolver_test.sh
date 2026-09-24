#!/usr/bin/env bash
# Tests for .prospect/scripts/sdd-next.sh — the pipeline resolver.
# Each test builds a disposable repo copy with a synthetic spec folder and
# asserts the resolved phase, composed prompt, and side effects.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
TESTS=0

t() { TESTS=$((TESTS + 1)); echo "  · $1"; }
err() { echo "    FAIL: $1"; FAIL=1; }

# make_repo — fresh temp repo with the real .prospect tree copied in
make_repo() {
  local dir
  dir="$(mktemp -d)"
  cp -r "$REPO_ROOT/.prospect" "$dir/.prospect"
  mkdir -p "$dir/specs/active" "$dir/scripts"
  echo "$dir"
}

# make_spec <repo> <folder> <work-type> <rigor> [approved]
make_spec() {
  local repo="$1" folder="$2" wtype="$3" rigor="$4" approved="${5:-}"
  mkdir -p "$repo/specs/active/$folder"
  {
    echo '---'
    echo "id: SPEC-T"
    echo "title: Test"
    echo "status: active"
    echo "work-type: $wtype"
    echo "rigor: $rigor"
    [ -n "$approved" ] && echo "approved: $approved"
    echo '---'
    echo
    echo '# Specification: Test'
  } > "$repo/specs/active/$folder/spec.md"
}

resolve() { # resolve <repo> [args...]
  local repo="$1"; shift
  (cd "$repo" && bash .prospect/scripts/sdd-next.sh "$@" 2>&1)
}

# ── ambiguity / guard ────────────────────────────────────────────────────

t "no active folder exits 2"
R="$(make_repo)"
resolve "$R" >/dev/null 2>&1
[ $? -eq 2 ] || err "expected exit 2 with no active folder"

t "two active folders without an argument exits 2 and lists both"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium
make_spec "$R" 2026-01-02-bb feature medium
OUT="$(resolve "$R")"; RC=$?
[ $RC -eq 2 ] || err "expected exit 2, got $RC"
echo "$OUT" | grep -q "2026-01-01-aa" || err "missing folder aa in listing"
echo "$OUT" | grep -q "2026-01-02-bb" || err "missing folder bb in listing"

t "unknown work-type exits 3"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa gizmo medium
resolve "$R" >/dev/null 2>&1
[ $? -eq 3 ] || err "expected exit 3 for unknown work-type"

# ── feature phase detection ──────────────────────────────────────────────

t "feature: unapproved spec resolves to specify"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: specify" || err "expected specify, got: $(echo "$OUT" | grep '^phase:')"

t "feature medium: approved spec without tasks resolves to tasks"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: tasks" || err "expected tasks, got: $(echo "$OUT" | grep '^phase:')"

t "feature high: approved spec with non-empty architecture delta resolves to architect"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature high 2026-01-02
printf '\n## Architecture Delta\n\n- new port: PaymentPort\n' >> "$R/specs/active/2026-01-01-aa/spec.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: architect" || err "expected architect, got: $(echo "$OUT" | grep '^phase:')"

t "feature high: delta 'none' skips architect and resolves to tasks"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature high 2026-01-02
printf '\n## Architecture Delta\n\nnone\n' >> "$R/specs/active/2026-01-01-aa/spec.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: tasks" || err "expected tasks, got: $(echo "$OUT" | grep '^phase:')"

t "feature xhigh: architecture present, no discussion findings resolves to discuss"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature xhigh 2026-01-02
printf '\n## Architecture Delta\n\n- new port: P\n' >> "$R/specs/active/2026-01-01-aa/spec.md"
echo '# Architecture' > "$R/specs/active/2026-01-01-aa/architecture.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: discuss" || err "expected discuss, got: $(echo "$OUT" | grep '^phase:')"

t "feature: unchecked tasks resolve to implement with folder substituted in prompt"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
printf -- '- [ ] T01 do a thing\n' > "$R/specs/active/2026-01-01-aa/tasks.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: implement" || err "expected implement, got: $(echo "$OUT" | grep '^phase:')"
echo "$OUT" | grep -q "specs/active/2026-01-01-aa" || err "prompt does not substitute the folder path"

t "feature: all tasks checked, no validation report resolves to validate"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
printf -- '- [x] T01 done\n' > "$R/specs/active/2026-01-01-aa/tasks.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: validate" || err "expected validate, got: $(echo "$OUT" | grep '^phase:')"

t "feature: validation PASS resolves to complete"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
printf -- '- [x] T01 done\n' > "$R/specs/active/2026-01-01-aa/tasks.md"
printf 'Verdict: PASS\n' > "$R/specs/active/2026-01-01-aa/validation-report.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: complete" || err "expected complete, got: $(echo "$OUT" | grep '^phase:')"

t "feature: a bold verdict line resolves to complete"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
printf -- '- [x] T01 done
' > "$R/specs/active/2026-01-01-aa/tasks.md"
printf '**Verdict:** **PASS**
' > "$R/specs/active/2026-01-01-aa/validation-report.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: complete" || err "expected complete, got: $(echo "$OUT" | grep '^phase:')"

t "feature: a FAILED verdict that mentions PASS stays in validate"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
printf -- '- [x] T01 done
' > "$R/specs/active/2026-01-01-aa/tasks.md"
printf 'Verdict: FAILED - two Blockers; re-run to reach PASS
'   > "$R/specs/active/2026-01-01-aa/validation-report.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: validate" || err "a FAILED report resolved to: $(echo "$OUT" | grep '^phase:')"

# ── other work types ─────────────────────────────────────────────────────

t "fix: existing spec resolves straight to implement (no tasks phase)"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa fix medium 2026-01-02
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: implement" || err "expected implement, got: $(echo "$OUT" | grep '^phase:')"

t "fix: at medium+ a written test-map hands off to validate"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa fix high 2026-01-02
printf 'FR-1-S1 -> reproduces the defect
' > "$R/specs/active/2026-01-01-aa/test-map.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: validate" || err "fix stalled at: $(echo "$OUT" | grep '^phase:')"

t "fix: a failing validation report re-runs validate rather than implement"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa fix high 2026-01-02
printf 'FR-1-S1 -> reproduces the defect
' > "$R/specs/active/2026-01-01-aa/test-map.md"
printf 'Verdict: FAILED - one Blocker
' > "$R/specs/active/2026-01-01-aa/validation-report.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: validate" || err "expected validate, got: $(echo "$OUT" | grep '^phase:')"

t "fix: at rigor low implement still self-marks and completes"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa fix low 2026-01-02
printf 'FR-1-S1 -> reproduces the defect
' > "$R/specs/active/2026-01-01-aa/test-map.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: implement" || err "low should stay on implement, got: $(echo "$OUT" | grep '^phase:')"

t "docs: resolves to edit"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa docs low 2026-01-02
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: edit" || err "expected edit, got: $(echo "$OUT" | grep '^phase:')"

t "chore: resolves to work"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa chore low 2026-01-02
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: work" || err "expected work, got: $(echo "$OUT" | grep '^phase:')"

t "decision: approved spec without discussion resolves to discuss"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa decision xhigh 2026-01-02
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: discuss" || err "expected discuss, got: $(echo "$OUT" | grep '^phase:')"

# decision_ready <repo> <checks-body> — decided spec past its discussion
decision_ready() {
  make_spec "$1" 2026-01-01-aa decision medium 2026-01-02
  printf '\n## Enforcement Checks\n\n%s\n\n## Discussion Findings\n\n- agreed\n' "$2" \
    >> "$1/specs/active/2026-01-01-aa/spec.md"
  echo '# Decisions' > "$1/specs/active/2026-01-01-aa/decision-record.md"
}

t "decision: decided with enforcement checks and no tasks resolves to implement"
R="$(make_repo)"
decision_ready "$R" "- CHK-1-S1: WHEN a module imports infra THE SYSTEM SHALL fail"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: implement" || err "expected implement, got: $(echo "$OUT" | grep '^phase:')"
echo "$OUT" | grep -q "enforcement checks" || err "implement did not compose implement-checks"

t "decision: unchecked check tasks stay on implement"
R="$(make_repo)"
decision_ready "$R" "- CHK-1-S1: WHEN x THE SYSTEM SHALL y"
printf -- '- [x] T01 a\n- [ ] T02 b\n' > "$R/specs/active/2026-01-01-aa/tasks.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: implement" || err "expected implement, got: $(echo "$OUT" | grep '^phase:')"

t "decision: all check tasks ticked resolves to validate"
R="$(make_repo)"
decision_ready "$R" "- CHK-1-S1: WHEN x THE SYSTEM SHALL y"
printf -- '- [x] T01 check\n' > "$R/specs/active/2026-01-01-aa/tasks.md"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: validate" || err "expected validate, got: $(echo "$OUT" | grep '^phase:')"

t "decision: enforcement checks 'none' skips implement"
R="$(make_repo)"
decision_ready "$R" "none"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: validate" || err "expected validate, got: $(echo "$OUT" | grep '^phase:')"

# ── overrides and side effects ───────────────────────────────────────────

t "--phase override wins over detection"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
OUT="$(resolve "$R" 2026-01-01-aa --phase validate)"
echo "$OUT" | grep -q "^phase: validate" || err "override ignored: $(echo "$OUT" | grep '^phase:')"

t "resolution stamps a phase line into metrics.md"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
resolve "$R" >/dev/null
grep -q "tasks" "$R/specs/active/2026-01-01-aa/metrics.md" 2>/dev/null \
  || err "metrics.md missing or not stamped"

t "--explain prints state without stamping metrics"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
OUT="$(resolve "$R" 2026-01-01-aa --explain)"
echo "$OUT" | grep -qi "work-type: feature" || err "explain output missing work-type"
[ -f "$R/specs/active/2026-01-01-aa/metrics.md" ] && err "explain must not stamp metrics"

t "--auto appends the autonomy addendum to the composed prompt"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
OUT="$(resolve "$R" 2026-01-01-aa --auto)"
echo "$OUT" | grep -q "Unattended operation" || err "autonomy addendum missing under --auto"
OUT2="$(resolve "$R" 2026-01-01-aa)"
echo "$OUT2" | grep -q "Unattended operation" && err "autonomy addendum leaked without --auto"
echo "$OUT" | grep -q "policy in \`.prospect/autonomy.md\`" || err "default policy path not substituted"
echo "$OUT" | grep -q "^### STOP D<n>" || err "STOP shape missing from the addendum"

t "PROSPECT_AUTONOMY points the addendum at another policy file"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
OUT="$(PROSPECT_AUTONOMY=.prospect/autonomy-harness.md resolve "$R" 2026-01-01-aa --auto)"
echo "$OUT" | grep -q "policy in \`.prospect/autonomy-harness.md\`" || err "override path not substituted"
echo "$OUT" | grep -q 'AUTONOMY}' && err "autonomy placeholder survived"
OUT="$(PROSPECT_AUTONOMY=.prospect/autonomy-harness.md resolve "$R" 2026-01-01-aa --auto --explain)"
echo "$OUT" | grep -q "^autonomy: .prospect/autonomy-harness.md" || err "--explain omits the policy"

t "an unreadable PROSPECT_AUTONOMY exits 2 under --auto"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature medium 2026-01-02
PROSPECT_AUTONOMY=missing.md resolve "$R" 2026-01-01-aa --auto >/dev/null
[ $? -eq 2 ] || err "expected exit 2 for a missing policy file"

# ── review mode ──────────────────────────────────────────────────────────

# complete_repo <review-mode-line> — feature spec ready to complete
complete_repo() {
  local r; r="$(make_repo)"
  make_spec "$r" 2026-01-01-aa feature medium 2026-01-02
  printf -- '- [x] T01 done\n' > "$r/specs/active/2026-01-01-aa/tasks.md"
  printf 'Verdict: PASS\n' > "$r/specs/active/2026-01-01-aa/validation-report.md"
  [ -n "$1" ] && printf -- '- %s\n' "$1" > "$r/CLAUDE.md"
  echo "$r"
}

t "complete defaults to the team review mode"
R="$(complete_repo "")"
OUT="$(resolve "$R" 2026-01-01-aa --explain)"
echo "$OUT" | grep -q "shared/complete-team.md" || err "expected team: $(echo "$OUT" | grep '^fragments:')"

t "review-mode: harness in CLAUDE.md selects the harness handoff"
R="$(complete_repo '`review-mode: harness`')"
OUT="$(resolve "$R" 2026-01-01-aa)"
echo "$OUT" | grep -q "^## Review mode: harness" || err "harness fragment not composed"

t "PROSPECT_REVIEW_MODE wins over CLAUDE.md"
R="$(complete_repo '`review-mode: solo`')"
OUT="$(PROSPECT_REVIEW_MODE=harness resolve "$R" 2026-01-01-aa --explain)"
echo "$OUT" | grep -q "shared/complete-harness.md" || err "env ignored: $(echo "$OUT" | grep '^fragments:')"
echo "$OUT" | grep -q "complete-solo" && err "CLAUDE.md setting leaked past the env"
PROSPECT_REVIEW_MODE=bogus resolve "$R" 2026-01-01-aa --explain >/dev/null
[ $? -eq 3 ] || err "an unknown review mode must exit 3"

# ── reopen ledger ────────────────────────────────────────────────────────

# reopened_repo — tasks pending, specify reopened (closed R1, open R2 + R3)
reopened_repo() {
  local r; r="$(make_repo)"
  make_spec "$r" 2026-01-01-aa feature medium 2026-01-02
  printf -- '- [ ] T01 a — reopened R2\n      Scenarios: FR-1.1-S1\n' > "$r/specs/active/2026-01-01-aa/tasks.md"
  cat > "$r/specs/active/2026-01-01-aa/reopen.md" <<'EOF'
# Reopen Ledger

- [closed] R1 · phase: implement · scope: all · reason: old · at: 2026-01-01T00:00:00Z
- [open] R2 · phase: specify · scope: FR-1.1-S1 · reason: a|b & c · at: 2026-01-02T00:00:00Z
- [open] R3 · phase: tasks · scope: FR-1.1-S1 · reason: a|b & c · at: 2026-01-02T00:00:00Z
EOF
  echo "$r"
}

t "the first open reopen entry wins over the disk-state probes"
R="$(reopened_repo)"
OUT="$(resolve "$R")"
echo "$OUT" | grep -q "^phase: specify" || err "expected specify, got: $(echo "$OUT" | grep '^phase:')"
echo "$OUT" | grep -q "^## Reopened phase" || err "reopen fragment not appended"
echo "$OUT" | grep -qF -- '- [open] R2 · phase: specify · scope: FR-1.1-S1 · reason: a|b & c' \
  || err "entry not substituted verbatim"
echo "$OUT" | grep -q 'REOPEN}' && err "reopen placeholder survived"
OUT="$(resolve "$R" 2026-01-01-aa --explain)"
echo "$OUT" | grep -q "^reopen: - \[open\] R2" || err "--explain omits the reopen entry"

t "later open entries run once earlier ones close, then the probes resume"
R="$(reopened_repo)"
sed -i 's/\[open\] R2/[closed] R2/' "$R/specs/active/2026-01-01-aa/reopen.md"
OUT="$(resolve "$R" 2026-01-01-aa --explain)"
echo "$OUT" | grep -q "^phase: tasks" || err "expected tasks, got: $(echo "$OUT" | grep '^phase:')"
sed -i 's/\[open\] R3/[closed] R3/' "$R/specs/active/2026-01-01-aa/reopen.md"
OUT="$(resolve "$R" 2026-01-01-aa --explain)"
echo "$OUT" | grep -q "^phase: implement" || err "expected implement, got: $(echo "$OUT" | grep '^phase:')"
echo "$OUT" | grep -q "reopen" && err "closed ledger still composes the reopen fragment"

t "--phase override wins over the reopen ledger"
R="$(reopened_repo)"
OUT="$(resolve "$R" 2026-01-01-aa --phase validate --explain)"
echo "$OUT" | grep -q "^phase: validate" || err "override ignored: $(echo "$OUT" | grep '^phase:')"
echo "$OUT" | grep -q "shared/reopen.md" && err "override still composes the reopen fragment"

t "a reopen entry for a phase without a matrix cell exits 3"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature low 2026-01-02
printf -- '- [open] R1 · phase: tasks · scope: all · reason: x · at: 2026-01-01T00:00:00Z\n' \
  > "$R/specs/active/2026-01-01-aa/reopen.md"
resolve "$R" >/dev/null
[ $? -eq 3 ] || err "expected exit 3"

# ── scenario budget ───────────────────────────────────────────────────────

t "the specify prompt carries the rigor tier's scenario budget"
for pair in low:15 medium:40 high:70 xhigh:110 max:160; do
  rg="${pair%%:*}"; want="${pair##*:}"
  R="$(make_repo)"
  make_spec "$R" 2026-01-01-aa feature "$rg"
  OUT="$(resolve "$R" 2026-01-01-aa)"
  echo "$OUT" | grep -qE "Scenario budget[^0-9]*$want" \
    || err "$rg: specify prompt does not carry budget $want"
done

t "no resolved prompt leaks an unsubstituted scenario-budget placeholder"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature high
OUT="$(resolve "$R" 2026-01-01-aa)"
echo "$OUT" | grep -q "SCENARIO_BUDGET" && err "the placeholder survived substitution"

t "--explain reports the resolved scenario budget"
R="$(make_repo)"
make_spec "$R" 2026-01-01-aa feature xhigh
OUT="$(resolve "$R" 2026-01-01-aa --explain)"
echo "$OUT" | grep -q "scenario-budget: 110" || err "--explain omits the budget: $OUT"

t "every matrix row references only fragment files that exist"
while IFS=$'\t' read -r wtype bucket phase fragments; do
  case "$wtype" in \#*|'') continue ;; esac
  IFS=',' read -ra FR <<< "$fragments"
  for frag in "${FR[@]}"; do
    [ -f "$REPO_ROOT/.prospect/prompts/$frag" ] || err "matrix references missing fragment: $frag"
  done
done < <(tr -d '\r' < "$REPO_ROOT/.prospect/prompts/matrix.tsv")

echo ""
if [ $FAIL -eq 0 ]; then
  echo "resolver tests: PASS ($TESTS tests)"
else
  echo "resolver tests: FAIL"
  exit 1
fi
