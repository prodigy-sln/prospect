#!/usr/bin/env bash
# Release artifact tests — T026
# Covers FR-8.2, FR-8.3, FR-8.4
#
# Verifies that scripts/build-release.sh produces a correct release artifact:
# correct directory structure, required files, excluded content, and
# .gitkeep markers for empty directories.
#
# Tests WILL FAIL until scripts/build-release.sh is implemented (RED phase).

set -euo pipefail

source "$(dirname "$0")/../helpers/setup.bash"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_SCRIPT="$REPO_ROOT/scripts/build-release.sh"

# ── Internal helper ───────────────────────────────────────────────────────────

_fail() {
  echo "    FAIL: $*" >&2
  exit 1
}

# Run build script in TEST_DIR, extract the archive, and return the extracted
# root directory path via stdout.
_build_and_extract() {
  local version="${1:-v1.0.0}"

  # Run the build script from the repo root so it can find source files
  bash "$BUILD_SCRIPT" "$version" >"$TEST_DIR/build.log" 2>&1

  # The script should produce prospect-<version>.tar.gz in the current directory
  # The build script outputs to pwd when called; we run it from REPO_ROOT and
  # capture the archive paths from its output.
  local tarball
  tarball=$(grep '\.tar\.gz' "$TEST_DIR/build.log" | tail -1 | tr -d '[:space:]')

  if [[ -z "$tarball" || ! -f "$tarball" ]]; then
    echo "    FAIL: build script did not produce a .tar.gz (log: $(cat "$TEST_DIR/build.log"))" >&2
    exit 1
  fi

  # Extract into TEST_DIR
  tar -xzf "$tarball" -C "$TEST_DIR"

  # Return the extracted root directory
  echo "$TEST_DIR/prospect-${version}"
}

# ── Tests ─────────────────────────────────────────────────────────────────────

# FR-8.2: artifact contains Claude Code files
test_artifact_contains_claude_files() {
  local root
  root=$(_build_and_extract "v1.0.0")

  assert_dir_exists "$root/.claude/agents" ".claude/agents/ must be in artifact" \
    || _fail ".claude/agents/ missing from artifact"
  assert_dir_exists "$root/.claude/skills" ".claude/skills/ must be in artifact" \
    || _fail ".claude/skills/ missing from artifact"
}

# FR-8.2: artifact contains VS Code Copilot files
test_artifact_contains_copilot_files() {
  local root
  root=$(_build_and_extract "v1.0.0")

  assert_dir_exists "$root/.github/agents" ".github/agents/ must be in artifact" \
    || _fail ".github/agents/ missing from artifact"
  assert_dir_exists "$root/.github/prompts" ".github/prompts/ must be in artifact" \
    || _fail ".github/prompts/ missing from artifact"
  assert_dir_exists "$root/.github/instructions" ".github/instructions/ must be in artifact" \
    || _fail ".github/instructions/ missing from artifact"
}

# FR-8.2: artifact contains shared/standards files
test_artifact_contains_shared_files() {
  local root
  root=$(_build_and_extract "v1.0.0")

  assert_dir_exists "$root/standards" "standards/ must be in artifact" \
    || _fail "standards/ missing from artifact"
  assert_dir_exists "$root/specs/_templates" "specs/_templates/ must be in artifact" \
    || _fail "specs/_templates/ missing from artifact"
  assert_file_exists "$root/CLAUDE.md" "CLAUDE.md must be in artifact" \
    || _fail "CLAUDE.md missing from artifact"
  assert_file_exists "$root/README.md" "README.md must be in artifact" \
    || _fail "README.md missing from artifact"
}

# FR-8.2: artifact contains install scripts
test_artifact_contains_scripts() {
  local root
  root=$(_build_and_extract "v1.0.0")

  assert_file_exists "$root/install.sh" "install.sh must be in artifact" \
    || _fail "install.sh missing from artifact"
  assert_file_exists "$root/install.ps1" "install.ps1 must be in artifact" \
    || _fail "install.ps1 missing from artifact"
}

# FR-8.3: artifact includes .gitkeep markers for empty spec directories
test_artifact_includes_gitkeep_for_empty_dirs() {
  local root
  root=$(_build_and_extract "v1.0.0")

  assert_file_exists "$root/specs/active/.gitkeep" \
    "specs/active/.gitkeep must be in artifact (FR-8.3)" \
    || _fail "specs/active/.gitkeep missing from artifact"
  assert_file_exists "$root/specs/implemented/.gitkeep" \
    "specs/implemented/.gitkeep must be in artifact (FR-8.3)" \
    || _fail "specs/implemented/.gitkeep missing from artifact"
}

# FR-8.4: artifact must NOT include spec content under specs/active/ (only .gitkeep)
test_artifact_excludes_spec_content() {
  local root
  root=$(_build_and_extract "v1.0.0")

  # Count files under specs/active/ — must be exactly 1 (.gitkeep only)
  local active_files
  active_files=$(find "$root/specs/active" -type f 2>/dev/null | wc -l | tr -d '[:space:]')

  assert_eq "1" "$active_files" \
    "specs/active/ should contain exactly 1 file (.gitkeep), got $active_files" \
    || _fail "specs/active/ should contain only .gitkeep, found $active_files file(s)"

  local implemented_files
  implemented_files=$(find "$root/specs/implemented" -type f 2>/dev/null | wc -l | tr -d '[:space:]')

  assert_eq "1" "$implemented_files" \
    "specs/implemented/ should contain exactly 1 file (.gitkeep), got $implemented_files" \
    || _fail "specs/implemented/ should contain only .gitkeep, found $implemented_files file(s)"
}

# FR-8.4: artifact must NOT include .git directory
test_artifact_excludes_git_directory() {
  local root
  root=$(_build_and_extract "v1.0.0")

  if [[ -d "$root/.git" ]]; then
    _fail ".git/ must NOT be included in the release artifact (FR-8.4)"
  fi
}

# FR-8.2: top-level directory must be prospect-<version>/
test_artifact_has_correct_structure() {
  local version="v1.0.0"

  bash "$BUILD_SCRIPT" "$version" >"$TEST_DIR/build.log" 2>&1

  local tarball
  tarball=$(grep '\.tar\.gz' "$TEST_DIR/build.log" | tail -1 | tr -d '[:space:]')

  if [[ -z "$tarball" || ! -f "$tarball" ]]; then
    _fail "build script did not produce a .tar.gz"
  fi

  # List top-level entries in the archive — they must all start with prospect-v1.0.0/
  local top_level
  top_level=$(tar -tzf "$tarball" | cut -d'/' -f1 | sort -u)

  assert_eq "prospect-${version}" "$top_level" \
    "top-level archive directory must be prospect-${version}" \
    || _fail "expected top-level 'prospect-${version}', got: $top_level"
}

# ── Run ───────────────────────────────────────────────────────────────────────

run_tests
