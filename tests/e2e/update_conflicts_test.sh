#!/usr/bin/env bash
# E2E test: update with conflicts via bash — T031
#
# Covers:
#   FR-3.2 — unmodified files are overwritten silently on update
#   FR-3.3 — modified files get .prospect-incoming treatment
#   FR-3.4 — conflict summary printed
#   FR-5.3 — user content in specs/active/ is never touched
#
# Strategy:
#   Build two real release artifacts (v1.0.0 and v2.0.0) at top level using
#   build-release.sh.  Source install.sh at top level.  Each test:
#     1. Does a fresh install of v1.0.0.
#     2. Optionally modifies files or adds user content.
#     3. Updates to v2.0.0 and verifies the outcome.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../helpers/setup.bash"

BUILD_SCRIPT="$REPO_ROOT/scripts/build-release.sh"
INSTALL_SH="$REPO_ROOT/install.sh"

# ── Build v1 and v2 artifacts at script load time ─────────────────────────────

_E2E_BUILD_DIR="$(mktemp -d)"
trap "rm -rf '$_E2E_BUILD_DIR'" EXIT

# Build v1.
(cd "$_E2E_BUILD_DIR" && bash "$BUILD_SCRIPT" "v1.0.0") \
  >"$_E2E_BUILD_DIR/v1-out.log" 2>"$_E2E_BUILD_DIR/v1-err.log" \
  || { echo "FATAL: build v1.0.0 failed" >&2; cat "$_E2E_BUILD_DIR/v1-err.log" >&2; exit 1; }
E2E_TARBALL_V1="$(grep '\.tar\.gz' "$_E2E_BUILD_DIR/v1-out.log" | head -1 | tr -d '[:space:]')"
if [[ -z "$E2E_TARBALL_V1" || ! -f "$E2E_TARBALL_V1" ]]; then
  echo "FATAL: build v1.0.0 did not produce a tarball" >&2; exit 1
fi
export E2E_TARBALL_V1

# Build v2.
(cd "$_E2E_BUILD_DIR" && bash "$BUILD_SCRIPT" "v2.0.0") \
  >"$_E2E_BUILD_DIR/v2-out.log" 2>"$_E2E_BUILD_DIR/v2-err.log" \
  || { echo "FATAL: build v2.0.0 failed" >&2; cat "$_E2E_BUILD_DIR/v2-err.log" >&2; exit 1; }
E2E_TARBALL_V2="$(grep '\.tar\.gz' "$_E2E_BUILD_DIR/v2-out.log" | head -1 | tr -d '[:space:]')"
if [[ -z "$E2E_TARBALL_V2" || ! -f "$E2E_TARBALL_V2" ]]; then
  echo "FATAL: build v2.0.0 did not produce a tarball" >&2; exit 1
fi
export E2E_TARBALL_V2

# ── Source install.sh at top level ────────────────────────────────────────────

_raw="$(cat "$INSTALL_SH")"
_patched="$(printf '%s\n' "$_raw" \
  | sed 's/^[[:space:]]*exit[[:space:]]*[0-9]*[[:space:]]*$/: # exit neutralised/')"
_PROSPECT_SOURCED=1 eval "$_patched" 2>/dev/null || true
unset _raw _patched

# Default _download_artifact override (may be changed per-test via E2E_TARBALL_V1/V2).
_download_artifact() {
  cp "${_E2E_CURRENT_TARBALL:-$E2E_TARBALL_V1}" "$2"
}

# ── Internal helpers ──────────────────────────────────────────────────────────

_fail() {
  echo "    FAIL: $*" >&2
  exit 1
}

