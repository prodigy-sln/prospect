#!/usr/bin/env bash
# Unit tests for file categorization and manifest functions in install.sh
#
# Covers:
#   FR-4.1 — write .prospect-version file
#   FR-4.2 — write .prospect-manifest.json with version, toolchains, per-file checksums
#   FR-5.1 — framework-managed files (overwrite if unmodified)
#   FR-5.2 — user-customizable files (conflict-check on update)
#   FR-5.3 — user-created content (never touch)
#   FR-5.4 — directory structure created even if empty
#
# Task: T012 [TEST] [SCRIPT] Write tests for file categorization and manifest
#
# RED phase: classify_file(), write_manifest(), read_manifest_version(),
#            read_manifest_toolchains(), read_manifest_checksum(), and
#            write_version_file() are not yet defined in install.sh,
#            so all tests will fail.

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
  echo "  Tests will fail because required functions are not defined." >&2
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

# ── Tests: classify_file ───────────────────────────────────────────────────────

# test_classify_framework_files
#
# Paths under .claude/agents/*, .claude/skills/*, .github/agents/*,
# .github/prompts/*, .github/instructions/*, and specs/_templates/* must all
# return "framework" — these are safe to overwrite on update (FR-5.1).
test_classify_framework_files() {
  _require_function classify_file

  local paths=(
    ".claude/agents/sdd-architect.md"
    ".claude/agents/sdd-implementer.md"
    ".claude/skills/sdd-start/SKILL.md"
    ".claude/skills/sdd-tasks/SKILL.md"
    ".github/agents/sdd-start.agent.md"
    ".github/prompts/sdd-start.prompt.md"
    ".github/instructions/sdd-context.md"
    "specs/_templates/spec.template.md"
    "specs/_templates/tasks.template.md"
  )

  for path in "${paths[@]}"; do
    local result
    result="$(classify_file "$path")" \
      || _fail "classify_file '$path' exited non-zero"
    [[ "$result" == "framework" ]] \
      || _fail "classify_file '$path' — expected 'framework', got '$result'"
  done
}

# test_classify_customizable_files
#
# standards/global/*.md, CLAUDE.md, and .github/copilot-instructions.md must
# return "customizable" — conflict-check needed on update (FR-5.2).
test_classify_customizable_files() {
  _require_function classify_file

  local paths=(
    "standards/global/code-quality.md"
    "standards/global/testing.md"
    "standards/global/git-workflow.md"
    "CLAUDE.md"
    ".github/copilot-instructions.md"
  )

  for path in "${paths[@]}"; do
    local result
    result="$(classify_file "$path")" \
      || _fail "classify_file '$path' exited non-zero"
    [[ "$result" == "customizable" ]] \
      || _fail "classify_file '$path' — expected 'customizable', got '$result'"
  done
}

# test_classify_user_content_files
#
# Contents under specs/active/*, specs/implemented/*, and the user product
# files (product/mission.md, product/roadmap.md) must return "user-content" —
# these locations are never touched by the installer (FR-5.3).
test_classify_user_content_files() {
  _require_function classify_file

  local paths=(
    "specs/active/2026-03-19-my-feature/spec.md"
    "specs/active/some-spec/tasks.md"
    "specs/implemented/2025-01-01-done/spec.md"
    "product/mission.md"
    "product/roadmap.md"
  )

  for path in "${paths[@]}"; do
    local result
    result="$(classify_file "$path")" \
      || _fail "classify_file '$path' exited non-zero"
    [[ "$result" == "user-content" ]] \
      || _fail "classify_file '$path' — expected 'user-content', got '$result'"
  done
}

# test_classify_template_files
#
# product/mission.template.md and product/roadmap.template.md are framework-
# managed templates that live under product/ — they must return "template" so
# the installer can write them without ever touching the user-created .md
# counterparts (FR-5.1 / FR-5.3 boundary).
test_classify_template_files() {
  _require_function classify_file

  local paths=(
    "product/mission.template.md"
    "product/roadmap.template.md"
  )

  for path in "${paths[@]}"; do
    local result
    result="$(classify_file "$path")" \
      || _fail "classify_file '$path' exited non-zero"
    [[ "$result" == "template" ]] \
      || _fail "classify_file '$path' — expected 'template', got '$result'"
  done
}

# ── Tests: write_manifest ──────────────────────────────────────────────────────

