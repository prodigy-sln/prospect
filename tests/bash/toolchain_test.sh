#!/usr/bin/env bash
# Unit tests for select_toolchain() in install.sh
#
# Covers:
#   FR-2.1 — interactive multi-select prompt for toolchain
#   FR-2.5 — non-interactive defaults to "all"; --claude/--copilot/--all flags override
#   FR-4.3 — manifest-based default when no flag is provided
#
# RED phase: install.sh does not yet define select_toolchain(), so all tests fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/setup.bash"

# ── Source install.sh (functions only, no main execution) ──────────────────────
#
# install.sh guards its main block with:
#   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi
#
# Bare `exit [N]` lines (stub guards) are neutralised before eval so sourcing
# does not terminate the current shell.

INSTALL_SH="$SCRIPT_DIR/../../install.sh"

if [[ ! -f "$INSTALL_SH" ]]; then
  echo "NOTE: install.sh not found at $INSTALL_SH" >&2
  echo "  Tests will fail because select_toolchain() is not defined." >&2
else
  _raw="$(cat "$INSTALL_SH")"
  _patched="$(printf '%s\n' "$_raw" \
    | sed 's/^[[:space:]]*exit[[:space:]]*[0-9]*[[:space:]]*$/: # exit neutralised for sourcing/')"
  _PROSPECT_SOURCED=1 eval "$_patched" 2>/dev/null || true
  unset _raw _patched
fi

# ── Internal helpers ────────────────────────────────────────────────────────────

# _fail <message>
# Prints a FAIL message and exits the current (sub)shell with status 1.
_fail() {
  echo "    FAIL: $*" >&2
  exit 1
}

# select_toolchain_defined
# Returns 0 if select_toolchain() is declared as a shell function, else _fail.
select_toolchain_defined() {
  if ! declare -f select_toolchain > /dev/null 2>&1; then
    _fail "select_toolchain() is not defined in install.sh — implement it first"
  fi
}

# is_valid_toolchain <value>
# Returns 0 if <value> is one of the three allowed toolchain identifiers.
is_valid_toolchain() {
  case "$1" in
    claude|copilot|all) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Tests ──────────────────────────────────────────────────────────────────────

# test_select_toolchain_function_is_defined
#
# The most basic requirement: install.sh must define a select_toolchain
# function.  A clear failure here directs the implementer immediately.
test_select_toolchain_function_is_defined() {
  declare -f select_toolchain > /dev/null 2>&1 \
    || _fail "select_toolchain() is not defined in install.sh"
}

# test_select_toolchain_uses_flag_when_set
#
# FR-2.5: When TOOLCHAIN is already set via a CLI flag (--claude, --copilot,
# --all), select_toolchain must echo that value unchanged and exit zero.
# No manifest or tty check is needed — the flag wins unconditionally.
test_select_toolchain_uses_flag_when_set() {
  select_toolchain_defined

  TOOLCHAIN="claude"
  local result status
  status=0
  result="$(select_toolchain "$TEST_DIR" 2>/dev/null)" || status=$?

  [[ $status -eq 0 ]] \
    || _fail "select_toolchain exited with status $status when TOOLCHAIN=claude"

  assert_eq "claude" "$result" \
    "select_toolchain should return 'claude' when TOOLCHAIN flag is set" \
    || _fail "expected 'claude', got '$result'"
}

# test_select_toolchain_uses_manifest_default
#
# FR-4.3: When no flag is set but a .prospect-manifest.json exists in the
# target directory with a "toolchains" field, select_toolchain must default to
# the first toolchain listed in that array (non-interactive path).
#
# stdin is not a terminal in tests, so the non-interactive branch is exercised.
test_select_toolchain_uses_manifest_default() {
  select_toolchain_defined

  # Create a manifest recording a previous "claude"-only install.
  printf '{"version":"v1.0.0","toolchains":["claude"],"files":{}}\n' \
    > "$TEST_DIR/.prospect-manifest.json"

  TOOLCHAIN=""
  local result status
  status=0
  result="$(select_toolchain "$TEST_DIR" 2>/dev/null)" || status=$?

  [[ $status -eq 0 ]] \
    || _fail "select_toolchain exited with status $status when manifest present"

  assert_eq "claude" "$result" \
    "select_toolchain should return manifest toolchain 'claude' when no flag set" \
    || _fail "expected 'claude' from manifest, got '$result'"
}

# test_select_toolchain_defaults_to_all_when_non_interactive
#
# FR-2.5: When no flag is set and no manifest exists, and stdin is not a
# terminal (piped/non-interactive), select_toolchain must default to "all".
test_select_toolchain_defaults_to_all_when_non_interactive() {
  select_toolchain_defined

  # TEST_DIR has no manifest — verify that assumption.
  [[ ! -f "$TEST_DIR/.prospect-manifest.json" ]] \
    || _fail "test setup error: manifest should not exist in fresh TEST_DIR"

  TOOLCHAIN=""
  local result status
  status=0
  # Redirect stdin from /dev/null to guarantee non-interactive (no tty).
  result="$(select_toolchain "$TEST_DIR" 2>/dev/null < /dev/null)" || status=$?

  [[ $status -eq 0 ]] \
    || _fail "select_toolchain exited with status $status in non-interactive mode"

  assert_eq "all" "$result" \
    "select_toolchain should default to 'all' when non-interactive and no manifest" \
    || _fail "expected 'all', got '$result'"
}

# test_select_toolchain_flag_overrides_manifest
#
# FR-2.5 + FR-4.3: A CLI flag must take precedence over manifest defaults.
# If TOOLCHAIN="copilot" but the manifest says ["claude"], the flag wins.
test_select_toolchain_flag_overrides_manifest() {
  select_toolchain_defined

  # Manifest records a prior claude-only install.
  printf '{"version":"v1.0.0","toolchains":["claude"],"files":{}}\n' \
    > "$TEST_DIR/.prospect-manifest.json"

  TOOLCHAIN="copilot"
  local result status
  status=0
  result="$(select_toolchain "$TEST_DIR" 2>/dev/null)" || status=$?

  [[ $status -eq 0 ]] \
    || _fail "select_toolchain exited with status $status when flag overrides manifest"

  assert_eq "copilot" "$result" \
    "CLI flag 'copilot' must override manifest default 'claude'" \
    || _fail "expected 'copilot' (flag wins over manifest), got '$result'"
}

# test_select_toolchain_returns_valid_values
#
# FR-2.1 / FR-2.5: Whatever path is taken, the return value must be one of the
# three defined identifiers: "claude", "copilot", or "all".
# This test exercises the non-interactive, no-manifest, no-flag path and
# validates the contract on the output value.
test_select_toolchain_returns_valid_values() {
  select_toolchain_defined

  TOOLCHAIN=""
  local result status
  status=0
  result="$(select_toolchain "$TEST_DIR" 2>/dev/null < /dev/null)" || status=$?

  [[ $status -eq 0 ]] \
    || _fail "select_toolchain exited with status $status"

  is_valid_toolchain "$result" \
    || _fail "select_toolchain returned '$result'; must be one of: claude, copilot, all"
}

# ── Run ────────────────────────────────────────────────────────────────────────

run_tests
