#!/usr/bin/env bash
# sdd-reopen.sh — reopen a finished phase for a scoped amendment.
# Queues ledger entries in reopen.md (the resolver runs them before its
# normal probes) and invalidates only what the scope touches: ticked tasks
# covering scoped scenarios, their test-map lines, and the validation
# verdict. Never deletes an artifact and never removes `approved:`.
# Rewritten files keep their line endings.
#
# Usage: sdd-reopen.sh <folder> <phase> [--scope <ids>] --reason "<text>"
#   ids: comma-separated scenario ids (FR-1.2-S1) or requirement prefixes
#   (FR-1.2), each present in spec.md; no or empty scope reopens the whole
#   phase. An identical open entry already queued is not queued again.
# Exit codes: 0 reopened or already queued · 1 rewrite failed ·
#             2 usage, folder missing, or unknown scope id ·
#             3 unknown type/phase, or complete
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MATRIX="$ROOT/.prospect/prompts/matrix.tsv"
ACTIVE="$ROOT/specs/active"

usage() { echo "usage: sdd-reopen.sh <folder> <phase> [--scope <ids>] --reason \"<text>\"" >&2; exit 2; }

folder=""; phase=""; scope=""; reason=""
while [ $# -gt 0 ]; do
  case "$1" in
    --scope) [ $# -ge 2 ] || usage; scope="$2"; shift 2 ;;
    --reason) [ $# -ge 2 ] || usage; reason="$2"; shift 2 ;;
    -*) echo "unknown option: $1" >&2; usage ;;
    *)
      if [ -z "$folder" ]; then folder="$1"
      elif [ -z "$phase" ]; then phase="$1"
      else usage
      fi
      shift ;;
  esac
done
[ -n "$folder" ] && [ -n "$phase" ] && [ -n "$reason" ] || usage

folder="${folder%/}"; folder="${folder##*/}"
DIR="$ACTIVE/$folder"
SPEC="$DIR/spec.md"
[ -f "$SPEC" ] || { echo "$DIR has no spec.md" >&2; exit 2; }

fm() { # fm <key> — first frontmatter value for key
  awk -v k="$1" -F': *' 'NR>1 && /^---[[:space:]]*$/{exit} $1==k{print $2; exit}' "$SPEC" | tr -d '\r'
}
wtype="$(fm 'work-type')"; wtype="${wtype:-feature}"
rigor="$(fm 'rigor')"; rigor="${rigor:-medium}"

# complete publishes and disposes of the folder; there is nothing to amend.
[ "$phase" = complete ] && { echo "complete cannot be reopened; reopen the phase that owns the defect" >&2; exit 3; }

has_cell() { # has_cell <phase> — the matrix composes this phase for the spec
  tr -d '\r' < "$MATRIX" | awk -F'\t' -v t="$wtype" -v r="$rigor" -v p="$1" '
    $1==t && $3==p { n = split($2, rs, "|"); for (i = 1; i <= n; i++) if (rs[i] == r) { f = 1; exit } }
    END { exit !f }'
}
has_cell "$phase" || { echo "no matrix entry for $wtype/$rigor/$phase" >&2; exit 3; }

# Scope ids: comma/space separated. Reasons stay one line, and lose the
# ledger's field separator and backticks so the entry parses and quotes.
scope="$(printf '%s' "$scope" | tr ',\r\n\t' '    ' | tr -s ' ' | sed 's/^ //; s/ $//')"
scope_label="${scope:-all}"; scope_label="${scope_label// /,}"
reason="$(printf '%s' "$reason" | tr '\r\n\t`' "   '" | sed 's/·/-/g')"

# The matcher shared by every awk pass: a token matches a scope id exactly
# or as a requirement prefix (FR-1.2 covers FR-1.2-S1); tokens lose
# trailing punctuation (".", "-").
AWK_SCOPE='
  function in_scope(id,   k) {
    for (k in S) if (id == k || index(id, k "-") == 1) return 1
    return 0
  }
  function line_hits(s,   n, i, tok) {
    n = split(s, tok, /[^A-Za-z0-9.-]+/)
    for (i = 1; i <= n; i++) {
      sub(/[.-]+$/, "", tok[i])
      if (tok[i] != "" && in_scope(tok[i])) return 1
    }
    return 0
  }
  BEGIN { m = split(scope, a, " "); for (i = 1; i <= m; i++) S[a[i]] = 1 }'

# Every scope id must name something in the spec; a typo would otherwise
# invalidate nothing and still discard the verdict.
for id in $scope; do
  awk -v scope="$id" "$AWK_SCOPE"' line_hits($0) { f = 1; exit } END { exit !f }' "$SPEC" \
    || { echo "scope id not found in spec.md: $id" >&2; exit 2; }
done

