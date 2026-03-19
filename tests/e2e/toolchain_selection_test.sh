#!/usr/bin/env bash
# E2E test: toolchain selection produces correct file sets — T032
#
# Covers:
#   FR-2.2 — Claude Code toolchain installs .claude/ files, not .github/ files
#   FR-2.3 — Copilot toolchain installs .github/ files, not .claude/ files
#   FR-2.4 — shared files installed regardless of toolchain selection
#
# Strategy:
#   Build a real release artifact, then run install_files with each toolchain
#   flag and verify the resulting file tree.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../helpers/setup.bash"

BUILD_SCRIPT="$REPO_ROOT/scripts/build-release.sh"
INSTALL_SH="$REPO_ROOT/install.sh"

# ── Internal helpers ──────────────────────────────────────────────────────────

_fail() {
  echo "    FAIL: $*" >&2
  exit 1
}

# _build_real_artifact <version> <dest_dir>
_build_real_artifact() {
  local version="$1"
  local dest_dir="$2"

  local log="$dest_dir/build.log"
  (cd "$dest_dir" && bash "$BUILD_SCRIPT" "$version") >"$log" 2>&1 || {
    echo "    FAIL: build-release.sh failed — $(cat "$log")" >&2
    exit 1
  }

  local tarball
  tarball="$(grep '\.tar\.gz' "$log" | tail -1 | tr -d '[:space:]')"
  if [[ -z "$tarball" || ! -f "$tarball" ]]; then
    _fail "build-release.sh did not produce a .tar.gz"
  fi
  echo "$tarball"
}

# _source_install_sh
_source_install_sh() {
  local raw patched
  raw="$(cat "$INSTALL_SH")"
  patched="$(printf '%s\n' "$raw" \
    | sed 's/^[[:space:]]*exit[[:space:]]*[0-9]*[[:space:]]*$/: # exit neutralised/')"
  eval "$patched" 2>/dev/null || true
}

# _extract_artifact <tarball> <version> <extract_dir>
_extract_artifact() {
  local tarball="$1"
  local version="$2"
  local extract_dir="$3"

  tar -xzf "$tarball" -C "$extract_dir"
  local source_dir="$extract_dir/prospect-${version}"
  [[ -d "$source_dir" ]] || source_dir="$extract_dir"
  echo "$source_dir"
}

# ── Tests ─────────────────────────────────────────────────────────────────────

# test_e2e_toolchain_claude_only_has_no_github_files
#
# Installing with --claude must produce .claude/ files and shared files,
# but no .github/ files (FR-2.2).
test_e2e_toolchain_claude_only_has_no_github_files() {
  local build_dir="$TEST_DIR/build"
  local target_dir="$TEST_DIR/target"
  local extract_dir="$TEST_DIR/extract"
  mkdir -p "$build_dir" "$target_dir" "$extract_dir"

  _source_install_sh

  local tarball
  tarball="$(_build_real_artifact "v1.0.0" "$build_dir")"
  local source_dir
  source_dir="$(_extract_artifact "$tarball" "v1.0.0" "$extract_dir")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "claude" \
    || _fail "E2E: install_files (claude) exited non-zero"

  # Claude files must be present.
  assert_dir_exists "$target_dir/.claude" \
    || _fail "E2E: .claude/ directory not present for claude toolchain"

  # Shared files must be present.
  assert_dir_exists "$target_dir/standards/global" \
    || _fail "E2E: standards/global/ not present for claude toolchain"
  assert_file_exists "$target_dir/CLAUDE.md" \
    || _fail "E2E: CLAUDE.md not present for claude toolchain"

  # .github/ files (Copilot-only) must NOT be present.
  if [[ -d "$target_dir/.github/agents" ]]; then
    local agent_count
    agent_count="$(find "$target_dir/.github/agents" -type f 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$agent_count" -eq 0 ]] \
      || _fail "E2E: .github/agents/ files present for claude-only toolchain ($agent_count file(s))"
  fi
  if [[ -d "$target_dir/.github/prompts" ]]; then
    local prompt_count
    prompt_count="$(find "$target_dir/.github/prompts" -type f 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$prompt_count" -eq 0 ]] \
      || _fail "E2E: .github/prompts/ files present for claude-only toolchain ($prompt_count file(s))"
  fi
  if [[ -d "$target_dir/.github/instructions" ]]; then
    local instr_count
    instr_count="$(find "$target_dir/.github/instructions" -type f 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$instr_count" -eq 0 ]] \
      || _fail "E2E: .github/instructions/ files present for claude-only toolchain ($instr_count file(s))"
  fi
}

