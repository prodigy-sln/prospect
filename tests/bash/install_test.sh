#!/usr/bin/env bash
# Unit tests for install_files() in install.sh
#
# Covers:
#   FR-3.1 — fresh install copies all selected files without conflict checks
#   FR-3.2 — on update, unmodified files are overwritten silently
#   FR-3.3 — on update, modified files get .prospect-incoming treatment
#   FR-3.4 — summary of conflicts printed after all files are processed
#   FR-3.5 — existing copilot-instructions.md with non-Prospect content triggers notification
#   FR-4.1 — .prospect-version created after install
#   FR-4.2 — .prospect-manifest.json created with per-file checksums
#   FR-5.3 — user-created content (specs/active/*, product/mission.md) never touched
#   FR-5.4 — empty directories (specs/active/, specs/implemented/, product/) created
#   FR-6.1 — script never deletes files it did not install
#   FR-6.2 — pre-existing non-Prospect .github/ content survives install
#   FR-7.1 — non-git directory prints warning but succeeds
#   FR-7.3 — idempotent: second run with same version produces no errors
#   FR-2.2 — claude-only toolchain installs only .claude/* and shared files
#   FR-2.3 — copilot-only toolchain installs only .github/* and shared files
#
# Task: T014 [TEST] [SCRIPT] Write tests for fresh install and conflict detection
#
# RED phase: install_files() is not yet defined in install.sh, so all tests fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/setup.bash"

# ── Source install.sh (functions only, no main execution) ──────────────────────
#
# install.sh guards its main block with:
#   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi
#
# Bare `exit` lines (stub guards) would kill the sourcing shell, so we
# neutralise them before eval'ing — the same pattern used by version_test.sh.

INSTALL_SH="$SCRIPT_DIR/../../install.sh"

if [[ ! -f "$INSTALL_SH" ]]; then
  echo "NOTE: install.sh not found at $INSTALL_SH" >&2
  echo "  Tests will fail because install_files() is not defined." >&2
else
  _raw="$(cat "$INSTALL_SH")"
  _patched="$(printf '%s\n' "$_raw" \
    | sed 's/^[[:space:]]*exit[[:space:]]*[0-9]*[[:space:]]*$/: # exit neutralised for sourcing/')"
  _PROSPECT_SOURCED=1 eval "$_patched" 2>/dev/null || true
  unset _raw _patched
fi

# ── Internal helpers ───────────────────────────────────────────────────────────

# _fail <message>
# Prints a FAIL message and exits the current (sub)shell with status 1.
# Using exit rather than return because run_tests wraps each test in a
# subshell via `if ( ... )`, which disables set -e for return values.
_fail() {
  echo "    FAIL: $*" >&2
  exit 1
}

# _require_function <name>
# Exits with a clear message if the function is not yet defined in install.sh.
_require_function() {
  local fn="$1"
  declare -f "$fn" > /dev/null 2>&1 \
    || _fail "$fn() is not defined in install.sh — implement it first"
}

# _make_target_git_repo <dir>
# Initialises a minimal .git directory inside <dir> so the installer
# considers it a git repository.
_make_target_git_repo() {
  local dir="$1"
  mkdir -p "$dir/.git"
}

# _artifact_root <dest_dir> <version>
# Returns the path to the root directory inside the mock artifact.
_artifact_root() {
  local dest_dir="$1"
  local version="$2"
  echo "$dest_dir/prospect-${version}"
}

# ── Tests: install_files function defined ─────────────────────────────────────

# test_install_files_function_is_defined
#
# The most basic requirement: install.sh must define install_files().
# This gives a clear, actionable failure message in the RED phase.
test_install_files_function_is_defined() {
  declare -f install_files > /dev/null 2>&1 \
    || _fail "install_files() is not defined in install.sh"
}

# ── Tests: FR-3.1 — fresh install ─────────────────────────────────────────────

