# Task Breakdown: [Feature Title]

**Spec**: [link to spec.md]
**Branch**: `feature/YYYY-MM-DD-feature-name`
**Created**: YYYY-MM-DD

## Overview

| Metric | Count |
|--------|-------|
| Total Tasks | [X] |
| Phases | [X] |
| Estimated Effort | [X hours/days] |

## Task Format

```
- [ ] [ID] [P?] [Domain] Description — path/to/file
      └── Acceptance: [How to verify completion]
```

- `[P]` = Parallelizable (can run concurrently with other [P] tasks)
- Domain tags: `[DB]` `[API]` `[UI]` `[TEST]` `[INFRA]`

---

## Phase 1: Setup & Infrastructure

**Dependencies**: None
**Goal**: Project structure and foundational infrastructure ready

- [ ] T001 [INFRA] Create feature branch and spec folder structure
      └── Acceptance: Branch exists, specs/active/[name]/ initialized

- [ ] T002 [INFRA] Configure test environment for this feature
      └── Acceptance: Test runner configured, baseline tests pass

- [ ] T003 [P] [INFRA] Set up required dependencies/packages
      └── Acceptance: All dependencies installed, no version conflicts

**Phase 1 Checklist**:
- [ ] Feature branch created
- [ ] Folder structure in place
- [ ] Test environment ready
- [ ] Dependencies installed

---

## Phase 2: Database Layer (TDD)

**Dependencies**: Phase 1
**Goal**: Data models and persistence layer complete with passing tests

### 2.1 Database Tests (Write First — RED)

- [ ] T004 [TEST] [DB] Write schema validation tests — tests/db/[model]_schema_test.[ext]
      └── Acceptance: Tests exist and FAIL (no implementation yet)
      └── Tests: Table structure, constraints, indexes

- [ ] T005 [P] [TEST] [DB] Write model validation tests — tests/db/[model]_validation_test.[ext]
      └── Acceptance: Tests exist and FAIL
      └── Tests: Required fields, data types, business rules

- [ ] T006 [P] [TEST] [DB] Write relationship tests — tests/db/[model]_relations_test.[ext]
      └── Acceptance: Tests exist and FAIL
      └── Tests: Foreign keys, cascades, associations

### 2.2 Database Implementation (Make Tests Pass — GREEN)

- [ ] T007 [DB] Create database migration — db/migrations/[timestamp]_create_[table].sql
      └── Acceptance: Migration runs successfully
      └── Depends on: T004

- [ ] T008 [DB] Create model with validations — src/models/[model].[ext]
      └── Acceptance: T005 tests pass
      └── Depends on: T007

- [ ] T009 [DB] Set up model associations — src/models/[model].[ext]
      └── Acceptance: T006 tests pass
      └── Depends on: T008

### 2.3 Database Verification

- [ ] T010 [TEST] [DB] Run all database tests — verify GREEN
      └── Acceptance: All T004-T006 tests pass
      └── Command: [test command for db tests]

**Phase 2 Checklist**:
- [ ] All database tests written (T004-T006)
- [ ] All database tests passing (T010)
- [ ] Migration runs cleanly
- [ ] Models validated

---

## Phase 3: Backend/API Layer (TDD)

**Dependencies**: Phase 2
**Goal**: API endpoints and business logic complete with passing tests

### 3.1 API Contract Tests (Write First — RED)

- [ ] T011 [TEST] [API] Write API contract tests — tests/api/[resource]_contract_test.[ext]
      └── Acceptance: Tests exist and FAIL
      └── Tests: Request validation, response schemas, status codes

- [ ] T012 [P] [TEST] [API] Write authentication/authorization tests — tests/api/[resource]_auth_test.[ext]
      └── Acceptance: Tests exist and FAIL
      └── Tests: Auth required, permission checks, token validation

- [ ] T013 [P] [TEST] [API] Write business logic tests — tests/services/[service]_test.[ext]
      └── Acceptance: Tests exist and FAIL
      └── Tests: Core business rules, edge cases, error handling

### 3.2 API Implementation (Make Tests Pass — GREEN)

- [ ] T014 [API] Implement service/business logic — src/services/[service].[ext]
      └── Acceptance: T013 tests pass
      └── Depends on: T010 (database ready)

- [ ] T015 [API] Implement controller/endpoint — src/controllers/[resource].[ext]
      └── Acceptance: T011 tests pass
      └── Depends on: T014

- [ ] T016 [API] Implement auth middleware/guards — src/middleware/[auth].[ext]
      └── Acceptance: T012 tests pass
      └── Depends on: T015

- [ ] T017 [API] Add API routes configuration — src/routes/[resource].[ext]
      └── Acceptance: Endpoints accessible
      └── Depends on: T015, T016

### 3.3 API Verification

- [ ] T018 [TEST] [API] Run all API tests — verify GREEN
      └── Acceptance: All T011-T013 tests pass
      └── Command: [test command for api tests]

**Phase 3 Checklist**:
- [ ] All API tests written (T011-T013)
- [ ] All API tests passing (T018)
- [ ] Endpoints documented
- [ ] Auth working correctly

---

## Phase 4: Frontend/UI Layer (TDD)

**Dependencies**: Phase 3
**Goal**: UI components and user interactions complete with passing tests