# rewrite <file> <awk-program> [awk-args...] — run the program over the file
# with CR stripped per line (CR[NR] records it; out() restores it), write
# the result back in place (keeping mode), and fail loudly on an awk error.
AWK_IO='
  { cr = sub(/\r$/, "") }
  function out(s) { printf "%s%s\n", s, (cr ? "\r" : "") }'
rewrite() {
  local file="$1" prog="$2" tmp; shift 2
  tmp="$(mktemp)"
  # BINMODE=3 stops Windows gawk from dropping CRs; other awks ignore it.
  if ! awk -v BINMODE=3 "$@" "$AWK_IO$prog" "$file" > "$tmp"; then
    rm -f "$tmp"; echo "failed to rewrite $file" >&2; exit 1
  fi
  cat "$tmp" > "$file"; rm -f "$tmp"
}

LEDGER="$DIR/reopen.md"
if [ ! -f "$LEDGER" ]; then
  printf '# Reopen Ledger\n\nOpen entries run first, top to bottom; each run closes its own entry.\n\n' > "$LEDGER"
fi
queued() { # queued <phase> — an open entry with this phase and scope exists
  tr -d '\r' < "$LEDGER" | grep '^- \[open\] ' | grep -qF -- " · phase: $1 · scope: $scope_label · "
}
if queued "$phase"; then
  echo "already queued: $phase · scope: $scope_label"
  exit 0
fi

# Downstream stages that own an artifact the amendment may invalidate.
stages="$phase"
add_stage() { [ -f "$DIR/$2" ] && has_cell "$1" && ! queued "$1" && stages="$stages $1"; }
case "$wtype/$phase" in
  feature/specify) add_stage architect architecture.md; add_stage tasks tasks.md ;;
  feature/architect) add_stage tasks tasks.md ;;
  decision/specify) add_stage decide decision-record.md ;;
esac

n=$(grep -oE '^- \[(open|closed)\] R[0-9]+' "$LEDGER" | sed 's/.*R//' | sort -n | tail -1)
n=$(( ${n:-0} + 1 ))
primary="R$n"
at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
for s in $stages; do
  line="- [open] R$n · phase: $s · scope: $scope_label · reason: $reason · at: $at"
  echo "$line" >> "$LEDGER"
  echo "$line"
  n=$((n + 1))
done

# The verdict no longer holds; the report stays for reference.
if [ -f "$DIR/validation-report.md" ]; then
  mkdir -p "$DIR/history"
  mv "$DIR/validation-report.md" "$DIR/history/validation-report.$primary.md"
  echo "validation report → history/validation-report.$primary.md"
fi

# Stamped completion headings (low-rigor validation, docs, chore) go stale
# the same way; the resolver ignores headings marked stale.
rewrite "$SPEC" '
  /^## (Validation|Published|Done)([[:space:]]|$)/ && !/\(stale / {
    h = $0; sub(/^## [A-Za-z]+/, "& (stale " tag ")", h); out(h); next
  }
  { out($0) }' -v tag="$primary"

# tasks.md: untick tasks whose Scenarios line intersects the scope. A
# whole-phase reopen of implement unticks every task.
TASKS="$DIR/tasks.md"
if [ -f "$TASKS" ] && [ "$phase" != validate ] \
   && { [ -n "$scope" ] || [ "$phase" = implement ]; }; then
  rewrite "$TASKS" "$AWK_SCOPE"'
    { L[NR] = $0; C[NR] = cr }
    END {
      for (i = 1; i <= NR; i++) {
        if (L[i] ~ /^[[:space:]]*- \[[xX]\]/) {
          hit = all
          for (j = i + 1; !hit && j <= NR && L[j] !~ /^[[:space:]]*- \[/ && L[j] !~ /^#/; j++)
            if (L[j] ~ /Scenarios:/) hit = line_hits(substr(L[j], index(L[j], "Scenarios:") + 10))
          if (hit) {
            sub(/- \[[xX]\]/, "- [ ]", L[i]); L[i] = L[i] " — reopened " tag
            t = L[i]; sub(/^[[:space:]]*- \[ \][[:space:]]*/, "", t); split(t, w, " ")
            print "unticked: " w[1] > "/dev/stderr"
          }
        }
        cr = C[i]; out(L[i])
      }
    }' -v scope="$scope" -v all="$([ -z "$scope" ] && echo 1 || echo 0)" -v tag="$primary"
fi

# test-map.md: mark mappings of scoped scenarios stale.
MAP="$DIR/test-map.md"
if [ -f "$MAP" ] && [ -n "$scope" ]; then
  rewrite "$MAP" "$AWK_SCOPE"'
    /→|->/ && line_hits($0) { $0 = $0 " (stale " tag ")"; c++ }
    { out($0) }
    END { print "stale test-map lines: " c + 0 > "/dev/stderr" }' -v scope="$scope" -v tag="$primary"
fi

exit 0
