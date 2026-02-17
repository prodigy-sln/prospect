---
name: sdd-validate
description: Phase 6 - Verify implementation matches specification
tools:
  - agent
  - read
  - execute
  - edit
  - search
  - web
  - mcp_io_github_ups_resolve-library-id
  - mcp_io_github_ups_get-library-docs
  - search/codebase
handoffs:
  - label: Complete Feature
    agent: sdd-complete
    prompt: Finalize and move spec to implemented
    send: true
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

## Step 2: Requirements Verification

For each functional requirement (FR-X.X) in the spec:

```
┌─────────────────────────────────────────────────────────┐
│ FR-X.X: [Requirement description]                       │
├─────────────────────────────────────────────────────────┤
│ Implemented: [ ] Yes  [ ] No  [ ] Partial               │
│ Location: [file path and line numbers]                  │
│ Tests: [test file and test names]                       │
│ Acceptance criteria met: [ ] Yes  [ ] No                │
│ Notes: [any observations]                               │
└─────────────────────────────────────────────────────────┘
```

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

### Checklist

- [ ] **Simplicity**: No premature abstractions, no YAGNI violations
- [ ] **Organization**: Single responsibility, appropriate file sizes
- [ ] **Naming**: Follows conventions, meaningful names
- [ ] **Error Handling**: Explicit handling, specific messages
- [ ] **Dependencies**: Correct direction, injected appropriately
- [ ] **Security**: Input validated, no secrets in code

---

## Step 5: Scope Verification (CRITICAL)

Check the "Out of Scope" section from spec:

### Verify None of These Were Implemented

For each out-of-scope item:
- [ ] Confirmed NOT implemented

### Check for Scope Creep

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

---

## Requirements Verification

### Implemented

| ID | Requirement | Location | Tests | Status |
|----|-------------|----------|-------|--------|
| FR-1.1 | [desc] | [path] | [tests] | ✓ |
| FR-1.2 | [desc] | [path] | [tests] | ✓ |

### Not Implemented (if any)

| ID | Requirement | Reason |
|----|-------------|--------|
| FR-X.X | [desc] | [why] |

---

## Test Results

**Command**: `[test command]`
**Result**: [X] tests, [Y] passing, [Z] failing

### Coverage

| Category | Target | Actual | Status |
|----------|--------|--------|--------|
| Overall | [X]% | [Y]% | [PASS/FAIL] |
| Business Logic | 90% | [Y]% | [PASS/FAIL] |
| Critical Paths | 100% | [Y]% | [PASS/FAIL] |

---

## Code Quality Check

- [x] No premature abstractions
- [x] Single responsibility followed
- [x] Meaningful names throughout
- [x] Explicit error handling
- [ ] [Any issues found]

### Issues (if any)

| Issue | Location | Severity | Recommendation |
|-------|----------|----------|----------------|
| [desc] | [path] | [High/Med/Low] | [fix] |

---

## Scope Verification

### Out of Scope Items Verified

| Item | Verified Not Implemented |
|------|--------------------------|
| [item 1] | ✓ |
| [item 2] | ✓ |

### Scope Creep Check

- [x] No features beyond spec
- [x] No unrelated changes
- [x] No unjustified dependencies

---

## Recommendations

### Before Completion (if FAIL)

[Issues that must be fixed]

### Future Improvements

[Suggestions for future iterations - NOT this spec]

---

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

**If PASS**: Ready for completion.

**If NEEDS FIXES**: List issues to address, then re-run validation.