### 4.1 Component Tests (Write First — RED)

- [ ] T019 [TEST] [UI] Write component render tests — tests/components/[Component]_test.[ext]
      └── Acceptance: Tests exist and FAIL
      └── Tests: Renders correctly, props handled, states displayed

- [ ] T020 [P] [TEST] [UI] Write interaction tests — tests/components/[Component]_interaction_test.[ext]
      └── Acceptance: Tests exist and FAIL
      └── Tests: User clicks, form submissions, navigation

- [ ] T021 [P] [TEST] [UI] Write form validation tests — tests/components/[Form]_validation_test.[ext]
      └── Acceptance: Tests exist and FAIL
      └── Tests: Required fields, format validation, error display

### 4.2 UI Implementation (Make Tests Pass — GREEN)

- [ ] T022 [UI] Implement base component — src/components/[Component].[ext]
      └── Acceptance: T019 tests pass
      └── Reference: visuals/[mockup].png

- [ ] T023 [UI] Implement user interactions — src/components/[Component].[ext]
      └── Acceptance: T020 tests pass
      └── Depends on: T022

- [ ] T024 [UI] Implement form with validation — src/components/[Form].[ext]
      └── Acceptance: T021 tests pass
      └── Depends on: T022

- [ ] T025 [UI] Connect to API endpoints — src/components/[Component].[ext]
      └── Acceptance: Data flows correctly
      └── Depends on: T018 (API ready), T023

- [ ] T026 [UI] Apply styling per design — src/components/[Component].css
      └── Acceptance: Matches visual design
      └── Reference: visuals/[mockup].png

### 4.3 UI Verification

- [ ] T027 [TEST] [UI] Run all component tests — verify GREEN
      └── Acceptance: All T019-T021 tests pass
      └── Command: [test command for ui tests]

**Phase 4 Checklist**:
- [ ] All UI tests written (T019-T021)
- [ ] All UI tests passing (T027)
- [ ] Components match visual design
- [ ] API integration working

---

## Phase 5: Integration & E2E (TDD)

**Dependencies**: Phase 4
**Goal**: Full user journeys validated end-to-end

### 5.1 Integration Tests (Write First — RED)

- [ ] T028 [TEST] Write E2E test for primary user journey — tests/e2e/[feature]_primary_test.[ext]
      └── Acceptance: Test exists and FAILS (or passes if all prior work complete)
      └── Tests: Complete user flow from start to finish

- [ ] T029 [P] [TEST] Write E2E test for error scenarios — tests/e2e/[feature]_errors_test.[ext]
      └── Acceptance: Test exists
      └── Tests: Error handling, validation failures, edge cases

### 5.2 Integration Fixes (Make Tests Pass — GREEN)

- [ ] T030 Fix any integration issues discovered by E2E tests
      └── Acceptance: T028-T029 tests pass
      └── Depends on: T028, T029

### 5.3 Final Verification

- [ ] T031 [TEST] Run complete test suite — verify ALL GREEN
      └── Acceptance: All tests pass (T004-T029)
      └── Command: [full test suite command]

- [ ] T032 Verify test coverage meets threshold
      └── Acceptance: Coverage >= [X]%
      └── Command: [coverage command]

**Phase 5 Checklist**:
- [ ] E2E tests passing
- [ ] All unit/integration tests passing
- [ ] Coverage threshold met
- [ ] No regressions

---

## Phase 6: Polish & Documentation

**Dependencies**: Phase 5
**Goal**: Production-ready code with documentation

- [ ] T033 [P] Code review self-check against coding standards
      └── Acceptance: Complies with standards/global/code-quality.md

- [ ] T034 [P] Update/create API documentation
      └── Acceptance: Endpoints documented with examples

- [ ] T035 [P] Add inline code documentation where needed
      └── Acceptance: Complex logic explained

- [ ] T036 Performance review (if applicable)
      └── Acceptance: Meets performance requirements from spec

**Phase 6 Checklist**:
- [ ] Code standards compliance verified
- [ ] Documentation complete
- [ ] Performance acceptable

---

## Execution Summary

### Recommended Order

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Database) ──── Tests first, then implementation
    │
    ▼
Phase 3 (API) ────────── Tests first, then implementation
    │
    ▼
Phase 4 (UI) ─────────── Tests first, then implementation
    │
    ▼
Phase 5 (Integration) ── E2E tests, final verification
    │
    ▼
Phase 6 (Polish) ─────── Documentation, cleanup
```

### Parallel Opportunities

Tasks marked `[P]` can run in parallel:
- T003, T005, T006 (setup + db tests)
- T012, T013 (API tests)
- T020, T021 (UI tests)
- T033, T034, T035 (polish tasks)

### Dependencies Graph

```
T001 → T002 → T004 → T007 → T008 → T009 → T010
                ↓
       T005 ────┘
       T006 ────┘

T010 → T011 → T015 → T017 → T018
         ↓
  T013 → T014
  T012 → T016

T018 → T019 → T022 → T023 → T025 → T027
         ↓
  T020 ─────→ T023
  T021 → T024

T027 → T028 → T030 → T031 → T032
         ↓
       T029
```

---

## Notes

[Add any implementation notes, decisions made during development, or issues encountered]

- [Date]: [Note]
