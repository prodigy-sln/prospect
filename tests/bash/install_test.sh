#!/usr/bin/env bash
# Unit tests for install_files() in install.sh
#
# Covers:
#   FR-3.1 — fresh install copies all files without conflict checks
#   FR-3.2 — on update, unmodified files are overwritten silently
#   FR-3.3 — on update, modified files get .prospect-incoming treatment
#   FR-3.4 — summary of conflicts printed after all files are processed
#   FR-4.1 — .prospect-version created after install
#   FR-4.2 — .prospect-manifest.json created with per-file checksums
#   FR-5.3 — user-created content (specs/active/*, product/mission.md) never touched
#   FR-5.4 — empty directories (specs/active/, specs/archive/, product/) created
#   FR-6.1 — script never deletes files it did not install
#   FR-6.2 — pre-existing unrelated content survives install
#   FR-7.1 — non-git directory prints warning but succeeds
#   FR-7.3 — idempotent: second run with same version produces no errors
#   specs/REGISTRY.md — seeded when absent, never overwritten on update
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
# On first install (no .prospect-manifest.json), all managed files from the
# source artifact must be copied to target_dir (FR-3.1).
test_fresh_install_copies_all_files() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  install_files "$source_dir" "$target_dir" "v1.0.0" \
    || _fail "install_files exited non-zero on fresh install"

  # Spot-check framework, workflow, standards, template, and shared files.
  assert_file_exists "$target_dir/.claude/agents/sdd-architect.md" \
    || _fail ".claude/agents/sdd-architect.md must be installed"

  assert_file_exists "$target_dir/.claude/skills/sdd-start/SKILL.md" \
    || _fail ".claude/skills/sdd-start/SKILL.md must be installed"

  assert_file_exists "$target_dir/.claude/workflows/sdd-validate.js" \
    || _fail ".claude/workflows/sdd-validate.js must be installed"

  assert_file_exists "$target_dir/standards/global/code-quality.md" \
    || _fail "standards/global/code-quality.md must be installed"

  assert_file_exists "$target_dir/CLAUDE.md" \
    || _fail "CLAUDE.md must be installed"

  assert_file_exists "$target_dir/.prospect/templates/spec.template.md" \
    || _fail ".prospect/templates/spec.template.md must be installed"

  assert_file_exists "$target_dir/specs/REGISTRY.md" \
    || _fail "specs/REGISTRY.md must be seeded on fresh install"

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

  install_files "$source_dir" "$target_dir" "v1.0.0" \
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
# install_files must create specs/active/, specs/archive/, and product/
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

  install_files "$source_dir" "$target_dir" "v1.0.0" \
    || _fail "install_files exited non-zero"

  assert_dir_exists "$target_dir/specs/active" \
    || _fail "specs/active/ directory must exist after install"

  assert_dir_exists "$target_dir/specs/archive" \
    || _fail "specs/archive/ directory must exist after install"

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

  install_files "$source_v1" "$target_dir" "v1.0.0" \
    || _fail "fresh install (v1.0.0) exited non-zero"

  # Prepare v2.0.0 artifact with updated content for a framework file.
  create_mock_artifact "$artifact_v2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$artifact_v2" "v2.0.0")"
  echo "# Architect Agent v2" > "$source_v2/.claude/agents/sdd-architect.md"
  bake_manifest "$source_v2" "v2.0.0"

  install_files "$source_v2" "$target_dir" "v2.0.0" \
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

  install_files "$source_v1" "$target_dir" "v1.0.0" \
    || _fail "fresh install (v1.0.0) exited non-zero"

  # Simulate user modifying a framework file after install.
  echo "# My custom architect agent" > "$target_dir/.claude/agents/sdd-architect.md"

  # Prepare v2.0.0 artifact.
  create_mock_artifact "$artifact_v2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$artifact_v2" "v2.0.0")"
  echo "# Architect Agent v2 content" > "$source_v2/.claude/agents/sdd-architect.md"
  bake_manifest "$source_v2" "v2.0.0"

  install_files "$source_v2" "$target_dir" "v2.0.0" \
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
  install_files "$source_v1" "$target_dir" "v1.0.0" \
    || _fail "fresh install exited non-zero"

  # Modify a framework file to create a conflict.
  echo "# Customised by user" > "$target_dir/.claude/agents/sdd-architect.md"

  # Prepare v2 with new content for the conflicted file.
  create_mock_artifact "$artifact_v2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$artifact_v2" "v2.0.0")"
  echo "# Architect Agent v2" > "$source_v2/.claude/agents/sdd-architect.md"
  bake_manifest "$source_v2" "v2.0.0"

  local output
  output="$(install_files "$source_v2" "$target_dir" "v2.0.0" 2>&1)" \
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
# Files in user-created content locations (specs/active/*, specs/archive/*,
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

  install_files "$source_dir" "$target_dir" "v1.0.0" \
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

