---
name: sdd-tasks
description: "Phase 4: Create TDD-ordered task breakdown from the specification"
argument-hint: "[specification folder name, e.g. '2024-06-01-new-login-system']"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Create Task Breakdown

Generate TDD-ordered tasks from the specification.

## Prerequisites

- `specs/active/[folder]/spec.md` is complete
- If present, `specs/active/[folder]/architecture.md` is available for reference
- Open questions resolved
- Out of scope defined

---

## Step 1: Load Context

Read these files:

1. **Specification**: `specs/active/[folder]/spec.md`
2. **Task Template**: `specs/_templates/tasks.template.md`
3. **Testing Standards**: `standards/global/testing.md`
4. **Architecture Plan (optional)**: `specs/active/[folder]/architecture.md`

---

## Step 2: Analyze Requirements

Extract from spec (and architecture plan if available):

1. **Data Layer** (if applicable): New entities, migrations, validations
2. **Backend/API Layer** (if applicable): Endpoints, services, auth
3. **Frontend/UI Layer** (if applicable): Components, forms, integration
4. **Integration Points**: Existing code to connect with

Map requirements to phases:
```
FR-1.x (Data) → Phase 2: Database
FR-2.x (API)  → Phase 3: Backend
FR-3.x (UI)   → Phase 4: Frontend
All FRs        → Phase 5: Integration
```

---

## Step 3: Generate Tasks (TDD Order)

### TDD Principle (NON-NEGOTIABLE)

Within each phase, tests come FIRST:

```
1. Write tests FIRST (RED)
2. Implement to pass tests (GREEN)
3. Verify all tests pass
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
- 2.1 Tests (RED): Write schema/validation tests
- 2.2 Implementation (GREEN): Create migrations and models
- 2.3 Verification: Run all database tests

**Phase 3: Backend/API Layer (TDD)**
- 3.1 Tests (RED): Write contract and service tests
- 3.2 Implementation (GREEN): Implement services and controllers
- 3.3 Verification: Run all API tests

**Phase 4: Frontend/UI Layer (TDD)**
- 4.1 Tests (RED): Write component and interaction tests
- 4.2 Implementation (GREEN): Implement components
- 4.3 Verification: Run all UI tests

**Phase 5: Integration & E2E**
- Write E2E tests, run complete suite, verify coverage
- Ensure there are zero warnings and errors, if not they need to be fixed

**Phase 6: Polish & Documentation**
- Self-review, documentation, final cleanup

---

## Step 4: Add Metadata

Include overview table (total tasks, test vs impl count), dependencies graph, and parallel opportunities.

---

## Step 5: Jira Sync (Optional)

If Jira MCP is available and spec has `jira:` in frontmatter, offer to create subtasks in Jira.

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

### Next Steps
1. Review the tasks
2. Adjust if needed
3. When ready, run: `/sdd-implement`
```

Tell user to review tasks before proceeding.
