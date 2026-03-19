---
name: sdd-validate
description: "Phase 6: Verify implementation matches the specification — checks requirements, tests, quality, and scope"
argument-hint: ""
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

## Step 2: Requirements Verification (Delegate to sdd-verifier subagent)

Use the **Task tool** with `subagent_type: "sdd-verifier"` to verify requirements across the codebase. Do not parallelize verification with report writing—wait for the verifier output before drafting the validation report.

### Launch Verifier Subagent

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

Use the sdd-verifier subagent's findings for the validation report in Step 7.

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

## Step 4: Code Review (Delegate to sdd-review subagent)

Use the **Task tool** with `subagent_type: "sdd-review"` to perform a code review. Provide spec, tasks, standards, and the latest test/coverage context.

Prompt to send:

```
Conduct a code review for the feature against spec.md, tasks.md, and standards.
Assess correctness, architecture alignment, code quality, testing completeness, security, performance, and maintainability.
Report findings with severity (blocker/major/minor/info), file:line locations, requirement IDs impacted (if any), and concrete recommendations.
Highlight positives briefly (what's working well).
Flag any refactorings needed.
```

Use the sdd-review findings in the validation report (Steps 5-7).

---

## Step 5: Code Quality Verification

Check against `standards/global/code-quality.md`:

- [ ] **Simplicity**: No premature abstractions, no YAGNI violations
- [ ] **Organization**: Single responsibility, appropriate file sizes
- [ ] **Naming**: Follows conventions, meaningful names
- [ ] **Error Handling**: Explicit handling, specific messages
- [ ] **Dependencies**: Correct direction, injected appropriately
- [ ] **Security**: Input validated, no secrets in code

---

## Step 6: Scope Verification

Scope verification is included in the sdd-verifier subagent delegation from Step 2. Review the out-of-scope and scope creep sections from the subagent's report.

Verify from the report:
- [ ] All out-of-scope items confirmed NOT implemented
- [ ] No features added beyond spec requirements
- [ ] No "improvements" to unrelated code
- [ ] No additional dependencies without justification

---

## Step 7: Generate Validation Report

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
| Code Review | [PASS/FAIL] | [issues found or "No issues"] |
| Code Quality | [PASS/FAIL] | [issues found or "No issues"] |
| Scope Control | [PASS/FAIL] | [violations found or "No violations"] |

## Overall Status: [PASS / FAIL / NEEDS REVIEW]

## Requirements Verification
[Detailed table of each FR-X.X]

## Test Results
[Test command, results, coverage breakdown]

## Code Review
[Summary of findings from sdd-review: blockers/majors/minors, positives, refactoring recommendations]

## Code Quality Check
[Checklist results and any issues]

## Scope Verification
[Out-of-scope items verified, scope creep check]

## Sign-off
- [ ] All requirements implemented
- [ ] All tests passing
- [ ] Coverage thresholds met
- [ ] Code review issues addressed
- [ ] Code quality standards met
- [ ] No scope violations

**Ready for completion**: [YES / NO]
```

---

## Step 8: Commit the documents

Ensure the `specs/active/[folder]/validation-report.md` and `specs/active/[folder]/code-review.md` files are committed to the repository. If any issues were found, ensure they are documented in the report and that the report is updated after fixes are made.

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
| Code Review | [PASS/issues found] |
| Code Quality | [PASS/issues found] |
| Scope | [No violations/violations found] |

### Overall: [PASS / NEEDS FIXES]
```

**If PASS**: Ready for completion. Run: `/sdd-complete`

**If NEEDS FIXES**: List issues to address, then re-run `/sdd-validate`.