# test_e2e_toolchain_copilot_only_has_no_claude_files
#
# Installing with --copilot must produce .github/ files and shared files,
# but no .claude/ files (FR-2.3).
test_e2e_toolchain_copilot_only_has_no_claude_files() {
  local build_dir="$TEST_DIR/build"
  local target_dir="$TEST_DIR/target"
  local extract_dir="$TEST_DIR/extract"
  mkdir -p "$build_dir" "$target_dir" "$extract_dir"

  _source_install_sh

  local tarball
  tarball="$(_build_real_artifact "v1.0.0" "$build_dir")"
  local source_dir
  source_dir="$(_extract_artifact "$tarball" "v1.0.0" "$extract_dir")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "copilot" \
    || _fail "E2E: install_files (copilot) exited non-zero"

  # Shared files must be present.
  assert_dir_exists "$target_dir/standards/global" \
    || _fail "E2E: standards/global/ not present for copilot toolchain"

  # CLAUDE.md must NOT be installed for copilot-only (FR-2.3).
  assert_file_not_exists "$target_dir/CLAUDE.md" \
    || _fail "E2E: CLAUDE.md present for copilot-only toolchain"

  # .claude/ files must NOT be present.
  if [[ -d "$target_dir/.claude/agents" ]]; then
    local agent_count
    agent_count="$(find "$target_dir/.claude/agents" -type f 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$agent_count" -eq 0 ]] \
      || _fail "E2E: .claude/agents/ files present for copilot-only toolchain ($agent_count file(s))"
  fi
  if [[ -d "$target_dir/.claude/skills" ]]; then
    local skill_count
    skill_count="$(find "$target_dir/.claude/skills" -type f 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$skill_count" -eq 0 ]] \
      || _fail "E2E: .claude/skills/ files present for copilot-only toolchain ($skill_count file(s))"
  fi
}

# test_e2e_toolchain_all_has_both_file_sets
#
# Installing with --all must produce both .claude/ and .github/ files along
# with shared files (FR-2.4).
test_e2e_toolchain_all_has_both_file_sets() {
  local build_dir="$TEST_DIR/build"
  local target_dir="$TEST_DIR/target"
  local extract_dir="$TEST_DIR/extract"
  mkdir -p "$build_dir" "$target_dir" "$extract_dir"

  _source_install_sh

  local tarball
  tarball="$(_build_real_artifact "v1.0.0" "$build_dir")"
  local source_dir
  source_dir="$(_extract_artifact "$tarball" "v1.0.0" "$extract_dir")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "all" \
    || _fail "E2E: install_files (all) exited non-zero"

  # Claude files.
  assert_dir_exists "$target_dir/.claude" \
    || _fail "E2E: .claude/ not present for all toolchain"

  # Copilot files — check directory if it exists in the artifact.
  if [[ -d "$source_dir/.github/agents" ]]; then
    assert_dir_exists "$target_dir/.github/agents" \
      || _fail "E2E: .github/agents/ not present for all toolchain"
  fi

  # Shared files.
  assert_dir_exists "$target_dir/standards/global" \
    || _fail "E2E: standards/global/ not present for all toolchain"
  assert_file_exists "$target_dir/CLAUDE.md" \
    || _fail "E2E: CLAUDE.md not present for all toolchain"
}

# test_e2e_toolchain_shared_dirs_always_created
#
# Regardless of toolchain selection, the empty directory structure must exist
# after install (FR-2.4, FR-5.4).
test_e2e_toolchain_shared_dirs_always_created() {
  local build_dir="$TEST_DIR/build"
  local extract_dir="$TEST_DIR/extract"
  mkdir -p "$build_dir" "$extract_dir"

  _source_install_sh

  local tarball
  tarball="$(_build_real_artifact "v1.0.0" "$build_dir")"
  local source_dir
  source_dir="$(_extract_artifact "$tarball" "v1.0.0" "$extract_dir")"

  for toolchain in claude copilot all; do
    local target_dir="$TEST_DIR/target_${toolchain}"
    mkdir -p "$target_dir"

    install_files "$source_dir" "$target_dir" "v1.0.0" "$toolchain" \
      || _fail "E2E: install_files ($toolchain) exited non-zero"

    assert_dir_exists "$target_dir/specs/active" \
      || _fail "E2E: specs/active/ not created for toolchain=$toolchain"
    assert_dir_exists "$target_dir/specs/implemented" \
      || _fail "E2E: specs/implemented/ not created for toolchain=$toolchain"
    assert_dir_exists "$target_dir/product" \
      || _fail "E2E: product/ not created for toolchain=$toolchain"
  done
}

# ── Run ───────────────────────────────────────────────────────────────────────

run_tests
