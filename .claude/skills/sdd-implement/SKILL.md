---
name: sdd-implement
description: "Phase 5: Orchestrate TDD implementation using subagents for Red-Green-Refactor cycle"
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# TDD Implementation Orchestrator

Orchestrate the implementation process using specialized subagents for each TDD phase.

## Subagents

| Subagent | TDD Phase | Responsibility |
|----------|-----------|----------------|
| `sdd-test-writer` | RED | Write failing tests |
| `sdd-implementer` | GREEN | Write minimal code to pass |
| `sdd-refactorer` | REFACTOR | Improve code quality |
| `sdd-verifier` | VERIFY | Check phase completion |

## Prerequisites

- Spec: `specs/active/[folder]/spec.md`
- Tasks: `specs/active/[folder]/tasks.md`
- User has reviewed and approved both

---

## Step 1: Load Context

Read these files before starting:

1. **Specification**: `specs/active/[folder]/spec.md`
2. **Task Breakdown**: `specs/active/[folder]/tasks.md`
3. **Standards**: `standards/global/code-quality.md`, `standards/global/testing.md`
4. **Project Instructions**: `CLAUDE.md` (if exists)

---

## Step 2: Identify Progress

Check tasks.md for:
- Completed tasks: `[x]`
- Current phase
- Next task to work on
- Any blocked tasks

---

## Step 3: Process Each Phase

Phases are processed sequentially (typically: Database → Backend → Frontend → Integration).

```
FOR EACH PHASE:

  For each task in phase (sequential):

    1. Check if task is blocked
       - If blockedBy tasks not complete → skip for now
       - If ready → proceed

    2. Delegate to sdd-test-writer subagent (RED)
       - Pass: spec path, task details, standards path, requirement ID
       - Receive: test files, test names, confirmation

    3. Delegate to sdd-implementer subagent (GREEN)
       - Pass: spec path, task details, standards path, test output
       - Receive: implementation files, confirmation

    4. Delegate to sdd-refactorer subagent (REFACTOR)
       - Pass: spec path, task details, standards path, implementation files
       - Receive: refactoring summary, confirmation

    5. Mark task complete in tasks.md
       - Update: [ ] → [x]
       - Add completion date

  After all tasks in phase complete:

    6. Delegate to sdd-verifier subagent
       - Pass: spec path, phase name, completed tasks, coverage target
       - Receive: test results, coverage, issues

    7. Handle verification result
       - If PASSED → continue to next phase
       - If FAILED → report issues, ask user how to proceed
```

---

## Step 4: Subagent Delegation

Use the Task tool to delegate to each subagent. Provide full context in the prompt:

### Test Writer (RED)
```
Delegate to sdd-test-writer subagent:

Context:
- Spec: [path to spec.md]
- Task: [current task ID and full details]
- Standards: [path to testing.md]
- Requirement: [FR-X.X being implemented]

Write failing tests for this task.
```

### Implementer (GREEN)
```
Delegate to sdd-implementer subagent:

Context:
- Spec: [path to spec.md]
- Task: [current task ID and full details]
- Standards: [path to code-quality.md]
- Test files: [paths from test-writer]

Implement minimal code to pass the tests.
```

### Refactorer (REFACTOR)
```
Delegate to sdd-refactorer subagent:

Context:
- Spec: [path to spec.md]
- Task: [current task ID and full details]
- Standards: [path to code-quality.md]
- Implementation files: [paths from implementer]

Refactor while keeping tests green.
```

### Verifier (PHASE END)
```
Delegate to sdd-verifier subagent:

Context:
- Spec: [path to spec.md]
- Phase: [phase name]
- Completed tasks: [list of task IDs]
- Coverage target: [from spec or standards]

Verify phase completion and report results.
```

---

## Step 5: Scope Control (CRITICAL)

Before allowing ANY implementation:

1. Is this task in tasks.md?
2. Does this task relate to a spec requirement (FR-X.X)?
3. Is this NOT in the "Out of Scope" section?

**If NO to any → Do not implement. Note it for future work.**

The spec's "Out of Scope" section is **binding**:
- Do NOT implement out-of-scope items
- Do NOT add "improvements" beyond spec
- Do NOT refactor unrelated code

---

## Step 6: Progress Tracking

### Update tasks.md After Each Task

```markdown
- [x] T004 [TEST] Write schema tests ✓ 2026-01-29
      └── Tests: 3 added, all passing
```

### Report After Each Phase

Show tasks completed, verification results, and next phase.

---

## Step 7: Error Handling

- **Test Failure**: Re-invoke test-writer or implementer to fix
- **Blocked Task**: Check dependencies, ask user if external blocker
- **Coverage Below Target**: Re-invoke test-writer to add missing tests

---

## Output

When implementation session ends (complete or paused):

```
## Implementation Progress

**Spec**: `specs/active/[folder]/spec.md`

### Session Summary
| Phase | Status | Tasks | Tests | Coverage |
|-------|--------|-------|-------|----------|
| Database | Complete | 3/3 | 12 | 95% |
| Backend | Complete | 5/5 | 24 | 88% |
| Frontend | In Progress | 2/4 | 8 | 72% |
| Integration | Pending | 0/2 | - | - |

### Next Steps
[Continue implementation or proceed to validation: `/sdd-validate`]
```