# test_fresh_install_copies_all_files
#
# On first install (no .prospect-manifest.json), all files from the source
# artifact that are within the selected toolchain must be copied to target_dir
# (FR-3.1).
test_fresh_install_copies_all_files() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "all" \
    || _fail "install_files exited non-zero on fresh install"

  # Spot-check files from each toolchain and shared files.
  assert_file_exists "$target_dir/.claude/agents/sdd-architect.md" \
    || _fail ".claude/agents/sdd-architect.md must be installed"

  assert_file_exists "$target_dir/.claude/skills/sdd-start/SKILL.md" \
    || _fail ".claude/skills/sdd-start/SKILL.md must be installed"

  assert_file_exists "$target_dir/.github/agents/sdd-start.agent.md" \
    || _fail ".github/agents/sdd-start.agent.md must be installed"

  assert_file_exists "$target_dir/.github/copilot-instructions.md" \
    || _fail ".github/copilot-instructions.md must be installed"

  assert_file_exists "$target_dir/standards/global/code-quality.md" \
    || _fail "standards/global/code-quality.md must be installed"

  assert_file_exists "$target_dir/CLAUDE.md" \
    || _fail "CLAUDE.md must be installed"

  assert_file_exists "$target_dir/specs/_templates/spec.template.md" \
    || _fail "specs/_templates/spec.template.md must be installed"

  assert_file_exists "$target_dir/product/mission.template.md" \
    || _fail "product/mission.template.md must be installed"
}

# ── Tests: FR-4.1, FR-4.2 — manifest and version file after fresh install ─────

# test_fresh_install_creates_manifest_and_version
#
# After a fresh install, .prospect-manifest.json and .prospect-version must
# both exist in target_dir with correct content (FR-4.1, FR-4.2).
test_fresh_install_creates_manifest_and_version() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "all" \
    || _fail "install_files exited non-zero"

  assert_file_exists "$target_dir/.prospect-manifest.json" \
    || _fail ".prospect-manifest.json must be created after fresh install"

  assert_file_exists "$target_dir/.prospect-version" \
    || _fail ".prospect-version must be created after fresh install"

  assert_file_contains "$target_dir/.prospect-version" "v1.0.0" \
    || _fail ".prospect-version must contain 'v1.0.0'"

  assert_file_contains "$target_dir/.prospect-manifest.json" '"version"' \
    || _fail ".prospect-manifest.json must contain a version field"

  assert_file_contains "$target_dir/.prospect-manifest.json" "v1.0.0" \
    || _fail ".prospect-manifest.json must record the installed version"

  assert_file_contains "$target_dir/.prospect-manifest.json" '"files"' \
    || _fail ".prospect-manifest.json must contain a files field"
}

# ── Tests: FR-5.4 — empty directories created ─────────────────────────────────

# test_fresh_install_creates_empty_directories
#
# install_files must create specs/active/, specs/implemented/, and product/
# in target_dir regardless of whether they contain files (FR-5.4).
test_fresh_install_creates_empty_directories() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "all" \
    || _fail "install_files exited non-zero"

  assert_dir_exists "$target_dir/specs/active" \
    || _fail "specs/active/ directory must exist after install"

  assert_dir_exists "$target_dir/specs/implemented" \
    || _fail "specs/implemented/ directory must exist after install"

  assert_dir_exists "$target_dir/product" \
    || _fail "product/ directory must exist after install"
}

# ── Tests: FR-3.2 — update overwrites unmodified files ────────────────────────

# test_update_overwrites_unmodified_files
#
# On update, a file whose current checksum matches the manifest-recorded
# checksum (i.e. the user has not modified it) must be silently overwritten
# with the new version (FR-3.2).
test_update_overwrites_unmodified_files() {
  _require_function install_files

  local artifact_v1="$TEST_DIR/artifact_v1"
  local artifact_v2="$TEST_DIR/artifact_v2"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_v1" "$artifact_v2" "$target_dir"
  _make_target_git_repo "$target_dir"

  # Fresh install with v1.0.0.
  create_mock_artifact "$artifact_v1" "v1.0.0"
  local source_v1
  source_v1="$(_artifact_root "$artifact_v1" "v1.0.0")"

  install_files "$source_v1" "$target_dir" "v1.0.0" "all" \
    || _fail "fresh install (v1.0.0) exited non-zero"

  # Prepare v2.0.0 artifact with updated content for a framework file.
  create_mock_artifact "$artifact_v2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$artifact_v2" "v2.0.0")"
  echo "# Architect Agent v2" > "$source_v2/.claude/agents/sdd-architect.md"

  install_files "$source_v2" "$target_dir" "v2.0.0" "all" \
    || _fail "update install (v2.0.0) exited non-zero"

  # The unmodified file must now reflect the v2 content.
  assert_file_contains "$target_dir/.claude/agents/sdd-architect.md" "v2" \
    || _fail "unmodified framework file must be overwritten with v2 content"

  # No .prospect-incoming for an unmodified file.
  assert_file_not_exists "$target_dir/.claude/agents/sdd-architect.md.prospect-incoming" \
    || _fail ".prospect-incoming must NOT be created for an unmodified file"
}

