#!/usr/bin/env bash
source "$(dirname "$0")/setup.bash"

test_framework_works() {
  assert_eq "hello" "hello" "basic equality"
}

test_temp_dir_created() {
  assert_dir_exists "$TEST_DIR" "TEST_DIR should exist"
}

test_mock_artifact() {
  local artifact
  artifact="$(create_mock_artifact "$TEST_DIR" "v1.0.0")"
  assert_file_exists "$artifact/.claude/agents/sdd-architect.md"
  assert_file_exists "$artifact/standards/global/code-quality.md"
  assert_file_exists "$artifact/specs/active/.gitkeep"
}

test_checksum() {
  echo "test content" > "$TEST_DIR/testfile"
  local sum
  sum="$(compute_checksum "$TEST_DIR/testfile")"
  [ -n "$sum" ]
  assert_eq "$sum" "$(compute_checksum "$TEST_DIR/testfile")" "checksum should be deterministic"
}

run_tests
