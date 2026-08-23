#!/usr/bin/env bash
# Tests for .prospect/scripts/sdd-artifact-lint.sh — the artifact budget lint.
# Each test builds a disposable spec folder under a fake repo root and asserts
# the verdict, exit code, and that no shell diagnostics leak into the output.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LINT="$REPO_ROOT/.prospect/scripts/sdd-artifact-lint.sh"
FAIL=0
TESTS=0

t() { TESTS=$((TESTS + 1)); echo "  · $1"; }
err() { echo "    FAIL: $1"; FAIL=1; }

# make_repo [registry-body] — fake repo root with one active spec folder
make_repo() {
  local dir
  dir="$(mktemp -d)"
  mkdir -p "$dir/specs/active/2026-01-01-t"
  printf '# Spec Registry\n\nFormat: `[folder] · [completed] · [rigor] · [summary]`\n\n---\n\n%s' \
    "${1:-}" > "$dir/specs/REGISTRY.md"
  printf '%s' "$dir"
}

# lint <repo> — run the lint on that repo's spec folder, stdout+stderr merged
lint() { (cd "$1" && bash "$LINT" specs/active/2026-01-01-t 2>&1); }

# repeat_lines <n> <text>
repeat_lines() { local i; for ((i = 0; i < $1; i++)); do echo "$2"; done; }

# ── test-map.md budget ────────────────────────────────────────────────────

t "an oversized test-map.md with zero mappings fails the lint"
R="$(make_repo)"
repeat_lines 20 "prose with no mapping arrow" > "$R/specs/active/2026-01-01-t/test-map.md"
OUT="$(lint "$R")"; RC=$?
[ $RC -eq 1 ] || err "expected exit 1, got $RC — the zero-mapping budget check did not run"
echo "$OUT" | grep -q "test-map.md: 20 lines for 0 mappings" || err "missing test-map budget failure: $OUT"

t "no shell diagnostic leaks when test-map.md has zero mappings"
R="$(make_repo)"
echo "prose only" > "$R/specs/active/2026-01-01-t/test-map.md"
OUT="$(lint "$R")"
echo "$OUT" | grep -qi "syntax error" && err "arithmetic error leaked into output: $OUT"

t "a small test-map.md with zero mappings passes"
R="$(make_repo)"
repeat_lines 5 "header prose" > "$R/specs/active/2026-01-01-t/test-map.md"
OUT="$(lint "$R")"; RC=$?
[ $RC -eq 0 ] || err "expected exit 0, got $RC: $OUT"

t "mappings raise the budget three lines each"
R="$(make_repo)"
{ repeat_lines 6 "FR-1.1-S1 → renders the empty state"; repeat_lines 20 "notes"; } \
  > "$R/specs/active/2026-01-01-t/test-map.md"
OUT="$(lint "$R")"; RC=$?
[ $RC -eq 0 ] || err "26 lines for 6 mappings (budget 28) should pass: $OUT"

t "the ASCII arrow counts as a mapping"
R="$(make_repo)"
repeat_lines 12 "FR-1.1-S1 -> renders the empty state" > "$R/specs/active/2026-01-01-t/test-map.md"
OUT="$(lint "$R")"
echo "$OUT" | grep -q "for 12 mappings" || echo "$OUT" | grep -q "artifact lint: PASS" \
  || err "ASCII arrow not recognised: $OUT"

# ── line counting ─────────────────────────────────────────────────────────

t "a final line without a trailing newline is counted"
R="$(make_repo)"
{ repeat_lines 60 "- [ ] task"; printf -- "- [ ] unterminated"; } \
  > "$R/specs/active/2026-01-01-t/tasks.md"
OUT="$(lint "$R")"; RC=$?
[ $RC -eq 1 ] || err "expected exit 1 for 61 lines, got $RC: $OUT"
echo "$OUT" | grep -q "tasks.md: 61 lines" || err "expected 61 counted lines: $OUT"

t "tasks.md exactly at budget passes"
R="$(make_repo)"
repeat_lines 60 "- [ ] task" > "$R/specs/active/2026-01-01-t/tasks.md"
OUT="$(lint "$R")"; RC=$?
[ $RC -eq 0 ] || err "60 lines should pass: $OUT"

# ── REGISTRY.md ───────────────────────────────────────────────────────────

t "an over-long registry entry without a bullet is caught"
LONG="$(repeat_lines 1 "$(printf 'word %.0s' $(seq 60))")"
R="$(make_repo "2026-01-01-t · 2026-01-02 · fix/medium · $LONG · PR #1")"
OUT="$(lint "$R")"; RC=$?
[ $RC -eq 1 ] || err "expected exit 1 for a >50-word entry, got $RC: $OUT"
echo "$OUT" | grep -q "REGISTRY.md entry exceeds 50 words" || err "missing registry failure: $OUT"

t "the registry format legend is not treated as an entry"
R="$(make_repo "- 2026-01-01-t · 2026-01-02 · fix/medium · short summary · PR #1")"
OUT="$(lint "$R")"; RC=$?
[ $RC -eq 0 ] || err "a compliant registry should pass: $OUT"

t "the registry is found from an archived spec folder"
R="$(make_repo "2026-01-01-t · 2026-01-02 · fix/medium · $(repeat_lines 1 "$(printf 'word %.0s' $(seq 60))") · PR #1")"
mkdir -p "$R/specs/archive/2026/2026-01-01-t"
OUT="$( (cd "$R" && bash "$LINT" specs/archive/2026/2026-01-01-t 2>&1) )"; RC=$?
[ $RC -eq 1 ] || err "registry check skipped for an archived folder (exit $RC): $OUT"

# ── guards ────────────────────────────────────────────────────────────────

t "a missing spec folder exits 2"
(bash "$LINT" /nonexistent/spec/folder) >/dev/null 2>&1
[ $? -eq 2 ] || err "expected exit 2 for a missing folder"

echo ""
if [ $FAIL -eq 0 ]; then
  echo "artifact lint tests: PASS ($TESTS tests)"
else
  echo "artifact lint tests: FAIL"
  exit 1
fi