# ── Tests: specs/REGISTRY.md — install-once ──────────────────────────────────

# test_registry_seeded_when_absent
#
# On a fresh install where specs/REGISTRY.md does not yet exist in the target,
# the installer must seed it from the artifact.
test_registry_seeded_when_absent() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  local source_dir
  source_dir="$(_artifact_root "$artifact_dir" "v1.0.0")"

  install_files "$source_dir" "$target_dir" "v1.0.0" \
    || _fail "install_files exited non-zero"

  assert_file_exists "$target_dir/specs/REGISTRY.md" \
    || _fail "specs/REGISTRY.md must be seeded when absent"
}

# test_registry_never_overwritten_on_update
#
# specs/REGISTRY.md is the user's append-only record. Once it exists it must
# never be overwritten — not even when its content differs from the artifact —
# and it must never produce a .prospect-incoming file.
test_registry_never_overwritten_on_update() {
  _require_function install_files

  local artifact_v1="$TEST_DIR/artifact_v1"
  local artifact_v2="$TEST_DIR/artifact_v2"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_v1" "$artifact_v2" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_v1" "v1.0.0"
  local source_v1
  source_v1="$(_artifact_root "$artifact_v1" "v1.0.0")"
  install_files "$source_v1" "$target_dir" "v1.0.0" \
    || _fail "fresh install (v1.0.0) exited non-zero"

  # User appends a completed-spec line to their registry.
  printf '\n[2026-my-feature] · 2026-01-01 · high · PR #1\n' \
    >> "$target_dir/specs/REGISTRY.md"

  # Update to v2 whose REGISTRY.md seed differs from the user's content.
  create_mock_artifact "$artifact_v2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$artifact_v2" "v2.0.0")"
  echo "# Spec Registry v2 seed" > "$source_v2/specs/REGISTRY.md"
  bake_manifest "$source_v2" "v2.0.0"

  install_files "$source_v2" "$target_dir" "v2.0.0" \
    || _fail "update install (v2.0.0) exited non-zero"

  # The user's registry content must survive verbatim.
  assert_file_contains "$target_dir/specs/REGISTRY.md" "2026-my-feature" \
    || _fail "user's REGISTRY.md content must be preserved, not overwritten"

  # No .prospect-incoming must be created for the registry.
  assert_file_not_exists "$target_dir/specs/REGISTRY.md.prospect-incoming" \
    || _fail ".prospect-incoming must NOT be created for specs/REGISTRY.md"
}

# ── Tests: conflicted files stay conflicted across updates ────────────────────

# test_conflict_does_not_record_user_checksum
#
# When an update conflicts, the manifest must record the checksum of the
# content Prospect shipped — never the checksum of the user's file that was
# left in place. Recording the user's checksum makes the file look pristine
# on the next update.
test_conflict_does_not_record_user_checksum() {
  _require_function install_files

  local artifact_v1="$TEST_DIR/artifact_v1"
  local artifact_v2="$TEST_DIR/artifact_v2"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_v1" "$artifact_v2" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_v1" "v1.0.0"
  install_files "$(_artifact_root "$artifact_v1" "v1.0.0")" "$target_dir" "v1.0.0" \
    || _fail "fresh install (v1.0.0) exited non-zero"

  local rel_path=".claude/agents/sdd-architect.md"
  echo "# My custom architect agent" > "$target_dir/$rel_path"

  create_mock_artifact "$artifact_v2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$artifact_v2" "v2.0.0")"
  echo "# Architect Agent v2 content" > "$source_v2/$rel_path"
  bake_manifest "$source_v2" "v2.0.0"

  install_files "$source_v2" "$target_dir" "v2.0.0" \
    || _fail "update install (v2.0.0) exited non-zero"

  local recorded user_sum shipped_sum
  recorded="$(read_manifest_checksum "$target_dir" "$rel_path")"
  user_sum="$(compute_checksum "$target_dir/$rel_path")"
  shipped_sum="$(compute_checksum "$source_v2/$rel_path")"

  [[ "$recorded" != "$user_sum" ]] \
    || _fail "manifest recorded the user's modified file as the tracked baseline"

  assert_eq "$shipped_sum" "$recorded" \
    || _fail "manifest must record the shipped v2 checksum for a conflicted file"
}

