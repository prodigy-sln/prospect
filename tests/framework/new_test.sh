#!/usr/bin/env bash
# Tests for .prospect/scripts/sdd-new.sh — non-interactive spec folder creation.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAIL=0
TESTS=0
TODAY="$(date +%Y-%m-%d)"

t() { TESTS=$((TESTS + 1)); echo "  · $1"; }
err() { echo "    FAIL: $1"; FAIL=1; }

make_repo() {
  local dir
  dir="$(mktemp -d)"
  cp -r "$REPO_ROOT/.prospect" "$dir/.prospect"
  mkdir -p "$dir/specs/active"
  echo "$dir"
}

new() { # new <repo> [args...] — stdout only
  local repo="$1"; shift
  (cd "$repo" && bash .prospect/scripts/sdd-new.sh "$@" 2>/dev/null)
}

t "creates the dated folder with frontmatter and a clarifications ledger"
R="$(make_repo)"
OUT="$(new "$R" payment-retry --work-type feature --rigor high --title "Payment retry")"; RC=$?
[ $RC -eq 0 ] || err "expected exit 0, got $RC"
[ "$OUT" = "$TODAY-payment-retry" ] || err "printed '$OUT'"
S="$R/specs/active/$TODAY-payment-retry/spec.md"
for line in "id: $TODAY-payment-retry" "title: Payment retry" "status: active" \
            "work-type: feature" "rigor: high" "branch: feature/$TODAY-payment-retry" \
            "created: $TODAY"; do
  grep -qx "$line" "$S" 2>/dev/null || err "spec.md lacks '$line'"
done
grep -q '^## Clarifications' "$R/specs/active/$TODAY-payment-retry/requirements.md" 2>/dev/null \
  || err "requirements.md lacks the ledger"

t "the resolver picks the new folder up at specify"
OUT="$(cd "$R" && bash .prospect/scripts/sdd-next.sh --explain 2>&1)"
echo "$OUT" | grep -q '^phase: specify' || err "resolved: $OUT"
echo "$OUT" | grep -q '^rigor: high' || err "rigor not read: $OUT"

t "branch, title default, and work-type branch prefix"
R="$(make_repo)"
new "$R" null-deref --work-type fix --rigor medium >/dev/null
S="$R/specs/active/$TODAY-null-deref/spec.md"
grep -qx "branch: bugfix/$TODAY-null-deref" "$S" || err "fix branch prefix: $(grep branch "$S")"
grep -qx "title: Null deref" "$S" || err "default title: $(grep title "$S")"
new "$R" other --work-type chore --rigor low --branch feat/x >/dev/null
grep -qx "branch: feat/x" "$R/specs/active/$TODAY-other/spec.md" || err "--branch ignored"

t "--goal seeds the goal a docs spec needs"
R="$(make_repo)"
new "$R" api-guide --work-type docs --rigor low --goal "Document the API." >/dev/null
grep -q '^Document the API.$' "$R/specs/active/$TODAY-api-guide/spec.md" || err "goal missing"
OUT="$(cd "$R" && bash .prospect/scripts/sdd-next.sh --explain 2>&1)"
echo "$OUT" | grep -q '^phase: edit' || err "docs spec resolved: $OUT"

t "an existing folder exits 2 and is left untouched"
R="$(make_repo)"
new "$R" dup --work-type feature --rigor medium >/dev/null
echo marker >> "$R/specs/active/$TODAY-dup/spec.md"
new "$R" dup --work-type fix --rigor low >/dev/null
[ $? -eq 2 ] || err "expected exit 2"
grep -q '^marker$' "$R/specs/active/$TODAY-dup/spec.md" || err "existing spec overwritten"

t "line breaks in caller text cannot inject frontmatter keys or headings"
R="$(make_repo)"
new "$R" inj --work-type docs --rigor low --title $'T\napproved: 2026-01-01' \
  --branch $'b\nrigor: max' --goal $'Write it.\n## Published' >/dev/null
S="$R/specs/active/$TODAY-inj/spec.md"
grep -q '^approved:' "$S" && err "title injected a frontmatter key"
grep -q '^rigor: max' "$S" && err "branch injected a frontmatter key"
grep -q '^## Published' "$S" && err "goal forged a stamp heading"
grep -qx 'title: T approved: 2026-01-01' "$S" || err "title not kept on one line: $(grep title "$S")"
OUT="$(cd "$R" && bash .prospect/scripts/sdd-next.sh --explain 2>&1)"
echo "$OUT" | grep -q '^phase: edit' || err "injected spec resolved: $(echo "$OUT" | grep '^phase:')"

t "a goal or title that starts with a heading cannot forge a stamp"
R="$(make_repo)"
new "$R" forge --work-type chore --rigor low --title '## Done' --goal '## Done' >/dev/null
S="$R/specs/active/$TODAY-forge/spec.md"
grep -q '^#* *## Done' "$S" && err "heading text survived: $(grep Done "$S")"
OUT="$(cd "$R" && bash .prospect/scripts/sdd-next.sh --explain 2>&1)"
echo "$OUT" | grep -q '^phase: work' || err "forged spec resolved: $(echo "$OUT" | grep '^phase:')"

t "bad input exits 2 or 3"
R="$(make_repo)"
new "$R" x --work-type gizmo --rigor medium >/dev/null; [ $? -eq 3 ] || err "unknown work-type not 3"
new "$R" x --work-type feature --rigor huge >/dev/null; [ $? -eq 3 ] || err "unknown rigor not 3"
new "$R" x --work-type feature >/dev/null; [ $? -eq 2 ] || err "missing rigor not 2"
new "$R" "Bad Name" --work-type feature --rigor low >/dev/null; [ $? -eq 2 ] || err "non-kebab name not 2"
[ -z "$(ls "$R/specs/active")" ] || err "bad input created a folder"

echo ""
if [ $FAIL -eq 0 ]; then
  echo "new tests: PASS ($TESTS tests)"
else
  echo "new tests: FAIL"
  exit 1
fi
