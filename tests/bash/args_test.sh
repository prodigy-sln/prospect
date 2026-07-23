#!/usr/bin/env bash
# Unit tests for install.sh argument parsing
# Task T004 — covers FR-1.4
#
# Tests verify: --help, version argument, default (no arguments), unknown
# flags, and that the removed toolchain flags are now rejected.

set -euo pipefail

source "$(dirname "$0")/../helpers/setup.bash"

# Resolve the install script path relative to this file so tests work
# regardless of the caller's working directory.
INSTALL_SH="$(cd "$(dirname "$0")/../.." && pwd)/install.sh"

# ── Internal helper ───────────────────────────────────────────────────────────

# Wrapper that converts a failed assertion (return 1) into an exit 1 so that
# the run_tests subshell (which disables set -e in an if-condition context)
# still terminates with a non-zero status.
_fail() {
  echo "    FAIL: $*" >&2
  exit 1
}

# ── Tests ─────────────────────────────────────────────────────────────────────

# FR-2.5 / spec: --help prints usage and exits 0
test_args_help_flag_prints_usage_and_exits_0() {
  local output
  local status=0
  output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" --help 2>&1) || status=$?
  assert_status 0 "$status" "--help should exit with status 0" || _fail "--help should exit with status 0"
  assert_contains "$output" "usage" "--help output should contain usage information" || _fail "--help output should contain usage information"
}

# FR-1.4: a semver version argument (e.g. v1.0.0) is accepted without error
test_args_version_argument_is_accepted() {
  local output
  local status=0
  output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" v1.0.0 2>&1) || status=$?
  assert_not_contains "$output" "unknown option" "version arg should not produce an unknown-option error" || _fail "version arg produced an unknown-option error"
  assert_not_contains "$output" "invalid option" "version arg should not produce an invalid-option error" || _fail "version arg produced an invalid-option error"
}

# The removed toolchain flags must now be rejected as unknown options.
test_args_removed_toolchain_flags_are_unknown() {
  for flag in --claude --copilot --all; do
    local output
    local status=0
    output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" "$flag" 2>&1) || status=$?
    assert_status 1 "$status" "$flag should exit with status 1" || _fail "$flag did not exit with status 1 (got $status)"
    assert_contains "$output" "unknown" "$flag should be reported as an unknown option" || _fail "$flag was not reported as unknown"
  done
}

# FR-1.4: running without arguments must not print a "version required" error —
# no-args defaults to latest version
test_args_no_arguments_defaults_to_latest_version() {
  local output
  output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" 2>&1) || true
  assert_not_contains "$output" "version required" "omitting version should not produce a version-required error" || _fail "no-args produced a version-required error"
}

# FR-2.5: an unknown flag must exit non-zero and print a message containing
# the word "unknown" so the user understands what went wrong
test_args_unknown_flag_exits_nonzero_with_error_message() {
  local output
  local status=0
  output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" --unknown-flag 2>&1) || status=$?
  assert_status 1 "$status" "unknown flag should exit with status 1" || _fail "unknown flag did not exit with status 1 (got $status)"
  assert_contains "$output" "unknown" "error message should identify the offending flag" || _fail "error message did not contain 'unknown'"
}

# ── Run ───────────────────────────────────────────────────────────────────────

run_tests