# test_second_update_after_unmerged_conflict_preserves_user_file
#
# The user's file survives repeated updates for as long as the conflict is
# unmerged: each update writes a fresh .prospect-incoming and never clobbers
# the local edits.
test_second_update_after_unmerged_conflict_preserves_user_file() {
  _require_function install_files

  local target_dir="$TEST_DIR/target"
  mkdir -p "$target_dir"
  _make_target_git_repo "$target_dir"

  local rel_path=".claude/agents/sdd-architect.md"

  create_mock_artifact "$TEST_DIR/a1" "v1.0.0"
  install_files "$(_artifact_root "$TEST_DIR/a1" "v1.0.0")" "$target_dir" "v1.0.0" \
    || _fail "fresh install (v1.0.0) exited non-zero"

  echo "# My custom architect agent" > "$target_dir/$rel_path"

  create_mock_artifact "$TEST_DIR/a2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$TEST_DIR/a2" "v2.0.0")"
  echo "# Architect Agent v2 content" > "$source_v2/$rel_path"
  bake_manifest "$source_v2" "v2.0.0"
  install_files "$source_v2" "$target_dir" "v2.0.0" \
    || _fail "update to v2.0.0 exited non-zero"

  # The user ignores the incoming file and updates again.
  create_mock_artifact "$TEST_DIR/a3" "v3.0.0"
  local source_v3
  source_v3="$(_artifact_root "$TEST_DIR/a3" "v3.0.0")"
  echo "# Architect Agent v3 content" > "$source_v3/$rel_path"
  bake_manifest "$source_v3" "v3.0.0"
  install_files "$source_v3" "$target_dir" "v3.0.0" \
    || _fail "update to v3.0.0 exited non-zero"

  assert_file_contains "$target_dir/$rel_path" "My custom architect agent" \
    || _fail "the second update overwrote the user's still-unmerged file"

  assert_file_contains "$target_dir/${rel_path}.prospect-incoming" "v3 content" \
    || _fail ".prospect-incoming must carry the newest shipped content"
}

# test_conflict_resolved_by_accepting_incoming_stops_conflicting
#
# Once the user adopts the shipped content, the file is tracked as pristine
# again and later updates apply silently.
test_conflict_resolved_by_accepting_incoming_stops_conflicting() {
  _require_function install_files

  local target_dir="$TEST_DIR/target"
  mkdir -p "$target_dir"
  _make_target_git_repo "$target_dir"

  local rel_path=".claude/agents/sdd-architect.md"

  create_mock_artifact "$TEST_DIR/a1" "v1.0.0"
  install_files "$(_artifact_root "$TEST_DIR/a1" "v1.0.0")" "$target_dir" "v1.0.0" \
    || _fail "fresh install exited non-zero"

  echo "# My custom architect agent" > "$target_dir/$rel_path"

  create_mock_artifact "$TEST_DIR/a2" "v2.0.0"
  local source_v2
  source_v2="$(_artifact_root "$TEST_DIR/a2" "v2.0.0")"
  echo "# Architect Agent v2 content" > "$source_v2/$rel_path"
  bake_manifest "$source_v2" "v2.0.0"
  install_files "$source_v2" "$target_dir" "v2.0.0" \
    || _fail "update to v2.0.0 exited non-zero"

  # User accepts the incoming file wholesale.
  mv "$target_dir/${rel_path}.prospect-incoming" "$target_dir/$rel_path"

  create_mock_artifact "$TEST_DIR/a3" "v3.0.0"
  local source_v3
  source_v3="$(_artifact_root "$TEST_DIR/a3" "v3.0.0")"
  echo "# Architect Agent v3 content" > "$source_v3/$rel_path"
  bake_manifest "$source_v3" "v3.0.0"
  install_files "$source_v3" "$target_dir" "v3.0.0" \
    || _fail "update to v3.0.0 exited non-zero"

  assert_file_contains "$target_dir/$rel_path" "v3 content" \
    || _fail "a resolved file must be updated silently by the next release"

  assert_file_not_exists "$target_dir/${rel_path}.prospect-incoming" \
    || _fail "no conflict may be reported once the user adopted the shipped content"
}

# ── Tests: installer plumbing never lands in the target ───────────────────────

