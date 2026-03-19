#!/usr/bin/env bash
# Test helper utilities — plain bash, no dependencies
#
# Usage in test files:
#   source "$(dirname "$0")/../helpers/setup.bash"
#
#   test_something() { ... assert_eq "a" "a"; }
#   run_tests

set -euo pipefail

_TESTS_PASS=0
_TESTS_FAIL=0
_TESTS_RUN=0

# ── Temp directory management ──

setup_test_dir() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
}

teardown_test_dir() {
  if [[ -n "${TEST_DIR:-}" && -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
}

# ── Assertions ──

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-}"
  if [[ "$expected" != "$actual" ]]; then
    echo "    FAIL: ${msg:-assert_eq}" >&2
    echo "      expected: '$expected'" >&2
    echo "      actual:   '$actual'" >&2
    return 1
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-}"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "    FAIL: ${msg:-assert_contains}" >&2
    echo "      expected to contain: '$needle'" >&2
    echo "      in: '$haystack'" >&2
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" msg="${3:-}"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "    FAIL: ${msg:-assert_not_contains}" >&2
    echo "      expected NOT to contain: '$needle'" >&2
    echo "      in: '$haystack'" >&2
    return 1
  fi
}

assert_file_exists() {
  local file="$1" msg="${2:-}"
  if [[ ! -f "$file" ]]; then
    echo "    FAIL: ${msg:-file should exist: $file}" >&2
    return 1
  fi
}

assert_file_not_exists() {
  local file="$1" msg="${2:-}"
  if [[ -f "$file" ]]; then
    echo "    FAIL: ${msg:-file should NOT exist: $file}" >&2
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1" msg="${2:-}"
  if [[ ! -d "$dir" ]]; then
    echo "    FAIL: ${msg:-directory should exist: $dir}" >&2
    return 1
  fi
}

assert_file_contains() {
  local file="$1" expected="$2" msg="${3:-}"
  if ! grep -q "$expected" "$file" 2>/dev/null; then
    echo "    FAIL: ${msg:-file '$file' should contain '$expected'}" >&2
    return 1
  fi
}

assert_status() {
  local expected="$1" actual="$2" msg="${3:-}"
  if [[ "$expected" -ne "$actual" ]]; then
    echo "    FAIL: ${msg:-exit status}" >&2
    echo "      expected status: $expected" >&2
    echo "      actual status:   $actual" >&2
    return 1
  fi
}

# ── Mock artifact creation ──

create_mock_artifact() {
  local dest="${1:?dest_dir required}"
  local version="${2:-v1.0.0}"
  local root="$dest/prospect-${version}"

  mkdir -p "$root/.claude/agents"
  mkdir -p "$root/.claude/skills/sdd-start"
  mkdir -p "$root/.github/agents"
  mkdir -p "$root/.github/prompts"
  mkdir -p "$root/.github/instructions"
  mkdir -p "$root/standards/global"
  mkdir -p "$root/specs/_templates"
  mkdir -p "$root/specs/active"
  mkdir -p "$root/specs/implemented"
  mkdir -p "$root/product"

  echo "# Architect Agent" > "$root/.claude/agents/sdd-architect.md"
  echo "---" > "$root/.claude/skills/sdd-start/SKILL.md"
  echo "# Start Agent" > "$root/.github/agents/sdd-start.agent.md"
  echo "---" > "$root/.github/prompts/sdd-start.prompt.md"
  echo "# Context" > "$root/.github/instructions/sdd-context.md"
  echo "# Copilot Instructions" > "$root/.github/copilot-instructions.md"
  echo "# Code Quality" > "$root/standards/global/code-quality.md"
  echo "# Testing" > "$root/standards/global/testing.md"
  echo "# Git Workflow" > "$root/standards/global/git-workflow.md"
  echo "# CLAUDE.md template" > "$root/CLAUDE.md"
  echo "# Spec Template" > "$root/specs/_templates/spec.template.md"
  echo "# Tasks Template" > "$root/specs/_templates/tasks.template.md"
  echo "# Mission Template" > "$root/product/mission.template.md"
  echo "# Roadmap Template" > "$root/product/roadmap.template.md"
  touch "$root/specs/active/.gitkeep"
  touch "$root/specs/implemented/.gitkeep"
  echo "# README" > "$root/README.md"

  echo "$root"
}

# ── SHA-256 checksum (cross-platform) ──

compute_checksum() {
  local file="${1:?file required}"
  if command -v sha256sum &>/dev/null; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    # PowerShell fallback on Windows/Git Bash
    powershell.exe -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '$file').Hash.ToLower()" 2>/dev/null || {
      echo "ERROR: no sha256 tool found" >&2
      return 1
    }
  fi
}

# ── Test runner ──

run_tests() {
  local funcs
  funcs=$(declare -F | awk '{print $3}' | grep '^test_' || true)

  if [[ -z "$funcs" ]]; then
    echo "  (no test_ functions found)"
    return 0
  fi

  for fn in $funcs; do
    _TESTS_RUN=$((_TESTS_RUN + 1))
    # Run each test in a subshell for isolation
    if ( setup_test_dir; "$fn"; teardown_test_dir ); then
      _TESTS_PASS=$((_TESTS_PASS + 1))
      echo "  ✓ $fn"
    else
      _TESTS_FAIL=$((_TESTS_FAIL + 1))
      echo "  ✗ $fn"
      teardown_test_dir 2>/dev/null || true
    fi
  done

  echo "  ──"
  echo "  $_TESTS_PASS/$_TESTS_RUN passed"

  [[ $_TESTS_FAIL -eq 0 ]]
}
