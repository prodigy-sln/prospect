# Task Breakdown: Install & Update Script

**Spec**: `specs/active/2026-03-19-install-script/spec.md`
**Branch**: `feature/2026-03-19-install-script`
**Created**: 2026-03-19

## Overview

| Metric | Count |
|--------|-------|
| Total Tasks | 38 |
| Phases | 6 |
| Test Tasks | 14 |
| Implementation Tasks | 24 |

## Task Format

```
- [ ] [ID] [P?] [Domain] Description — path/to/file
      └── Acceptance: [How to verify completion]
```

- `[P]` = Parallelizable (can run concurrently with other [P] tasks)
- Domain tags: `[INFRA]` `[TEST]` `[SCRIPT]` `[CI]`

---

## Phase 1: Setup & Infrastructure

**Dependencies**: None
**Goal**: Test framework and project structure ready

- [x] T001 [INFRA] Verify feature branch and spec folder structure ✓ 2026-03-19
      └── Acceptance: Branch `feature/2026-03-19-install-script` exists, spec folder initialized

- [x] T002 [INFRA] Set up plain bash test runner — tests/run.sh ✓ 2026-03-19
      └── Acceptance: `bash tests/run.sh` discovers and runs all *_test.sh files; no external dependencies
      └── Depends on: T001

- [x] T003 [INFRA] Create test helper utilities — tests/helpers/setup.bash ✓ 2026-03-19
      └── Acceptance: Assertions (assert_eq, assert_file_exists, etc.), temp dir management, mock artifact creation, checksum helper
      └── Depends on: T002

**Phase 1 Checklist**:
- [x] Feature branch created
- [x] Test framework configured (plain bash)
- [x] Test helpers ready

---

## Phase 2: Core Logic — Bash Script (TDD)

**Dependencies**: Phase 1
**Goal**: Fully functional `install.sh` with all features

### 2.1 Argument Parsing & Version Resolution Tests (RED)

- [x] T004 [TEST] [SCRIPT] Write tests for argument parsing — tests/bash/args_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; cover `--claude`, `--copilot`, `--all`, version argument, `--help`
      └── Requirements: FR-1.4, FR-2.5

- [x] T005 [P] [TEST] [SCRIPT] Write tests for version resolution — tests/bash/version_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; cover latest version fetch, specific version fetch, API failure fallback
      └── Requirements: FR-1.4, FR-7.2

### 2.2 Argument Parsing & Version Resolution (GREEN)

- [x] T006 [SCRIPT] Implement argument parsing and help — install.sh ✓ 2026-03-19
      └── Acceptance: T004 tests pass
      └── Depends on: T004

- [x] T007 [SCRIPT] Implement version resolution (GitHub API + fallback) — install.sh ✓ 2026-03-19
      └── Acceptance: T005 tests pass
      └── Depends on: T005

### 2.3 Download & Extract Tests (RED)

- [x] T008 [TEST] [SCRIPT] Write tests for download and extraction — tests/bash/download_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; cover successful download, extraction to temp dir, cleanup on exit
      └── Requirements: FR-1.1

### 2.4 Download & Extract (GREEN)

- [x] T009 [SCRIPT] Implement download, extraction, and temp dir management — install.sh ✓ 2026-03-19
      └── Acceptance: T008 tests pass; trap handler cleans up temp on exit/error
      └── Depends on: T007, T008

### 2.5 Toolchain Selection Tests (RED)

- [x] T010 [TEST] [SCRIPT] Write tests for toolchain selection — tests/bash/toolchain_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; cover interactive prompt, flag override, manifest-based default, non-interactive default
      └── Requirements: FR-2.1, FR-2.5, FR-4.3

### 2.6 Toolchain Selection (GREEN)

- [x] T011 [SCRIPT] Implement toolchain selection (interactive + flags + manifest default) — install.sh ✓ 2026-03-19
      └── Acceptance: T010 tests pass
      └── Depends on: T009, T010

### 2.7 File Categorization & Manifest Tests (RED)

- [x] T012 [TEST] [SCRIPT] Write tests for file categorization and manifest — tests/bash/manifest_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; cover framework-managed vs user-customizable vs user-created classification, manifest read/write, checksum computation
      └── Requirements: FR-4.1, FR-4.2, FR-5.1, FR-5.2, FR-5.3, FR-5.4

### 2.8 File Categorization & Manifest (GREEN)

- [x] T013 [SCRIPT] Implement file categorization, SHA-256 checksums, and manifest read/write — install.sh ✓ 2026-03-19
      └── Acceptance: T012 tests pass
      └── Depends on: T011, T012

### 2.9 Install & Conflict Detection Tests (RED)

- [x] T014 [TEST] [SCRIPT] Write tests for fresh install and conflict detection — tests/bash/install_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; cover fresh install (all files copied), update without conflicts (overwrite), update with conflicts (.prospect-incoming), idempotency, copilot-instructions.md merge suggestion, non-git warning
      └── Requirements: FR-3.1, FR-3.2, FR-3.3, FR-3.4, FR-3.5, FR-6.1, FR-6.2, FR-7.1, FR-7.3

