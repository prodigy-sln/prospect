#!/usr/bin/env bash
# E2E test: fresh install via bash into an empty directory — T030
#
# Covers:
#   FR-1.1 — bash script works in standard environments
#   FR-1.3 — all expected files present after install
#   FR-3.1 — first install copies all files without conflict checks
#   FR-4.1 — .prospect-version written
#   FR-4.2 — .prospect-manifest.json written with correct structure
#   FR-5.4 — empty directories created (specs/active/, specs/implemented/, product/)
#
# Strategy:
#   Build a real release artifact at script load time using build-release.sh.
#   Source install.sh at top level (so functions are inherited by test subshells),
#   then override _download_artifact via an exported env var to serve the local
#   tarball.  Each test exercises install_files() against real artifact content.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../helpers/setup.bash"

BUILD_SCRIPT="$REPO_ROOT/scripts/build-release.sh"
INSTALL_SH="$REPO_ROOT/install.sh"

# ── Build a real artifact once at script load time ────────────────────────────

_E2E_BUILD_DIR="$(mktemp -d)"
trap "rm -rf '$_E2E_BUILD_DIR'" EXIT

_E2E_TARBALL=""
(cd "$_E2E_BUILD_DIR" && bash "$BUILD_SCRIPT" "v1.0.0") \
  >"$_E2E_BUILD_DIR/build-out.log" \
  2>"$_E2E_BUILD_DIR/build-err.log" \
  || {
    echo "FATAL: build-release.sh failed at E2E setup" >&2
    cat "$_E2E_BUILD_DIR/build-err.log" >&2
    exit 1
  }

_E2E_TARBALL="$(grep '\.tar\.gz' "$_E2E_BUILD_DIR/build-out.log" | head -1 | tr -d '[:space:]')"
if [[ -z "$_E2E_TARBALL" || ! -f "$_E2E_TARBALL" ]]; then
  echo "FATAL: build-release.sh did not produce a tarball" >&2
  echo "  stdout: $(cat "$_E2E_BUILD_DIR/build-out.log")" >&2
  echo "  stderr: $(cat "$_E2E_BUILD_DIR/build-err.log")" >&2
  exit 1
fi

export E2E_TARBALL_V1="$_E2E_TARBALL"

# ── Source install.sh at top level (functions inherited by run_tests subshells)

_raw_install="$(cat "$INSTALL_SH")"
_patched_install="$(printf '%s\n' "$_raw_install" \
  | sed 's/^[[:space:]]*exit[[:space:]]*[0-9]*[[:space:]]*$/: # exit neutralised/')"
_PROSPECT_SOURCED=1 eval "$_patched_install" 2>/dev/null || true
unset _raw_install _patched_install

# Override _download_artifact to serve the pre-built local tarball.
# Uses the exported E2E_TARBALL_V1 variable (set before each test as needed).
_download_artifact() {
  # $1 = remote URL (ignored), $2 = destination file
  cp "$E2E_TARBALL_V1" "$2"
}

# ── Internal helpers ──────────────────────────────────────────────────────────

_fail() {
  echo "    FAIL: $*" >&2
  exit 1
}

# _run_fresh_install <target_dir> <version> <toolchain>
# Extracts the tarball to a temp dir and calls install_files.
_run_fresh_install() {
  local target_dir="$1"
  local version="$2"
  local toolchain="$3"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  # Note: no trap here — caller is responsible for cleanup or we rely on TEST_DIR cleanup.
  download_release "$version" "$tmp_dir"
  local source_dir="$tmp_dir/prospect-${version}"
  [[ -d "$source_dir" ]] || source_dir="$tmp_dir"

  install_files "$source_dir" "$target_dir" "$version" "$toolchain"
  rm -rf "$tmp_dir"
}

# ── Tests ─────────────────────────────────────────────────────────────────────

