#!/usr/bin/env bash
# Unit tests for download_release() and _download_artifact() in install.sh
# Task T008 — covers FR-1.1
#
# Tests verify:
#   - download_release extracts release artifact files to dest_dir
#   - download_release cleans up the downloaded tarball after extraction
#   - download_release returns non-zero when _download_artifact fails
#   - download_release returns non-zero when the downloaded file is not a valid archive
#
# RED phase: install.sh does not yet define download_release() or
# _download_artifact(), so all tests fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/setup.bash"

# ── Source install.sh (functions only, no main execution) ──────────────────────
#
# install.sh guards its main block:
#   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi
#
# We neutralise bare `exit [N]` lines before eval'ing, as version_test.sh does.

INSTALL_SH="$SCRIPT_DIR/../../install.sh"

if [[ ! -f "$INSTALL_SH" ]]; then
  echo "NOTE: install.sh not found at $INSTALL_SH" >&2
  echo "  Tests will fail because download_release() is not defined." >&2
else
  _raw="$(cat "$INSTALL_SH")"
  _patched="$(printf '%s\n' "$_raw" \
    | sed 's/^[[:space:]]*exit[[:space:]]*[0-9]*[[:space:]]*$/: # exit neutralised for sourcing/')"
  _PROSPECT_SOURCED=1 eval "$_patched" 2>/dev/null || true
  unset _raw _patched
fi

# ── Internal helpers ────────────────────────────────────────────────────────────

# _fail <message>
# Prints a FAIL message and exits the current subshell with status 1.
_fail() {
  echo "    FAIL: $*" >&2
  exit 1
}

# download_release_defined
# Returns 0 if download_release() is defined, else _fail.
download_release_defined() {
  if ! declare -f download_release > /dev/null 2>&1; then
    _fail "download_release() is not defined in install.sh — implement it first"
  fi
}

# create_mock_tarball <dest_dir> <version>
# Creates a proper release tarball at $dest_dir/prospect-<version>.tar.gz
# using create_mock_artifact from setup.bash, then tars it up.
# Echoes the path to the tarball.
create_mock_tarball() {
  local dest_dir="$1"
  local version="${2:-v1.0.0}"

  # create_mock_artifact populates $dest_dir/prospect-<version>/ and echoes the path
  local artifact_root
  artifact_root="$(create_mock_artifact "$dest_dir" "$version")"

  local tarball="$dest_dir/prospect-${version}.tar.gz"
  # tar the directory itself so extraction produces prospect-<version>/...
  tar -czf "$tarball" -C "$dest_dir" "prospect-${version}"

  # Clean up the source tree; only the tarball is needed hereafter
  rm -rf "$artifact_root"

  echo "$tarball"
}

# ── Tests ──────────────────────────────────────────────────────────────────────

# test_download_release_extracts_to_dest_dir
#
# download_release <version> <dest_dir> must extract the release artifact so
# that expected framework files exist under <dest_dir> after the call.
# We mock _download_artifact to copy a locally created tarball instead of
# hitting the network.
test_download_release_extracts_to_dest_dir() {
  download_release_defined

  local version="v1.0.0"
  local tarball_dir="$TEST_DIR/tarball_staging"
  local dest_dir="$TEST_DIR/install_dest"
  mkdir -p "$tarball_dir" "$dest_dir"

  # Build a real tarball that _download_artifact can "download"
  local mock_tarball
  mock_tarball="$(create_mock_tarball "$tarball_dir" "$version")"

  # Override _download_artifact: copy the local tarball to the requested dest_file
  # shellcheck disable=SC2317
  _download_artifact() {
    local _url="$1"
    local dest_file="$2"
    cp "$mock_tarball" "$dest_file"
  }

  local status=0
  download_release "$version" "$dest_dir" || status=$?

  [[ $status -eq 0 ]] \
    || _fail "download_release exited with status $status; expected 0"

  # Verify representative files are present in dest_dir
  assert_file_exists "$dest_dir/.claude/agents/sdd-architect.md" \
    "claude agents file should be extracted" \
    || _fail ".claude/agents/sdd-architect.md not found after extraction"

  assert_file_exists "$dest_dir/standards/global/code-quality.md" \
    "standards file should be extracted" \
    || _fail "standards/global/code-quality.md not found after extraction"

  assert_dir_exists "$dest_dir/specs/active" \
    "specs/active directory should be extracted" \
    || _fail "specs/active directory not found after extraction"
}