# test_write_manifest_creates_json
#
# write_manifest <target_dir> <version> <toolchains> <file1> [<file2> ...]
# must create .prospect-manifest.json in target_dir containing:
#   - "version" key matching the supplied version tag
#   - "toolchains" array with the supplied toolchain string(s)
#   - "files" object with at least one entry whose key is the relative path
#     and whose value is a sha256 hex string
# (FR-4.2)
test_write_manifest_creates_json() {
  _require_function write_manifest

  # Create a real file so compute_checksum has something to hash.
  local rel_path=".claude/agents/sdd-architect.md"
  mkdir -p "$TEST_DIR/.claude/agents"
  echo "# Architect Agent" > "$TEST_DIR/$rel_path"

  write_manifest "$TEST_DIR" "v1.0.0" "claude" "$rel_path" \
    || _fail "write_manifest exited non-zero"

  local manifest="$TEST_DIR/.prospect-manifest.json"
  assert_file_exists "$manifest" ".prospect-manifest.json must be created" \
    || _fail ".prospect-manifest.json was not created"

  local content
  content="$(cat "$manifest")"

  assert_contains "$content" '"version"' \
    || _fail 'manifest must contain a "version" key'

  assert_contains "$content" "v1.0.0" \
    || _fail "manifest must contain the version value 'v1.0.0'"

  assert_contains "$content" '"toolchains"' \
    || _fail 'manifest must contain a "toolchains" key'

  assert_contains "$content" '"files"' \
    || _fail 'manifest must contain a "files" key'

  assert_contains "$content" "$rel_path" \
    || _fail "manifest must contain the relative file path '$rel_path'"
}

# test_write_manifest_stores_correct_checksum
#
# The checksum stored in the manifest for each file must match the sha256
# of that file's actual content (FR-4.2).
test_write_manifest_stores_correct_checksum() {
  _require_function write_manifest

  local rel_path=".claude/agents/sdd-architect.md"
  mkdir -p "$TEST_DIR/.claude/agents"
  printf "known content\n" > "$TEST_DIR/$rel_path"

  write_manifest "$TEST_DIR" "v1.0.0" "claude" "$rel_path" \
    || _fail "write_manifest exited non-zero"

  local expected_checksum
  expected_checksum="$(compute_checksum "$TEST_DIR/$rel_path")"

  local manifest="$TEST_DIR/.prospect-manifest.json"
  assert_file_contains "$manifest" "$expected_checksum" \
    || _fail "manifest must contain the sha256 checksum '$expected_checksum' for '$rel_path'"
}

# test_write_manifest_multiple_toolchains
#
# When two toolchains are installed, both must appear in the manifest's
# toolchains list (FR-4.2).
test_write_manifest_multiple_toolchains() {
  _require_function write_manifest

  local rel_path="standards/global/testing.md"
  mkdir -p "$TEST_DIR/standards/global"
  echo "# Testing" > "$TEST_DIR/$rel_path"

  write_manifest "$TEST_DIR" "v1.2.3" "claude copilot" "$rel_path" \
    || _fail "write_manifest exited non-zero"

  local manifest="$TEST_DIR/.prospect-manifest.json"
  local content
  content="$(cat "$manifest")"

  assert_contains "$content" "claude" \
    || _fail "manifest must mention 'claude' toolchain"

  assert_contains "$content" "copilot" \
    || _fail "manifest must mention 'copilot' toolchain"
}

# ── Tests: read_manifest_version ──────────────────────────────────────────────

# test_read_manifest_version
#
# read_manifest_version <target_dir> must return the version string from an
# existing .prospect-manifest.json (FR-4.3).
test_read_manifest_version() {
  _require_function read_manifest_version

  # Write a minimal manifest by hand so this test is independent of
  # write_manifest.
  cat > "$TEST_DIR/.prospect-manifest.json" <<'EOF'
{"version":"v2.5.1","toolchains":["claude"],"files":{}}
EOF

  local result
  result="$(read_manifest_version "$TEST_DIR")" \
    || _fail "read_manifest_version exited non-zero"

  assert_eq "v2.5.1" "$result" \
    || _fail "read_manifest_version should return 'v2.5.1', got '$result'"
}

# ── Tests: read_manifest_toolchains ───────────────────────────────────────────