# test_e2e_fresh_install_all_files_present
#
# Run a fresh install with toolchain=all into an empty directory and verify
# that all expected files are present (FR-1.1, FR-1.3, FR-3.1).
test_e2e_fresh_install_all_files_present() {
  local target_dir="$TEST_DIR/target"
  mkdir -p "$target_dir"

  _run_fresh_install "$target_dir" "v1.0.0" "all" \
    || _fail "install_files exited non-zero on E2E fresh install"

  # ── Claude toolchain files ──
  assert_dir_exists "$target_dir/.claude" \
    || _fail "E2E: .claude/ directory not present"

  # ── Shared/standards files ──
  assert_file_exists "$target_dir/standards/global/code-quality.md" \
    || _fail "E2E: standards/global/code-quality.md not present"
  assert_file_exists "$target_dir/standards/global/testing.md" \
    || _fail "E2E: standards/global/testing.md not present"
  assert_file_exists "$target_dir/standards/global/git-workflow.md" \
    || _fail "E2E: standards/global/git-workflow.md not present"

  # ── Spec templates ──
  assert_dir_exists "$target_dir/specs/_templates" \
    || _fail "E2E: specs/_templates/ not present"

  # ── Product templates ──
  assert_file_exists "$target_dir/product/mission.template.md" \
    || _fail "E2E: product/mission.template.md not present"
  assert_file_exists "$target_dir/product/roadmap.template.md" \
    || _fail "E2E: product/roadmap.template.md not present"

  # ── CLAUDE.md ──
  assert_file_exists "$target_dir/CLAUDE.md" \
    || _fail "E2E: CLAUDE.md not present"
}

# test_e2e_fresh_install_version_file_correct
#
# After a fresh install, .prospect-version must contain exactly the installed
# version tag (FR-4.1).
test_e2e_fresh_install_version_file_correct() {
  local target_dir="$TEST_DIR/target"
  mkdir -p "$target_dir"

  _run_fresh_install "$target_dir" "v1.0.0" "all" \
    || _fail "install_files exited non-zero"

  assert_file_exists "$target_dir/.prospect-version" \
    || _fail "E2E: .prospect-version not created"
  assert_file_contains "$target_dir/.prospect-version" "v1.0.0" \
    || _fail "E2E: .prospect-version does not contain 'v1.0.0'"
}

# test_e2e_fresh_install_manifest_correct
#
# After a fresh install, .prospect-manifest.json must contain the version,
# toolchains, and files fields (FR-4.2).
test_e2e_fresh_install_manifest_correct() {
  local target_dir="$TEST_DIR/target"
  mkdir -p "$target_dir"

  _run_fresh_install "$target_dir" "v1.0.0" "all" \
    || _fail "install_files exited non-zero"

  assert_file_exists "$target_dir/.prospect-manifest.json" \
    || _fail "E2E: .prospect-manifest.json not created"
  assert_file_contains "$target_dir/.prospect-manifest.json" '"version"' \
    || _fail "E2E: manifest missing 'version' field"
  assert_file_contains "$target_dir/.prospect-manifest.json" "v1.0.0" \
    || _fail "E2E: manifest version value mismatch"
  assert_file_contains "$target_dir/.prospect-manifest.json" '"toolchains"' \
    || _fail "E2E: manifest missing 'toolchains' field"
  assert_file_contains "$target_dir/.prospect-manifest.json" '"files"' \
    || _fail "E2E: manifest missing 'files' field"
}

# test_e2e_fresh_install_directories_created
#
# After a fresh install, the empty directory markers must exist (FR-5.4).
test_e2e_fresh_install_directories_created() {
  local target_dir="$TEST_DIR/target"
  mkdir -p "$target_dir"

  _run_fresh_install "$target_dir" "v1.0.0" "all" \
    || _fail "install_files exited non-zero"

  assert_dir_exists "$target_dir/specs/active" \
    || _fail "E2E: specs/active/ directory not created"
  assert_dir_exists "$target_dir/specs/implemented" \
    || _fail "E2E: specs/implemented/ directory not created"
  assert_dir_exists "$target_dir/product" \
    || _fail "E2E: product/ directory not created"
}

# ── Run ───────────────────────────────────────────────────────────────────────

run_tests