### 2.10 Install & Conflict Detection (GREEN)

- [x] T015 [SCRIPT] Implement fresh install flow — install.sh ✓ 2026-03-19
      └── Acceptance: Fresh install tests in T014 pass; all selected files copied, manifest written, version file written
      └── Depends on: T013, T014

- [x] T016 [SCRIPT] Implement update flow with conflict detection — install.sh ✓ 2026-03-19
      └── Acceptance: Conflict detection tests in T014 pass; unmodified files overwritten, modified files get .prospect-incoming, summary printed
      └── Depends on: T015

- [x] T017 [SCRIPT] Implement edge cases (non-git warning, copilot-instructions.md notification, idempotency) — install.sh ✓ 2026-03-19
      └── Acceptance: All T014 tests pass
      └── Depends on: T016

### 2.11 Bash Verification

- [x] T018 [TEST] [SCRIPT] Run all bash tests — verify GREEN ✓ 2026-03-19
      └── 55/55 tests passing across 7 files
      └── Acceptance: All T004, T005, T008, T010, T012, T014 tests pass
      └── Depends on: T017

**Phase 2 Checklist**:
- [ ] All bash tests written and passing
- [ ] install.sh handles fresh install, update, conflicts, toolchain selection
- [ ] Manifest and version tracking works

---

## Phase 3: PowerShell Script (TDD)

**Dependencies**: Phase 2 (uses same logic design, parallel structure)
**Goal**: Fully functional `install.ps1` matching bash behavior

### 3.1 PowerShell Tests (RED)

- [x] T019 [TEST] [SCRIPT] Write tests for pwsh argument parsing and version resolution — tests/pwsh/args_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; invoke install.ps1 via `pwsh -File` and verify behavior matches bash for same scenarios as T004, T005
      └── Requirements: FR-1.2, FR-1.4, FR-2.5

- [x] T020 [P] [TEST] [SCRIPT] Write tests for pwsh download, toolchain selection, and manifest — tests/pwsh/install_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; cover same scenarios as T008, T010, T012
      └── Requirements: FR-1.2, FR-4.1, FR-4.2

- [x] T021 [P] [TEST] [SCRIPT] Write tests for pwsh install flow and conflict detection — tests/pwsh/conflicts_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; cover same scenarios as T014
      └── Requirements: FR-1.2, FR-3.1–FR-3.5, FR-6.1, FR-6.2, FR-7.1, FR-7.3

### 3.2 PowerShell Implementation (GREEN)

- [x] T022 [SCRIPT] Implement install.ps1 — argument parsing, version resolution, download — install.ps1 ✓ 2026-03-19
      └── Acceptance: T019 tests pass
      └── Depends on: T019

- [x] T023 [SCRIPT] Implement install.ps1 — toolchain selection, manifest, checksums — install.ps1 ✓ 2026-03-19
      └── Acceptance: T020 tests pass
      └── Depends on: T020, T022

- [x] T024 [SCRIPT] Implement install.ps1 — install flow, conflict detection, edge cases — install.ps1 ✓ 2026-03-19
      └── Acceptance: T021 tests pass
      └── Depends on: T021, T023

### 3.3 PowerShell Verification

- [x] T025 [TEST] [SCRIPT] Run all PowerShell tests — verify GREEN ✓ 2026-03-19
      └── 20/20 PowerShell tests passing
      └── Acceptance: All T019, T020, T021 tests pass
      └── Depends on: T024

**Phase 3 Checklist**:
- [ ] All PowerShell tests written and passing
- [ ] install.ps1 produces identical results to install.sh
- [ ] Cross-platform parity verified

---

## Phase 4: Release Pipeline (TDD)

**Dependencies**: Phase 2 (needs install.sh to exist for artifact)
**Goal**: GitHub Actions workflow that produces versioned release artifacts

### 4.1 Pipeline Tests (RED)

- [x] T026 [TEST] [CI] Write tests for release artifact content — tests/release/artifact_test.sh ✓ 2026-03-19
      └── Acceptance: Tests FAIL; verify artifact contains expected files, excludes specs/active content, includes .gitkeep for empty dirs, excludes .git
      └── Requirements: FR-8.2, FR-8.3, FR-8.4

### 4.2 Pipeline Implementation (GREEN)

- [x] T027 [CI] Create release artifact build script — scripts/build-release.sh ✓ 2026-03-19
      └── Acceptance: T026 tests pass; script produces correct tarball and zip
      └── Depends on: T026

- [x] T028 [CI] Create GitHub Actions release workflow — .github/workflows/release.yml ✓ 2026-03-19
      └── Acceptance: Workflow triggers on `v*` tag push, calls build script, creates GitHub Release with artifacts and auto-generated notes
      └── Requirements: FR-8.1, FR-8.5
      └── Depends on: T027

### 4.3 Pipeline Verification