# ── Tests: FR-3.3 — update creates .prospect-incoming for modified files ───────

# test_update_creates_incoming_for_modified_files
#
# When a user has modified a framework file since the last install,
# install_files must write the new version as <file>.prospect-incoming
# and leave the user's version intact (FR-3.3).
test_update_creates_incoming_for_modified_files() {
  _require_function install_files

  local artifact_v1="$TEST_DIR/artifact_v1"
  local artifact_v2="$TEST_DIR/artifact_v2"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_v1" "$artifact_v2" "$target_dir"
  _make_target_git_repo "$target_dir"

  # Fresh install with v1.0.0.
  create_mock_artifact "$artifact_v1" "v1.0.0"
  local source_v1
  source_v1="$(_artifact_root "$artifact_v1" "v1.0.0")"

  install_files "$source_v1" "$target_dir" "v1.0.0" "all" \
    || _fail "fresh install (v1.0.0) exited non-zero"

  # Simulate user modifying a framework file after install.
  echo "# My custom architect agent" > "$target_dir/.claude/agents/sdd-architect.md"

  # Prepare v2.0.0 artifact.
  create_mock_artifact "$artifact_v2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$artifact_v2" "v2.0.0")"
  echo "# Architect Agent v2 content" > "$source_v2/.claude/agents/sdd-architect.md"

  install_files "$source_v2" "$target_dir" "v2.0.0" "all" \
    || _fail "update install (v2.0.0) exited non-zero"

  # The .prospect-incoming file must exist with the new v2 content.
  assert_file_exists "$target_dir/.claude/agents/sdd-architect.md.prospect-incoming" \
    || _fail ".prospect-incoming must be created for a user-modified framework file"

  assert_file_contains \
    "$target_dir/.claude/agents/sdd-architect.md.prospect-incoming" \
    "v2 content" \
    || _fail ".prospect-incoming must contain the new incoming version content"

  # The user's modified file must be preserved.
  assert_file_contains "$target_dir/.claude/agents/sdd-architect.md" "custom" \
    || _fail "user's modified file must be preserved, not overwritten"
}

# ── Tests: FR-3.4 — conflict summary printed ──────────────────────────────────

# test_update_prints_conflict_summary
#
# When conflicts are detected, install_files must print a summary listing
# each .prospect-incoming file so the user knows where to look (FR-3.4).
test_update_prints_conflict_summary() {
  _require_function install_files

  local artifact_v1="$TEST_DIR/artifact_v1"
  local artifact_v2="$TEST_DIR/artifact_v2"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_v1" "$artifact_v2" "$target_dir"
  _make_target_git_repo "$target_dir"

  # Fresh install.
  create_mock_artifact "$artifact_v1" "v1.0.0"
  local source_v1
  source_v1="$(_artifact_root "$artifact_v1" "v1.0.0")"
  install_files "$source_v1" "$target_dir" "v1.0.0" "all" \
    || _fail "fresh install exited non-zero"

  # Modify a framework file to create a conflict.
  echo "# Customised by user" > "$target_dir/.claude/agents/sdd-architect.md"

  # Prepare v2 with new content for the conflicted file.
  create_mock_artifact "$artifact_v2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$artifact_v2" "v2.0.0")"
  echo "# Architect Agent v2" > "$source_v2/.claude/agents/sdd-architect.md"

  local output
  output="$(install_files "$source_v2" "$target_dir" "v2.0.0" "all" 2>&1)" \
    || _fail "update install exited non-zero"

  # Output must reference the incoming file or the concept of a conflict.
  local lower
  lower="$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')"

  [[ "$lower" == *"prospect-incoming"* \
  || "$lower" == *"conflict"* \
  || "$lower" == *"incoming"* ]] \
    || _fail "conflict summary must mention 'prospect-incoming', 'conflict', or 'incoming'; got: '$output'"
}

# ── Tests: FR-5.3, FR-6.1 — user content never overwritten ───────────────────

