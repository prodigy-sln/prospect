#!/usr/bin/env bash
# Unit tests for install.sh argument parsing
# Task T004 — covers FR-1.4, FR-2.5
#
# Tests verify: --help, --claude, --copilot, --all, version argument,
# default (no arguments), and unknown flags.
#
# Tests WILL FAIL until install.sh is implemented (RED phase).

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

# FR-2.5: --claude flag is recognised — must not print an unknown-flag error
test_args_claude_flag_is_recognised() {
  local output
  local status=0
  output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" --claude 2>&1) || status=$?
  assert_not_contains "$output" "unknown option" "--claude should not produce an unknown-option error" || _fail "--claude produced an unknown-option error"
  assert_not_contains "$output" "invalid option" "--claude should not produce an invalid-option error" || _fail "--claude produced an invalid-option error"
}

# FR-2.5: --copilot flag is recognised — must not print an unknown-flag error
test_args_copilot_flag_is_recognised() {
  local output
  local status=0
  output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" --copilot 2>&1) || status=$?
  assert_not_contains "$output" "unknown option" "--copilot should not produce an unknown-option error" || _fail "--copilot produced an unknown-option error"
  assert_not_contains "$output" "invalid option" "--copilot should not produce an invalid-option error" || _fail "--copilot produced an invalid-option error"
}

# FR-2.5: --all flag is recognised — must not print an unknown-flag error
test_args_all_flag_is_recognised() {
  local output
  local status=0
  output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" --all 2>&1) || status=$?
  assert_not_contains "$output" "unknown option" "--all should not produce an unknown-option error" || _fail "--all produced an unknown-option error"
  assert_not_contains "$output" "invalid option" "--all should not produce an invalid-option error" || _fail "--all produced an invalid-option error"
}

# FR-1.4: a semver version argument (e.g. v1.0.0) is accepted without error
test_args_version_argument_is_accepted() {
  local output
  local status=0
  output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" v1.0.0 2>&1) || status=$?
  assert_not_contains "$output" "unknown option" "version arg should not produce an unknown-option error" || _fail "version arg produced an unknown-option error"
  assert_not_contains "$output" "invalid option" "version arg should not produce an invalid-option error" || _fail "version arg produced an invalid-option error"
}

# FR-1.4 + FR-2.5: combining a version argument with a toolchain flag is accepted
test_args_version_and_toolchain_flag_combined_are_accepted() {
  local output
  local status=0
  output=$(cd "$TEST_DIR" && PROSPECT_DRY_RUN=1 bash "$INSTALL_SH" v1.0.0 --claude 2>&1) || status=$?
  assert_not_contains "$output" "unknown option" "version + --claude should not produce an unknown-option error" || _fail "version + --claude produced an unknown-option error"
  assert_not_contains "$output" "invalid option" "version + --claude should not produce an invalid-option error" || _fail "version + --claude produced an invalid-option error"
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