# _install_version <target_dir> <tarball> <version> <toolchain>
# Extracts the given tarball and calls install_files against target_dir.
_install_version() {
  local target_dir="$1"
  local tarball="$2"
  local version="$3"
  local toolchain="$4"

  export _E2E_CURRENT_TARBALL="$tarball"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  download_release "$version" "$tmp_dir"
  local source_dir="$tmp_dir/prospect-${version}"
  [[ -d "$source_dir" ]] || source_dir="$tmp_dir"

  # Copy extracted source to a mutable staging dir so we can mutate v2 content.
  local stage_dir="$tmp_dir/stage"
  cp -a "$source_dir" "$stage_dir"

  # Export so callers can mutate files before install.
  export _E2E_STAGE_DIR="$stage_dir"

  install_files "$stage_dir" "$target_dir" "$version" "$toolchain"

  rm -rf "$tmp_dir"
  unset _E2E_CURRENT_TARBALL
}

# ── Tests ─────────────────────────────────────────────────────────────────────

# test_e2e_update_modified_standards_creates_incoming
#
# Scenario: user modifies standards/global/code-quality.md after v1 install.
# On update to v2, the file must get .prospect-incoming treatment (FR-3.3).
# The user's modified version must be preserved (FR-3.2 / FR-3.3).
test_e2e_update_modified_standards_creates_incoming() {
  local target_dir="$TEST_DIR/target"
  mkdir -p "$target_dir"

  # Fresh install v1.
  _install_version "$target_dir" "$E2E_TARBALL_V1" "v1.0.0" "all" \
    || _fail "fresh install v1.0.0 exited non-zero"

  # Simulate user modifying a standards file.
  printf '\n# My custom addition\n' >> "$target_dir/standards/global/code-quality.md"

  # Update to v2 — the v2 tarball has the same content as v1 for this file,
  # so there is no "new incoming content" difference.  To ensure the conflict
  # fires we need the v2 source file to differ from the v1 manifest checksum.
  # We do this by appending a marker to the v2 artifact's standards file via
  # the staging hook in _install_version.
  export _E2E_CURRENT_TARBALL="$E2E_TARBALL_V2"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  download_release "v2.0.0" "$tmp_dir"
  local source_v2="$tmp_dir/prospect-v2.0.0"
  [[ -d "$source_v2" ]] || source_v2="$tmp_dir"

  # Mutate the v2 standards file so it differs from v1's content.
  printf '\n# Framework update marker for v2\n' >> "$source_v2/standards/global/code-quality.md"

  local output
  output="$(install_files "$source_v2" "$target_dir" "v2.0.0" "all" 2>&1)" \
    || _fail "update to v2.0.0 exited non-zero"
  rm -rf "$tmp_dir"

  # .prospect-incoming must be created for the modified standards file.
  assert_file_exists \
    "$target_dir/standards/global/code-quality.md.prospect-incoming" \
    || _fail "E2E: .prospect-incoming not created for modified standards file"

  # User's modification must be preserved in the original.
  assert_file_contains \
    "$target_dir/standards/global/code-quality.md" \
    "My custom addition" \
    || _fail "E2E: user's modified standards file was overwritten"

  # Output must reference the conflict.
  local lower
  lower="$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')"
  [[ "$lower" == *"prospect-incoming"* \
  || "$lower" == *"conflict"* \
  || "$lower" == *"incoming"* ]] \
    || _fail "E2E: conflict summary not printed; output was: $output"
}