# test_never_overwrites_user_content
#
# Files in user-created content locations (specs/active/*, specs/implemented/*,
# product/mission.md, product/roadmap.md) must survive an install or update
# completely unchanged (FR-5.3, FR-6.1).
test_never_overwrites_user_content() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  # Pre-create user content in target_dir.
  mkdir -p "$target_dir/specs/active/2026-my-feature"
  echo "# My feature spec" > "$target_dir/specs/active/2026-my-feature/spec.md"

  mkdir -p "$target_dir/product"
  echo "# My mission" > "$target_dir/product/mission.md"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "all" \
    || _fail "install_files exited non-zero"

  # User content must remain intact.
  assert_file_exists "$target_dir/specs/active/2026-my-feature/spec.md" \
    || _fail "specs/active/*/spec.md must not be deleted by install"

  assert_file_contains "$target_dir/specs/active/2026-my-feature/spec.md" "My feature spec" \
    || _fail "specs/active/ content must be preserved verbatim"

  assert_file_exists "$target_dir/product/mission.md" \
    || _fail "product/mission.md must not be deleted by install"

  assert_file_contains "$target_dir/product/mission.md" "My mission" \
    || _fail "product/mission.md content must be preserved verbatim"
}

# ── Tests: FR-3.5 — copilot-instructions.md notification ─────────────────────

# test_copilot_instructions_notification
#
# If .github/copilot-instructions.md already exists in the target with content
# that was not written by Prospect (non-Prospect content), the installer must
# notify the user and suggest merging — it must NOT overwrite the file (FR-3.5).
test_copilot_instructions_notification() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  # Pre-create a copilot-instructions.md with non-Prospect content.
  mkdir -p "$target_dir/.github"
  echo "# My existing Copilot instructions — do not overwrite" \
    > "$target_dir/.github/copilot-instructions.md"
  local original_content="My existing Copilot instructions"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  local output
  output="$(install_files "$source_dir" "$target_dir" "v1.0.0" "all" 2>&1)" \
    || _fail "install_files exited non-zero"

  # The file must not be overwritten.
  assert_file_contains "$target_dir/.github/copilot-instructions.md" "$original_content" \
    || _fail "copilot-instructions.md with non-Prospect content must not be overwritten"

  # The output must contain a merge suggestion or notification.
  local lower
  lower="$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')"

  [[ "$lower" == *"merge"* \
  || "$lower" == *"copilot-instructions"* \
  || "$lower" == *"existing"* \
  || "$lower" == *"manual"* ]] \
    || _fail "output must notify about existing copilot-instructions.md; got: '$output'"
}

# ── Tests: FR-7.1 — non-git directory warning ─────────────────────────────────

# test_non_git_repo_warning
#
# Running install_files against a directory that has no .git/ must print a
# warning but still complete successfully with exit status 0 (FR-7.1).
test_non_git_repo_warning() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  # Deliberately do NOT create .git — this is the non-git scenario.

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  local output status
  status=0
  output="$(install_files "$source_dir" "$target_dir" "v1.0.0" "all" 2>&1)" \
    || status=$?

  # Must succeed (exit 0) even without git.
  [[ $status -eq 0 ]] \
    || _fail "install_files must succeed in a non-git directory, got status $status"

  # Must print a warning that mentions git.
  local lower
  lower="$(printf '%s' "$output" | tr '[:upper:]' '[:lower:]')"

  [[ "$lower" == *"git"* ]] \
    || _fail "output must warn about missing git repository; got: '$output'"
}

# ── Tests: FR-7.3 — idempotency ───────────────────────────────────────────────

# test_idempotent_install
#
# Running install_files twice with the same version and source must produce
# the same result both times without errors (FR-7.3).
test_idempotent_install() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  # First install.
  install_files "$source_dir" "$target_dir" "v1.0.0" "all" \
    || _fail "first install exited non-zero"

  # Second install — must not error.
  local status=0
  install_files "$source_dir" "$target_dir" "v1.0.0" "all" \
    || status=$?

  [[ $status -eq 0 ]] \
    || _fail "second install (idempotency) must exit 0, got status $status"

  # No .prospect-incoming files should exist — nothing changed.
  local incoming_count
  incoming_count="$(find "$target_dir" -name "*.prospect-incoming" 2>/dev/null | wc -l | tr -d ' ')"

  [[ "$incoming_count" -eq 0 ]] \
    || _fail "idempotent install must produce zero .prospect-incoming files, found $incoming_count"

  # Version file still correct.
  assert_file_contains "$target_dir/.prospect-version" "v1.0.0" \
    || _fail ".prospect-version must still contain 'v1.0.0' after second install"
}