# test_install_scripts_and_readme_not_installed
#
# The release artifact carries install.sh, install.ps1 and the framework's own
# README so the tarball is self-contained, but installing must not drop them
# into the target project — README.md would overwrite the project's own.
test_install_scripts_and_readme_not_installed() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  echo "# My project" > "$target_dir/README.md"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  install_files "$(_artifact_root "$artifact_dir" "v1.0.0")" "$target_dir" "v1.0.0" \
    || _fail "fresh install exited non-zero"

  assert_file_contains "$target_dir/README.md" "My project" \
    || _fail "the project's README.md must not be replaced by the framework README"

  assert_file_not_exists "$target_dir/install.sh" \
    || _fail "install.sh must not be installed into the target project"
  assert_file_not_exists "$target_dir/install.ps1" \
    || _fail "install.ps1 must not be installed into the target project"

  local manifest="$target_dir/.prospect-manifest.json"
  assert_not_contains "$(cat "$manifest")" '"install.sh"' \
    || _fail "install.sh must not be tracked in the manifest"
  assert_not_contains "$(cat "$manifest")" '"README.md"' \
    || _fail "README.md must not be tracked in the manifest"
}

# test_fresh_install_does_not_clobber_existing_file
#
# Installing into a repository that already carries a file Prospect ships
# (e.g. its own CLAUDE.md) must offer the framework version as
# .prospect-incoming rather than overwrite work that predates the install.
test_fresh_install_does_not_clobber_existing_file() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  echo "# Existing project instructions" > "$target_dir/CLAUDE.md"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  install_files "$(_artifact_root "$artifact_dir" "v1.0.0")" "$target_dir" "v1.0.0" \
    || _fail "fresh install exited non-zero"

  assert_file_contains "$target_dir/CLAUDE.md" "Existing project instructions" \
    || _fail "a pre-existing CLAUDE.md must survive a fresh install"

  assert_file_exists "$target_dir/CLAUDE.md.prospect-incoming" \
    || _fail "the framework CLAUDE.md must be offered as .prospect-incoming"
}

# ── Tests: merging conflicts with Claude Code ─────────────────────────────────

# test_merge_proposal_prints_command_when_non_interactive
#
# Without a terminal (CI, `curl | bash` in a pipeline) the installer prints the
# ready-to-paste claude command instead of asking.
test_merge_proposal_prints_command_when_non_interactive() {
  _require_function propose_merge

  _is_interactive() { return 1; }

  local output
  output="$(propose_merge "$TEST_DIR" 2>&1)" \
    || _fail "propose_merge exited non-zero"

  assert_contains "$output" 'claude "' \
    || _fail "must print the claude command; got: $output"
  assert_contains "$output" ".prospect-incoming" \
    || _fail "the printed prompt must reference the .prospect-incoming files"
}

# test_merge_proposal_runs_claude_when_accepted
#
# In an interactive shell the installer offers to run Claude Code and does so
# when the user accepts.
test_merge_proposal_runs_claude_when_accepted() {
  _require_function propose_merge

  _is_interactive() { return 0; }
  _ask_yes_no() { return 0; }
  claude() { printf '%s' "$1" > "$TEST_DIR/claude-invoked"; }

  propose_merge "$TEST_DIR" > /dev/null 2>&1 \
    || _fail "propose_merge exited non-zero"

  assert_file_exists "$TEST_DIR/claude-invoked" \
    || _fail "claude must be invoked when the user accepts"
  assert_file_contains "$TEST_DIR/claude-invoked" "prospect-incoming" \
    || _fail "claude must receive the merge prompt"
}

# test_merge_proposal_prints_command_when_declined
#
# Declining leaves the command behind so it can be run later.
test_merge_proposal_prints_command_when_declined() {
  _require_function propose_merge

  _is_interactive() { return 0; }
  _ask_yes_no() { return 1; }
  claude() { touch "$TEST_DIR/claude-invoked"; }

  local output
  output="$(propose_merge "$TEST_DIR" 2>&1)" \
    || _fail "propose_merge exited non-zero"

  assert_file_not_exists "$TEST_DIR/claude-invoked" \
    || _fail "claude must not run when the user declines"
  assert_contains "$output" 'claude "' \
    || _fail "must print the claude command after declining; got: $output"
}

# ── Tests: the merge brief cites the release history ──────────────────────────

# test_merge_prompt_cites_the_version_range
#
# Merging incoming files well needs the framework's intent, which lives in the
# release notes — so the brief names both versions and links the tag comparison.
test_merge_prompt_cites_the_version_range() {
  _require_function merge_prompt

  local prompt
  prompt="$(merge_prompt "v2.0.0" "v3.0.0")"

  assert_contains "$prompt" "v2.0.0" \
    || _fail "the brief must name the version being updated from; got: $prompt"
  assert_contains "$prompt" "v3.0.0" \
    || _fail "the brief must name the version being updated to; got: $prompt"
  assert_contains "$prompt" "/compare/v2.0.0...v3.0.0" \
    || _fail "the brief must link the tag comparison; got: $prompt"
  assert_contains "$prompt" "/releases" \
    || _fail "the brief must link the release notes; got: $prompt"
}