# test_e2e_update_unmodified_files_overwritten
#
# Files that the user has NOT modified must be silently overwritten with the
# new version (FR-3.2). No .prospect-incoming should appear for them.
test_e2e_update_unmodified_files_overwritten() {
  local target_dir="$TEST_DIR/target"
  mkdir -p "$target_dir"

  # Fresh install v1.
  export _E2E_CURRENT_TARBALL="$E2E_TARBALL_V1"
  local tmp_v1; tmp_v1="$(mktemp -d)"
  download_release "v1.0.0" "$tmp_v1"
  local source_v1="$tmp_v1/prospect-v1.0.0"
  [[ -d "$source_v1" ]] || source_v1="$tmp_v1"
  install_files "$source_v1" "$target_dir" "v1.0.0" "all" \
    || _fail "fresh install v1.0.0 exited non-zero"
  rm -rf "$tmp_v1"

  # Build v2 source and mutate an UNMODIFIED framework file.
  export _E2E_CURRENT_TARBALL="$E2E_TARBALL_V2"
  local tmp_v2; tmp_v2="$(mktemp -d)"
  download_release "v2.0.0" "$tmp_v2"
  local source_v2="$tmp_v2/prospect-v2.0.0"
  [[ -d "$source_v2" ]] || source_v2="$tmp_v2"

  # Pick any .md file under .claude/agents/ and add a v2 marker.
  local agent_file rel_path
  agent_file="$(find "$source_v2/.claude/agents" -name '*.md' 2>/dev/null | head -1 || true)"
  if [[ -z "$agent_file" ]]; then
    agent_file="$(find "$source_v2/.claude" -name '*.md' 2>/dev/null | head -1 || true)"
  fi

  if [[ -n "$agent_file" ]]; then
    rel_path="${agent_file#$source_v2/}"
    printf '\n# v2 update marker\n' >> "$agent_file"

    install_files "$source_v2" "$target_dir" "v2.0.0" "all" \
      || _fail "update to v2.0.0 exited non-zero"
    rm -rf "$tmp_v2"

    # The unmodified file must now contain the v2 marker.
    assert_file_contains "$target_dir/$rel_path" "v2 update marker" \
      || _fail "E2E: unmodified framework file was not overwritten with v2 content"

    # No .prospect-incoming for an unmodified file.
    assert_file_not_exists "$target_dir/${rel_path}.prospect-incoming" \
      || _fail "E2E: .prospect-incoming created for an unmodified file"
  else
    # No agent files in artifact; still pass since there's nothing to test.
    rm -rf "$tmp_v2"
  fi
}

# test_e2e_update_user_content_untouched
#
# Files under specs/active/ that the user created must survive the update
# completely unchanged (FR-5.3).
test_e2e_update_user_content_untouched() {
  local target_dir="$TEST_DIR/target"
  mkdir -p "$target_dir"

  # Fresh install v1.
  export _E2E_CURRENT_TARBALL="$E2E_TARBALL_V1"
  local tmp_v1; tmp_v1="$(mktemp -d)"
  download_release "v1.0.0" "$tmp_v1"
  local source_v1="$tmp_v1/prospect-v1.0.0"
  [[ -d "$source_v1" ]] || source_v1="$tmp_v1"
  install_files "$source_v1" "$target_dir" "v1.0.0" "all" \
    || _fail "fresh install v1.0.0 exited non-zero"
  rm -rf "$tmp_v1"

  # Create user content in specs/active/ after install.
  mkdir -p "$target_dir/specs/active/my-feature"
  echo "# My feature spec — do not touch" > "$target_dir/specs/active/my-feature/spec.md"

  # Update to v2.
  export _E2E_CURRENT_TARBALL="$E2E_TARBALL_V2"
  local tmp_v2; tmp_v2="$(mktemp -d)"
  download_release "v2.0.0" "$tmp_v2"
  local source_v2="$tmp_v2/prospect-v2.0.0"
  [[ -d "$source_v2" ]] || source_v2="$tmp_v2"
  install_files "$source_v2" "$target_dir" "v2.0.0" "all" \
    || _fail "update to v2.0.0 exited non-zero"
  rm -rf "$tmp_v2"

  # User content must survive.
  assert_file_exists "$target_dir/specs/active/my-feature/spec.md" \
    || _fail "E2E: user file in specs/active/ was deleted on update"
  assert_file_contains "$target_dir/specs/active/my-feature/spec.md" "do not touch" \
    || _fail "E2E: user file in specs/active/ content was altered on update"
}

# ── Run ───────────────────────────────────────────────────────────────────────

run_tests
