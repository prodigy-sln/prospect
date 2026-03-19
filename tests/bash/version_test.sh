#!/usr/bin/env bash
# Unit tests for resolve_version() in install.sh
#
# Covers:
#   FR-1.4 — optional version argument; omitting resolves "latest"
#   FR-7.2 — clear error on GitHub API failure, not a cryptic shell error
#
# RED phase: install.sh does not yet define resolve_version(), so all tests fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/setup.bash"

# ── Source install.sh (functions only, no main execution) ──────────────────────
#
# install.sh must guard its main block so sourcing only loads function
# definitions:
#   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi
#
# A stub install.sh may use a bare `exit 1` as a temporary guard.  Sourcing
# such a file would kill the current shell, so we neutralise top-level exit
# lines before eval'ing the content.

INSTALL_SH="$SCRIPT_DIR/../../install.sh"

if [[ ! -f "$INSTALL_SH" ]]; then
  echo "NOTE: install.sh not found at $INSTALL_SH" >&2
  echo "  Tests will fail because resolve_version() is not defined." >&2
else
  _raw="$(cat "$INSTALL_SH")"
  # Replace bare `exit [N]` lines (stub guards) with no-ops, then eval.
  # The `|| true` prevents set -e from aborting if eval still errors.
  _patched="$(printf '%s\n' "$_raw" \
    | sed 's/^[[:space:]]*exit[[:space:]]*[0-9]*[[:space:]]*$/: # exit neutralised for sourcing/')"
  _PROSPECT_SOURCED=1 eval "$_patched" 2>/dev/null || true
  unset _raw _patched
fi

# ── Internal helpers ────────────────────────────────────────────────────────────

# _fail <message>
# Prints a FAIL message and exits the current (sub)shell with status 1.
# Using exit rather than return because run_tests wraps each test in a
# subshell via `if ( ... )`, which disables set -e for return values.
_fail() {
  echo "    FAIL: $*" >&2
  exit 1
}

# is_semver_tag <string>
# Returns 0 if <string> matches vX.Y.Z, 1 otherwise.
is_semver_tag() {
  [[ "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# resolve_version_defined
# Returns 0 if resolve_version() is defined as a shell function, else _fail.
resolve_version_defined() {
  if ! declare -f resolve_version > /dev/null 2>&1; then
    _fail "resolve_version() is not defined in install.sh — implement it first"
  fi
}

# Override the internal GitHub API helper that resolve_version() delegates to.
# install.sh must use a function named _fetch_latest_version_tag for the
# actual HTTP request so tests can substitute it without network access.
_mock_github_api_success() {
  # shellcheck disable=SC2317
  _fetch_latest_version_tag() { echo "v2.3.4"; }
}

_mock_github_api_failure() {
  # shellcheck disable=SC2317
  _fetch_latest_version_tag() { return 1; }
}

# ── Tests ──────────────────────────────────────────────────────────────────────

# test_resolve_version_function_is_defined
#
# The most basic requirement: install.sh must export a resolve_version
# function.  This test gives a clear, actionable failure message in RED phase.
test_resolve_version_function_is_defined() {
  declare -f resolve_version > /dev/null 2>&1 \
    || _fail "resolve_version() is not defined in install.sh"
}

# test_resolve_latest_version_returns_semver_tag
#
# Calling resolve_version with no argument must query the GitHub API
# (via _fetch_latest_version_tag) and return a string matching vX.Y.Z.
test_resolve_latest_version_returns_semver_tag() {
  resolve_version_defined
  _mock_github_api_success

  local version status
  status=0
  version="$(resolve_version)" || status=$?

  [[ $status -eq 0 ]] \
    || _fail "resolve_version (no arg) exited with status $status"

  is_semver_tag "$version" \
    || _fail "expected vX.Y.Z semver tag, got: '$version'"
}

# test_resolve_latest_version_with_explicit_latest_keyword
#
# Passing the literal string "latest" must behave identically to no argument:
# delegates to the API and returns a semver tag.
test_resolve_latest_version_with_explicit_latest_keyword() {
  resolve_version_defined
  _mock_github_api_success

  local version status
  status=0
  version="$(resolve_version "latest")" || status=$?

  [[ $status -eq 0 ]] \
    || _fail "resolve_version latest exited with status $status"

  is_semver_tag "$version" \
    || _fail "expected vX.Y.Z semver tag, got: '$version'"
}

# test_resolve_specific_version_returns_the_same_version
#
# When a valid semver tag is provided, resolve_version must echo it back
# unchanged — no network call required.
test_resolve_specific_version_returns_the_same_version() {
  resolve_version_defined

  local version status
  status=0
  version="$(resolve_version "v1.2.3")" || status=$?

  [[ $status -eq 0 ]] \
    || _fail "resolve_version v1.2.3 exited with status $status"

  assert_eq "v1.2.3" "$version" \
    "resolve_version v1.2.3 should return v1.2.3 verbatim" \
    || _fail "resolve_version v1.2.3 should return v1.2.3 verbatim (got '$version')"
}

# test_resolve_version_api_failure_prints_error_and_exits_nonzero
#
# When _fetch_latest_version_tag returns non-zero (API unreachable / rate
# limited), resolve_version must:
#   1. Exit with a non-zero status (FR-7.2).
#   2. Print a human-readable error — not a raw shell trace — containing at
#      least one of: error, failed, fail, unreachable, unable.
test_resolve_version_api_failure_prints_error_and_exits_nonzero() {
  resolve_version_defined
  _mock_github_api_failure

  local output status
  status=0
  output="$(resolve_version 2>&1)" || status=$?

  [[ $status -ne 0 ]] \
    || _fail "expected non-zero exit on API failure, got status 0"

  local lower
  lower="$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')"

  [[ "$lower" == *"error"*     \
  || "$lower" == *"failed"*    \
  || "$lower" == *"fail"*      \
  || "$lower" == *"unreachable"* \
  || "$lower" == *"unable"* ]] \
    || _fail "error output must contain a user-friendly word (error|failed|fail|unreachable|unable); got: '$output'"
}

# test_resolve_version_invalid_format_exits_nonzero_with_error
#
# Passing a string that is neither "latest" nor a valid vX.Y.Z tag (e.g.
# "abc", "1.2.3", "v1.x.0") must exit non-zero and print a message that
# identifies the problem (contains: invalid|error|format|version).
test_resolve_version_invalid_format_exits_nonzero_with_error() {
  resolve_version_defined

  local output status
  status=0
  output="$(resolve_version "abc" 2>&1)" || status=$?

  [[ $status -ne 0 ]] \
    || _fail "expected non-zero exit for invalid version 'abc', got status 0"

  local lower
  lower="$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')"

  [[ "$lower" == *"invalid"* \
  || "$lower" == *"error"*   \
  || "$lower" == *"format"*  \
  || "$lower" == *"version"* ]] \
    || _fail "error output must mention invalid format (invalid|error|format|version); got: '$output'"
}

# ── Run ────────────────────────────────────────────────────────────────────────

run_tests
