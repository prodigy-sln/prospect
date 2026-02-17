---
name: sdd-validate
description: "Phase 6: Verify implementation matches the specification — checks requirements, tests, quality, and scope"
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Validate Implementation

Verify implementation matches the specification.

## Prerequisites

- All tasks in `tasks.md` should be complete
- All tests should be passing
- Coverage threshold should be met

---

## Step 1: Load Context

Read these files:

1. **Specification**: `specs/active/[folder]/spec.md`
2. **Tasks**: `specs/active/[folder]/tasks.md`
3. **Standards**: `standards/global/code-quality.md`, `standards/global/testing.md`

---

## Step 2: Requirements Verification (Delegate to Explore subagent)

Use the **Task tool** with `subagent_type: Explore` to verify requirements across the codebase. This preserves context on the main conversation.

### Launch Explore Subagent

Extract all FR-X.X requirements from spec.md, then delegate:

```
Verify the implementation of the following functional requirements from the spec.
For each requirement, search the codebase and report:

| Requirement | Implemented? | Implementation Location | Test Coverage | Acceptance Criteria Met? |
|-------------|-------------|------------------------|---------------|------------------------|
| FR-X.X: [description] | Yes/No/Partial | [file:line] | [test file and names] | Yes/No |

Requirements to verify:
[list all FR-X.X from spec.md]

Also check the "Out of Scope" section from the spec:
[list all out-of-scope items]

For each out-of-scope item, confirm it was NOT implemented:
| Out-of-Scope Item | Confirmed NOT Implemented? | Evidence |
|-------------------|---------------------------|----------|

Finally, check for scope creep:
- Any features added beyond spec requirements?
- Any "improvements" to unrelated code?
- Any additional dependencies without justification?
```

### Process Verification Report

Use the Explore subagent's findings for the validation report in Step 6.

---

## Step 3: Test Verification

Run the complete test suite:

```bash
[project-specific test command]
```

Verify:
- [ ] All tests pass
- [ ] No skipped tests without justification
- [ ] Coverage meets threshold from spec (typically 80%, critical paths 100%)

---

## Step 4: Code Quality Verification

Check against `standards/global/code-quality.md`:

- [ ] **Simplicity**: No premature abstractions, no YAGNI violations
- [ ] **Organization**: Single responsibility, appropriate file sizes
- [ ] **Naming**: Follows conventions, meaningful names
- [ ] **Error Handling**: Explicit handling, specific messages
- [ ] **Dependencies**: Correct direction, injected appropriately
- [ ] **Security**: Input validated, no secrets in code

---

## Step 5: Scope Verification

Scope verification is included in the Explore subagent delegation from Step 2. Review the out-of-scope and scope creep sections from the subagent's report.

Verify from the report:
- [ ] All out-of-scope items confirmed NOT implemented
- [ ] No features added beyond spec requirements
- [ ] No "improvements" to unrelated code
- [ ] No additional dependencies without justification

---

## Step 6: Generate Validation Report

Write to `specs/active/[folder]/validation-report.md`:

```markdown
# Validation Report: [Feature Title]

**Date**: [today]
**Spec**: [link to spec.md]

## Summary

| Category | Status | Details |
|----------|--------|---------|
| Requirements | [PASS/FAIL] | [X]/[Y] implemented |
| Tests | [PASS/FAIL] | [X] passing, [Y]% coverage |
| Code Quality | [PASS/FAIL] | [issues found or "No issues"] |
| Scope Control | [PASS/FAIL] | [violations found or "No violations"] |

## Overall Status: [PASS / FAIL / NEEDS REVIEW]

## Requirements Verification
[Detailed table of each FR-X.X]

## Test Results
[Test command, results, coverage breakdown]

## Code Quality Check
[Checklist results and any issues]

## Scope Verification
[Out-of-scope items verified, scope creep check]

## Sign-off
- [ ] All requirements implemented
- [ ] All tests passing
- [ ] Coverage thresholds met
- [ ] Code quality standards met
- [ ] No scope violations

**Ready for completion**: [YES / NO]
```

---

## Output

```
## Validation Complete

**Report**: `specs/active/[folder]/validation-report.md`

### Summary
| Check | Result |
|-------|--------|
| Requirements | [X]/[Y] implemented |
| Tests | [X] passing, [Y]% coverage |
| Code Quality | [PASS/issues found] |
| Scope | [No violations/violations found] |

### Overall: [PASS / NEEDS FIXES]
```

**If PASS**: Ready for completion. Run: `/sdd-complete`

**If NEEDS FIXES**: List issues to address, then re-run `/sdd-validate`.
