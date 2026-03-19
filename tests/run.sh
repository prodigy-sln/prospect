#!/usr/bin/env bash
# Simple test runner — no dependencies required
# Usage: ./tests/run.sh [test_file_or_dir...]
# If no arguments, runs all test files matching tests/**/*_test.sh

set -euo pipefail

PASS=0
FAIL=0
ERRORS=()

run_test_file() {
  local file="$1"
  echo "── $file"
  if bash "$file"; then
    return 0
  else
    return 1
  fi
}

# Collect test files
if [[ $# -gt 0 ]]; then
  FILES=("$@")
else
  FILES=()
  while IFS= read -r -d '' f; do
    FILES+=("$f")
  done < <(find tests -name '*_test.sh' -print0 | sort -z)
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No test files found."
  exit 1
fi

echo "Running ${#FILES[@]} test file(s)..."
echo ""

for file in "${FILES[@]}"; do
  if run_test_file "$file"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    ERRORS+=("$file")
  fi
  echo ""
done

echo "════════════════════════════════"
echo "Results: $PASS passed, $FAIL failed (out of $((PASS + FAIL)) files)"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failed:"
  for e in "${ERRORS[@]}"; do
    echo "  ✗ $e"
  done
  exit 1
fi