- [x] T029 [TEST] [CI] Run artifact content tests — verify GREEN ✓ 2026-03-19
      └── 8/8 artifact tests passing
      └── Acceptance: T026 tests pass; artifact structure validated
      └── Depends on: T028

**Phase 4 Checklist**:
- [ ] Release workflow triggers on tag push
- [ ] Artifact contains correct files
- [ ] Artifact excludes user content
- [ ] Empty directories preserved via .gitkeep

---

## Phase 5: Integration & E2E

**Dependencies**: Phases 2, 3, 4
**Goal**: Full install/update journeys validated end-to-end

### 5.1 E2E Tests (RED)

- [x] T030 [TEST] Write E2E test: fresh install via bash into empty directory — tests/e2e/fresh_install_test.sh ✓ 2026-03-19
      └── Acceptance: All expected files present, manifest correct, version file correct
      └── Requirements: FR-1.1, FR-1.3, FR-3.1

- [x] T031 [P] [TEST] Write E2E test: update with conflicts via bash — tests/e2e/update_conflicts_test.sh ✓ 2026-03-19
      └── Acceptance: Modified files get .prospect-incoming, unmodified files overwritten, user content preserved
      └── Requirements: FR-3.2, FR-3.3, FR-3.4, FR-5.3

- [x] T032 [P] [TEST] Write E2E test: toolchain selection produces correct file sets — tests/e2e/toolchain_selection_test.sh ✓ 2026-03-19
      └── Acceptance: Claude-only has no .github files; Copilot-only has no .claude files; both has all
      └── Requirements: FR-2.2, FR-2.3, FR-2.4

- [x] T033 [P] [TEST] Write E2E test: cross-platform parity — tests/e2e/parity_test.sh ✓ 2026-03-19
      └── Acceptance: Bash and PowerShell produce identical file trees and manifests for same input
      └── Requirements: FR-1.3

### 5.2 E2E Fixes (GREEN)

- [ ] T034 Fix any integration issues discovered by E2E tests — PENDING USER TESTING
      └── Acceptance: All T030–T033 tests pass
      └── Depends on: T030, T031, T032, T033

### 5.3 Final Verification

- [ ] T035 [TEST] Run complete test suite — verify ALL GREEN
      └── Acceptance: All tests pass (T004–T033); zero warnings and errors
      └── Depends on: T034

- [ ] T036 Verify test coverage meets threshold
      └── Acceptance: Coverage >= 80%; conflict detection, manifest handling, file categorization at 100%
      └── Depends on: T035

**Phase 5 Checklist**:
- [ ] E2E tests passing
- [ ] All unit/integration tests passing
- [ ] Coverage threshold met
- [ ] No regressions
- [ ] Zero warnings and errors

---

## Phase 6: Polish & Documentation

**Dependencies**: Phase 5
**Goal**: Production-ready scripts with updated README

- [x] T037 [P] Update README.md install instructions — README.md ✓ 2026-03-19
      └── Acceptance: One-liner `curl` and PowerShell commands documented; manual install instructions updated to reference script; flag options documented

- [ ] T038 [P] Code review self-check against coding standards
      └── Acceptance: Scripts comply with standards/global/code-quality.md; shellcheck passes for install.sh; no warnings

**Phase 6 Checklist**:
- [ ] README updated with install commands
- [ ] Code standards compliance verified
- [ ] shellcheck clean

---

## Execution Summary

### Recommended Order

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Bash Script) ──── Tests first, then implementation
    │
    ├──────────────────────────┐
    ▼                          ▼
Phase 3 (PowerShell)    Phase 4 (Release Pipeline)
    │                          │
    └──────────┬───────────────┘
               ▼
Phase 5 (Integration & E2E)
               │
               ▼
Phase 6 (Polish & Documentation)
```

### Parallel Opportunities

- T005 ∥ T004 (version + arg tests)
- T020 ∥ T021 (pwsh tests)
- Phase 3 ∥ Phase 4 (after Phase 2 completes)
- T031 ∥ T032 ∥ T033 (E2E tests)
- T037 ∥ T038 (polish tasks)

### Dependencies Graph

```
T001 → T002 → T003
                 │
    ┌────────────┤
    ▼            ▼
  T004         T005
    │            │
    ▼            ▼
  T006         T007
    │            │
    └──────┬─────┘
           ▼
         T008 → T009 → T010 → T011 → T012 → T013
                                                │
                                    ┌───────────┤
                                    ▼           ▼
                                  T014        T014
                                    │
                              T015 → T016 → T017 → T018
                                                      │
                              ┌───────────────────────┤
                              ▼                       ▼
                     T019,T020,T021              T026 → T027 → T028 → T029
                       │   │   │
                       ▼   ▼   ▼
                     T022→T023→T024 → T025
                                        │
                              ┌─────────┤
                              ▼
                     T030,T031,T032,T033 → T034 → T035 → T036
                                                            │
                                                    T037 ∥ T038
```

---

## Notes

[Add any implementation notes, decisions made during development, or issues encountered]