# ── Tests: FR-2.2 — claude-only toolchain filter ─────────────────────────────

# test_toolchain_filter_claude_only
#
# When toolchain is "claude", only .claude/* files and shared files
# (standards/, specs/, product/, CLAUDE.md) are installed.
# .github/agents/*, .github/prompts/*, .github/instructions/* must NOT
# be installed (FR-2.2).
test_toolchain_filter_claude_only() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "claude" \
    || _fail "install_files (claude-only) exited non-zero"

  # Claude files must be installed.
  assert_file_exists "$target_dir/.claude/agents/sdd-architect.md" \
    || _fail ".claude/agents/sdd-architect.md must be installed for claude toolchain"

  # Shared files must be installed.
  assert_file_exists "$target_dir/standards/global/code-quality.md" \
    || _fail "standards/global/code-quality.md must be installed for claude toolchain"

  # Copilot-specific files must NOT be installed.
  assert_file_not_exists "$target_dir/.github/agents/sdd-start.agent.md" \
    || _fail ".github/agents/ files must NOT be installed for claude-only toolchain"

  assert_file_not_exists "$target_dir/.github/prompts/sdd-start.prompt.md" \
    || _fail ".github/prompts/ files must NOT be installed for claude-only toolchain"
}

# ── Tests: FR-2.3 — copilot-only toolchain filter ────────────────────────────

# test_toolchain_filter_copilot_only
#
# When toolchain is "copilot", only .github/* files and shared files are
# installed. .claude/agents/*, .claude/skills/* must NOT be installed (FR-2.3).
test_toolchain_filter_copilot_only() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "copilot" \
    || _fail "install_files (copilot-only) exited non-zero"

  # Copilot files must be installed.
  assert_file_exists "$target_dir/.github/agents/sdd-start.agent.md" \
    || _fail ".github/agents/sdd-start.agent.md must be installed for copilot toolchain"

  # Shared files must be installed.
  assert_file_exists "$target_dir/standards/global/code-quality.md" \
    || _fail "standards/global/code-quality.md must be installed for copilot toolchain"

  # Claude-specific files must NOT be installed.
  assert_file_not_exists "$target_dir/.claude/agents/sdd-architect.md" \
    || _fail ".claude/agents/ files must NOT be installed for copilot-only toolchain"

  assert_file_not_exists "$target_dir/.claude/skills/sdd-start/SKILL.md" \
    || _fail ".claude/skills/ files must NOT be installed for copilot-only toolchain"
}

# ── Tests: FR-6.2 — pre-existing non-Prospect .github/ content survives ───────

# test_preserves_non_prospect_files
#
# If a .github/workflows/ci.yml (or any other non-Prospect file) pre-exists
# in target_dir, install_files must leave it completely untouched (FR-6.2).
test_preserves_non_prospect_files() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  # Pre-create a non-Prospect workflow file.
  mkdir -p "$target_dir/.github/workflows"
  echo "name: CI" > "$target_dir/.github/workflows/ci.yml"

  # Pre-create a non-Prospect issue template.
  mkdir -p "$target_dir/.github/ISSUE_TEMPLATE"
  echo "Bug report template" > "$target_dir/.github/ISSUE_TEMPLATE/bug_report.md"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  install_files "$source_dir" "$target_dir" "v1.0.0" "all" \
    || _fail "install_files exited non-zero"

  # Non-Prospect files must survive.
  assert_file_exists "$target_dir/.github/workflows/ci.yml" \
    || _fail ".github/workflows/ci.yml must NOT be deleted by install"

  assert_file_contains "$target_dir/.github/workflows/ci.yml" "name: CI" \
    || _fail ".github/workflows/ci.yml content must be preserved verbatim"

  assert_file_exists "$target_dir/.github/ISSUE_TEMPLATE/bug_report.md" \
    || _fail ".github/ISSUE_TEMPLATE/bug_report.md must NOT be deleted by install"
}

# ── Run ────────────────────────────────────────────────────────────────────────

run_tests