# test_download_release_creates_temp_tarball_and_cleans_up
#
# download_release must not leave the downloaded tarball behind in dest_dir
# or any predictable location after successful extraction.
test_download_release_creates_temp_tarball_and_cleans_up() {
  download_release_defined

  local version="v1.2.3"
  local tarball_dir="$TEST_DIR/tarball_staging"
  local dest_dir="$TEST_DIR/install_dest"
  mkdir -p "$tarball_dir" "$dest_dir"

  local mock_tarball
  mock_tarball="$(create_mock_tarball "$tarball_dir" "$version")"

  # Track the path that _download_artifact writes to
  local captured_dest_file=""
  # shellcheck disable=SC2317
  _download_artifact() {
    local _url="$1"
    local dest_file="$2"
    captured_dest_file="$dest_file"
    cp "$mock_tarball" "$dest_file"
  }

  download_release "$version" "$dest_dir" \
    || _fail "download_release exited non-zero during cleanup test"

  # The tarball that was downloaded must no longer exist
  [[ -n "$captured_dest_file" ]] \
    || _fail "_download_artifact was not called — download_release must invoke it"

  assert_file_not_exists "$captured_dest_file" \
    "downloaded tarball should be removed after extraction" \
    || _fail "tarball '$captured_dest_file' still exists after download_release completed"
}

# test_download_release_fails_on_download_error
#
# When _download_artifact returns non-zero (network error, 404, etc.),
# download_release must:
#   1. Exit with a non-zero status (user-visible failure).
#   2. Print an error message to stderr containing at least one of:
#      error|fail|failed|download|unable.
test_download_release_fails_on_download_error() {
  download_release_defined

  local dest_dir="$TEST_DIR/install_dest"
  mkdir -p "$dest_dir"

  # _download_artifact simulates a network failure
  # shellcheck disable=SC2317
  _download_artifact() {
    echo "simulated download failure" >&2
    return 1
  }

  local output status
  status=0
  output="$(download_release "v1.0.0" "$dest_dir" 2>&1)" || status=$?

  [[ $status -ne 0 ]] \
    || _fail "expected non-zero exit when _download_artifact fails, got status 0"

  local lower
  lower="$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')"

  [[ "$lower" == *"error"*    \
  || "$lower" == *"fail"*     \
  || "$lower" == *"failed"*   \
  || "$lower" == *"download"* \
  || "$lower" == *"unable"* ]] \
    || _fail "stderr must contain a user-friendly word (error|fail|failed|download|unable); got: '$output'"
}

# test_download_release_fails_on_invalid_archive
#
# When _download_artifact succeeds but writes a file that is not a valid
# gzip-compressed tar archive, download_release must return non-zero.
# This guards against truncated downloads or server-side errors that return
# HTML/JSON instead of a tarball.
test_download_release_fails_on_invalid_archive() {
  download_release_defined

  local dest_dir="$TEST_DIR/install_dest"
  mkdir -p "$dest_dir"

  # _download_artifact writes garbage (not a valid tarball)
  # shellcheck disable=SC2317
  _download_artifact() {
    local _url="$1"
    local dest_file="$2"
    printf '<!DOCTYPE html><html><body>Not Found</body></html>\n' > "$dest_file"
  }

  local status=0
  download_release "v1.0.0" "$dest_dir" 2>/dev/null || status=$?

  [[ $status -ne 0 ]] \
    || _fail "expected non-zero exit when archive is not a valid tarball, got status 0"
}

# ── Run ────────────────────────────────────────────────────────────────────────

run_tests
