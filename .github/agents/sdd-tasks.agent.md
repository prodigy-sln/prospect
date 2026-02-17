---
name: sdd-tasks
description: Phase 4 - Create TDD-ordered task breakdown
tools:
  - agent
  - read
  - execute
  - edit
  - search
  - web
  - todo
  - mcp_io_github_ups_resolve-library-id
  - mcp_io_github_ups_get-library-docs
  - mcp__atlassian__createJiraIssue
  - mcp__atlassian__getJiraIssue
handoffs:
  - label: Start Implementation
    agent: sdd-implement
    prompt: Begin TDD implementation following the task breakdown
    send: true
---

# Create Task Breakdown

Generate TDD-ordered tasks from the specification.

## Prerequisites

- `specs/active/[folder]/spec.md` is complete
- Open questions resolved
- Out of scope defined

---

## Step 1: Load Context

Read these files:

1. **Specification**: `specs/active/[folder]/spec.md`
   - Functional requirements (FR-X.X)
   - Technical considerations
   - Test strategy
   - Existing code to leverage

2. **Task Template**: `specs/_templates/tasks.template.md`
   - Structure to follow
   - Phase organization

3. **Testing Standards**: `standards/global/testing.md`
   - TDD requirements
   - Coverage targets

---

## Step 2: Analyze Requirements

Extract from spec:

1. **Data Layer** (if applicable): New entities, migrations, validations
2. **Backend/API Layer** (if applicable): Endpoints, services, auth
3. **Frontend/UI Layer** (if applicable): Components, forms, integration
4. **Integration Points**: Existing code to connect with

Map requirements to phases:
```
FR-1.x (Data) → Phase 2: Database
FR-2.x (API)  → Phase 3: Backend
FR-3.x (UI)   → Phase 4: Frontend
All FRs       → Phase 5: Integration
```

---

## Step 3: Generate Tasks (TDD Order)

### TDD Principle (NON-NEGOTIABLE)

Within each phase, tests come FIRST:

```
1. Write tests FIRST (RED)
   - Tests define expected behavior
   - Tests MUST fail initially

2. Implement to pass tests (GREEN)
   - Minimal code to pass
   - No gold-plating

3. Verify all tests pass
   - Run test suite
   - Confirm coverage
```

### Task Format

```markdown
- [ ] T001 [P] [DOMAIN] Description — path/to/file
      └── Acceptance: [How to verify completion]
      └── Depends on: T000 (if applicable)
```

- `[P]` = Parallelizable (can run concurrently)
- Domain tags: `[DB]` `[API]` `[UI]` `[TEST]` `[INFRA]`

### Phase Structure

**Phase 1: Setup & Infrastructure**
- Verify branch and folder structure
- Configure test environment
- Install dependencies

**Phase 2: Database Layer (TDD)**
```
2.1 Tests (RED):
- [ ] T004 [TEST] [DB] Write schema tests
- [ ] T005 [P] [TEST] [DB] Write validation tests

2.2 Implementation (GREEN):
- [ ] T006 [DB] Create migration (depends on T004)
- [ ] T007 [DB] Implement model (depends on T006)

2.3 Verification:
- [ ] T008 [TEST] [DB] Run all database tests
```

**Phase 3: Backend/API Layer (TDD)**
```
3.1 Tests (RED):
- [ ] T009 [TEST] [API] Write contract tests
- [ ] T010 [P] [TEST] [API] Write service tests

3.2 Implementation (GREEN):
- [ ] T011 [API] Implement service (depends on T008)
- [ ] T012 [API] Implement controller (depends on T011)

3.3 Verification:
- [ ] T013 [TEST] [API] Run all API tests
```

**Phase 4: Frontend/UI Layer (TDD)**
```
4.1 Tests (RED):
- [ ] T014 [TEST] [UI] Write component tests
- [ ] T015 [P] [TEST] [UI] Write interaction tests

4.2 Implementation (GREEN):
- [ ] T016 [UI] Implement component (depends on T013)
- [ ] T017 [UI] Connect to API (depends on T016)

4.3 Verification:
- [ ] T018 [TEST] [UI] Run all UI tests
```

**Phase 5: Integration & E2E**
- Write E2E tests for primary journey
- Write error scenario tests
- Run complete test suite
- Verify coverage meets threshold

**Phase 6: Polish & Documentation**
- Self-review against code quality standards
- Update documentation
- Final cleanup

---

## Step 4: Add Metadata

### Overview Table

```markdown
| Metric | Count |
|--------|-------|
| Total Tasks | [X] |
| Phases | [X] |
| Test Tasks | [X] |
| Implementation Tasks | [X] |
```

### Dependencies Graph

Document which tasks depend on others.

### Parallel Opportunities

List tasks marked `[P]` that can run concurrently.

---

## Step 5: Jira Sync (Optional)

If Jira MCP available and spec has `jira:` in frontmatter:

1. Read parent issue key from spec
2. For each task, create subtask:
   ```
   mcp__atlassian__createJiraIssue
   - Project: [from parent]
   - IssueType: Subtask
   - Parent: [parent issue key]
   - Summary: [Task ID] [Description]
   ```
3. Add Jira links to tasks.md

---

## Output

Write to `specs/active/[folder]/tasks.md`

```
## Task Breakdown Complete

**Tasks File**: `specs/active/[folder]/tasks.md`

### Summary
| Phase | Tasks | Test Tasks | Impl Tasks |
|-------|-------|------------|------------|
| Setup | [X] | 0 | [X] |
| Database | [X] | [X] | [X] |
| Backend | [X] | [X] | [X] |
| Frontend | [X] | [X] | [X] |
| Integration | [X] | [X] | [X] |
| Polish | [X] | 0 | [X] |
| **Total** | **[X]** | **[X]** | **[X]** |

### TDD Structure
- Tests scheduled BEFORE implementation
- Each phase ends with verification
- Coverage target: [X]%

### Jira Status
[Synced to PROJ-123 | Not synced]

### Next Steps
1. Review the tasks
2. Adjust if needed
3. Proceed to implementation
```

Tell user to review tasks before proceeding.