# test_merge_prompt_without_a_previous_version
#
# A first install into a populated repository has no previous version to
# compare against; the brief still points at the release notes.
test_merge_prompt_without_a_previous_version() {
  _require_function merge_prompt

  local prompt
  prompt="$(merge_prompt "" "v3.0.0")"

  assert_contains "$prompt" "/releases" \
    || _fail "the brief must link the release notes; got: $prompt"
  assert_not_contains "$prompt" "/compare/" \
    || _fail "no tag comparison is possible without a previous version; got: $prompt"
  assert_contains "$prompt" ".prospect-incoming" \
    || _fail "the brief must still describe the merge task; got: $prompt"
}

# test_merge_prompt_survives_being_pasted
#
# The brief is printed inside claude "..." — characters the shell would expand
# there turn the copy-pasteable command into something else.
test_merge_prompt_survives_being_pasted() {
  _require_function merge_prompt

  local prompt
  prompt="$(merge_prompt "v2.0.0" "v3.0.0")"

  [[ "$prompt" != *'"'* ]] || _fail "the brief must not contain double quotes"
  [[ "$prompt" != *'`'* ]] || _fail "the brief must not contain backticks"
  [[ "$prompt" != *'$'* ]] || _fail "the brief must not contain dollar signs"
}

# test_install_reports_the_version_it_replaced
#
# propose_merge can only cite the range if install_files remembers what was
# there before it wrote the new version file.
test_install_reports_the_version_it_replaced() {
  _require_function install_files

  local artifact_dir="$TEST_DIR/artifact"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$artifact_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  create_mock_artifact "$artifact_dir" "v1.0.0"
  install_files "$(_artifact_root "$artifact_dir" "v1.0.0")" "$target_dir" "v1.0.0" \
    > /dev/null || _fail "first install exited non-zero"

  create_mock_artifact "$artifact_dir" "v2.0.0"
  install_files "$(_artifact_root "$artifact_dir" "v2.0.0")" "$target_dir" "v2.0.0" \
    > /dev/null || _fail "second install exited non-zero"

  assert_eq "v1.0.0" "${PROSPECT_PREVIOUS_VERSION:-}" \
    || _fail "install_files must report the version it replaced"
}

# test_merge_proposal_carries_the_version_range
#
# The command the installer prints is the one the user runs — the range has to
# be in it, not merely available to the function.
test_merge_proposal_carries_the_version_range() {
  _require_function propose_merge

  _is_interactive() { return 1; }

  local output
  output="$(propose_merge "$TEST_DIR" "v2.0.0" "v3.0.0" 2>&1)" \
    || _fail "propose_merge exited non-zero"

  assert_contains "$output" "/compare/v2.0.0...v3.0.0" \
    || _fail "the printed command must carry the tag comparison; got: $output"
}

# ── Tests: empty source ───────────────────────────────────────────────────────

# test_empty_source_fails_loudly
#
# An artifact that did not extract must abort the install rather than report
# success having written nothing.
test_empty_source_fails_loudly() {
  _require_function install_files

  local source_dir="$TEST_DIR/empty"
  local target_dir="$TEST_DIR/target"
  mkdir -p "$source_dir" "$target_dir"
  _make_target_git_repo "$target_dir"

  local output status
  status=0
  output="$(install_files "$source_dir" "$target_dir" "v1.0.0" 2>&1)" || status=$?

  [[ $status -ne 0 ]] \
    || _fail "install_files must fail when the source has no files"
  assert_contains "$output" "no files found" \
    || _fail "the error must say the artifact is empty; got: $output"
  assert_file_not_exists "$target_dir/.prospect-manifest.json" \
    || _fail "no manifest may be written for a failed install"
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
  output="$(install_files "$source_dir" "$target_dir" "v1.0.0" 2>&1)" \
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
  install_files "$source_dir" "$target_dir" "v1.0.0" \
    || _fail "first install exited non-zero"

  # Second install — must not error.
  local status=0
  install_files "$source_dir" "$target_dir" "v1.0.0" \
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

# ── Tests: FR-6.2 — pre-existing unrelated content survives ──────────────────

# test_preserves_non_prospect_files
#
# If a .github/workflows/ci.yml (or any other file the installer does not
# manage) pre-exists in target_dir, install_files must leave it completely
# untouched (FR-6.2).
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

  install_files "$source_dir" "$target_dir" "v1.0.0" \
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
