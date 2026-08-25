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