# test_read_manifest_toolchains
#
# read_manifest_toolchains <target_dir> must return the toolchains field from
# the manifest so the installer can default to the previous selection on update
# (FR-4.3).
test_read_manifest_toolchains() {
  _require_function read_manifest_toolchains

  cat > "$TEST_DIR/.prospect-manifest.json" <<'EOF'
{"version":"v1.0.0","toolchains":["claude","copilot"],"files":{}}
EOF

  local result
  result="$(read_manifest_toolchains "$TEST_DIR")" \
    || _fail "read_manifest_toolchains exited non-zero"

  assert_contains "$result" "claude" \
    || _fail "read_manifest_toolchains must include 'claude'"

  assert_contains "$result" "copilot" \
    || _fail "read_manifest_toolchains must include 'copilot'"
}

# ── Tests: read_manifest_checksum ─────────────────────────────────────────────

# test_read_manifest_checksum
#
# read_manifest_checksum <target_dir> <relative_path> must return the stored
# sha256 checksum for the given path from the manifest (FR-3.2 / FR-4.2).
test_read_manifest_checksum() {
  _require_function read_manifest_checksum

  local rel_path=".claude/agents/sdd-architect.md"
  local fake_checksum="abc123def456abc123def456abc123def456abc123def456abc123def456abc1"

  # Write a minimal manifest by hand with a known checksum.
  cat > "$TEST_DIR/.prospect-manifest.json" <<EOF
{"version":"v1.0.0","toolchains":["claude"],"files":{".claude/agents/sdd-architect.md":"$fake_checksum"}}
EOF

  local result
  result="$(read_manifest_checksum "$TEST_DIR" "$rel_path")" \
    || _fail "read_manifest_checksum exited non-zero"

  assert_eq "$fake_checksum" "$result" \
    || _fail "read_manifest_checksum should return '$fake_checksum', got '$result'"
}

# test_read_manifest_checksum_unknown_path_returns_empty_or_nonzero
#
# Querying a path that is not in the manifest must either return an empty
# string or exit non-zero — the caller distinguishes "new file" from
# "known file" based on this (FR-3.1 / FR-3.2).
test_read_manifest_checksum_unknown_path_returns_empty_or_nonzero() {
  _require_function read_manifest_checksum

  cat > "$TEST_DIR/.prospect-manifest.json" <<'EOF'
{"version":"v1.0.0","toolchains":["claude"],"files":{}}
EOF

  local result status
  status=0
  result="$(read_manifest_checksum "$TEST_DIR" "standards/global/testing.md")" \
    || status=$?

  # Accept either: exit non-zero, OR exit 0 with an empty/blank result.
  if [[ $status -eq 0 ]]; then
    [[ -z "${result// /}" ]] \
      || _fail "unknown path: expected empty result or non-zero exit, got '$result'"
  fi
}

# ── Tests: write_version_file ─────────────────────────────────────────────────

# test_write_version_file
#
# write_version_file <target_dir> <version> must create .prospect-version in
# target_dir whose content is exactly the version tag (FR-4.1).
test_write_version_file() {
  _require_function write_version_file

  write_version_file "$TEST_DIR" "v1.0.0" \
    || _fail "write_version_file exited non-zero"

  local version_file="$TEST_DIR/.prospect-version"
  assert_file_exists "$version_file" ".prospect-version must be created" \
    || _fail ".prospect-version was not created"

  local content
  content="$(cat "$version_file")"

  assert_contains "$content" "v1.0.0" \
    || _fail ".prospect-version must contain 'v1.0.0', got '$content'"
}

# test_write_version_file_overwrites_existing
#
# Re-running write_version_file with a newer version must update the file —
# idempotency requirement (FR-7.3).
test_write_version_file_overwrites_existing() {
  _require_function write_version_file

  # Write an old version first.
  echo "v0.9.0" > "$TEST_DIR/.prospect-version"

  write_version_file "$TEST_DIR" "v1.1.0" \
    || _fail "write_version_file exited non-zero on overwrite"

  local content
  content="$(cat "$TEST_DIR/.prospect-version")"

  assert_contains "$content" "v1.1.0" \
    || _fail ".prospect-version should now contain 'v1.1.0', got '$content'"

  assert_not_contains "$content" "v0.9.0" \
    || _fail ".prospect-version must not retain old version 'v0.9.0'"
}

# ── Run ────────────────────────────────────────────────────────────────────────

run_tests
