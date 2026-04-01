---
name: sdd-validate
description: "Phase 6: Verify implementation matches the specification — checks requirements, tests, quality, and scope"
argument-hint: ""
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Validate Implementation

Verify implementation matches the specification. Orchestrates a verifier and three focused reviewers in parallel, then merges their verdicts.

## Prerequisites

- All tasks in `tasks.md` should be complete
- All tests should be passing
- Coverage threshold should be met

---

## Completion Criteria

The overall verdict combines results from the verifier and all three reviewers:

- **PASS** = Verifier PASS **and** all three reviewers report zero Blockers, zero Majors, zero Minors
- **FAIL** = Verifier FAIL **or** any reviewer reports any Blocker, Major, or Minor

Info findings are acceptable and do not block completion. They are recorded in the report for future consideration.

---

## Step 1: Load Context

Read these files:

1. **Specification**: `specs/active/[folder]/spec.md`
2. **Tasks**: `specs/active/[folder]/tasks.md`
3. **Standards**: `standards/global/code-quality.md`, `standards/global/testing.md`
4. **Architecture (if present)**: `specs/active/[folder]/architecture.md`

---

## Step 2: Build File Manifest

The orchestrator builds a single, definitive file manifest. All reviewers receive this same manifest.

### Step 2a: Collect planned files from tasks.md

Extract every file path mentioned in tasks.md (implementation files and test files).

### Step 2b: Cross-reference with git

```bash
git diff --name-only main...HEAD 2>/dev/null || git diff --name-only HEAD~20 HEAD
```

### Step 2c: Build the manifest

The manifest is the **union** of:
- Files mentioned in tasks.md
- Files that appear in the git diff AND relate to the feature (same directories, same modules)

Exclude unrelated files that may have been touched by automated tooling (lockfiles, auto-generated code) unless they were explicitly listed in tasks.md.

Store the manifest for inclusion in reviewer prompts:

```
### File Manifest
[list every file path, one per line]
```

### Step 2d: Pass 2 additions

If this is Pass 2, check the quality reviewer's report from Pass 1 for out-of-scope files detected. Add those files to the manifest so that the correctness and coverage reviewers also evaluate them in this pass.

---

## Step 3: Determine Pass Number

Check if previous validation artifacts exist:

```bash
ls specs/active/[folder]/validation-report*.md specs/active/[folder]/review-correctness*.md specs/active/[folder]/review-coverage*.md specs/active/[folder]/review-quality*.md 2>/dev/null
```

- **No previous artifacts found**: This is Pass 1.
- **Previous artifacts found**: This is Pass 2. Archive previous artifacts first (see Step 3b).

**Hard cap: Maximum 2 full validation passes.** If Pass 2 still produces Blocker, Major, or Minor findings, escalate to the user. Do not start a Pass 3 automatically.

### Step 3b: Archive Previous Pass (Pass 2 only)

```bash
mv specs/active/[folder]/validation-report.md specs/active/[folder]/validation-report-pass-1.md
mv specs/active/[folder]/review-correctness.md specs/active/[folder]/review-correctness-pass-1.md
mv specs/active/[folder]/review-coverage.md specs/active/[folder]/review-coverage-pass-1.md
mv specs/active/[folder]/review-quality.md specs/active/[folder]/review-quality-pass-1.md
```

**Critical: Do NOT provide Pass 1 artifacts to the subagents.** Each pass must be a fresh, independent evaluation. This prevents anchoring bias.

---

## Step 4: Launch All Agents in Parallel

Launch the verifier and all three reviewers simultaneously using the Task tool. Do NOT wait for one to finish before starting another.

### 4a: Verifier (sdd-verifier)

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

### 4b: Correctness Reviewer (sdd-review-correctness)

```
Review the implementation for correctness against spec.md requirements.

For EACH FR-X.X requirement, trace the implementation logic and verify it produces the correct behavior as defined by the acceptance criteria. Check data flow across component boundaries.

### File Manifest
[paste manifest from Step 2]

Review ONLY manifest files. Produce a verdict for every FR-X.X. Report only behavioral defects, not style or test gaps.
```

### 4c: Coverage Reviewer (sdd-review-coverage)

```
Review test coverage against spec.md requirements.

For EACH FR-X.X requirement, find the corresponding tests and verify they assert the specific acceptance criteria. Identify gaps where requirements or acceptance criteria lack test coverage.

### File Manifest
[paste manifest from Step 2]

Review ONLY manifest files. Produce a verdict for every FR-X.X. Report only coverage gaps, not code quality or correctness issues.

Latest coverage output:
[paste coverage results if available from Step 4's test run]
```

### 4d: Quality Reviewer (sdd-review-quality)

```
Review code quality, pattern consistency, error handling, security, and scope compliance.

### File Manifest
[paste manifest from Step 2]

Review manifest files for quality. ALSO compare the manifest against all files changed on the branch (git diff) to detect out-of-scope changes. Report out-of-scope files but do not perform a full review on them.

SEVERITY REMINDER:
- Minor requires objective verifiability (two-developer test).
- Style preferences and subjective suggestions are Info, not Minor.
- When in doubt, classify as Info.
```

---

## Step 5: Run Tests

While agents are running, execute the full test suite:

```bash
[project-specific test command]
```

Verify:
- [ ] All tests pass
- [ ] No skipped tests without justification
- [ ] Coverage meets threshold from spec (typically 80%, critical paths 100%)

---

## Step 6: Merge Results

Wait for all four agents to complete. Collect:

- **Verifier**: requirements status, scope check
- **Correctness reviewer**: `review-correctness.md`
- **Coverage reviewer**: `review-coverage.md`
- **Quality reviewer**: `review-quality.md` (includes out-of-scope file detection)

### Aggregate findings:

```
Total Blockers = sum across all reviewers
Total Majors = sum across all reviewers
Total Minors = sum across all reviewers
Total Info = sum across all reviewers
Out-of-scope files = from quality reviewer
```

### Check for conflicting verdicts:

If the verifier says a requirement is PASS but the correctness reviewer says it's PARTIAL or FAIL, the correctness reviewer's finding takes precedence (it looked deeper at the logic).

---

## Step 7: Generate Validation Report

Write to `specs/active/[folder]/validation-report.md`:

```markdown
# Validation Report: [Feature Title]

**Date**: [today]
**Pass**: [1 or 2]
**Spec**: [link to spec.md]
**Files in Manifest**: [X]

## Summary

| Category | Status | Details |
|----------|--------|---------|
| Requirements (Verifier) | [PASS/FAIL] | [X]/[Y] implemented |
| Correctness Review | [PASS/FAIL] | Blockers: [X], Majors: [X], Minors: [X] |
| Coverage Review | [PASS/FAIL] | Blockers: [X], Majors: [X], Minors: [X] |
| Quality Review | [PASS/FAIL] | Blockers: [X], Majors: [X], Minors: [X], Info: [X] |
| Tests | [PASS/FAIL] | [X] passing, [Y]% coverage |
| Scope Control | [PASS/FAIL] | [out-of-scope files detected: X] |

## Overall Status: [PASS / FAIL / ESCALATED]

**PASS** requires ALL of:
- Verifier: all FR-X.X implemented with acceptance criteria met
- All reviewers: zero Blockers, zero Majors, zero Minors
- Tests: all passing, coverage threshold met
- Scope: no unresolved out-of-scope changes

## Correctness Review Summary
[Key findings from review-correctness.md]
[Full details: review-correctness.md]

## Coverage Review Summary
[Key findings from review-coverage.md]
[Full details: review-coverage.md]

## Quality Review Summary
[Key findings from review-quality.md, including out-of-scope files detected]
[Full details: review-quality.md]

## Test Results
[Test command, results, coverage breakdown]

## Verifier Results
[Requirements table, scope check]

## Info Findings (Non-Blocking)
[Consolidated list of all Info findings across reviewers]

## Sign-off
- [ ] All requirements implemented (verifier)
- [ ] All requirements behaviorally correct (correctness reviewer)
- [ ] All requirements tested with acceptance criteria coverage (coverage reviewer)
- [ ] Code quality standards met, no scope violations (quality reviewer)
- [ ] All tests passing, coverage thresholds met
- [ ] Zero blockers, zero majors, zero minors across all reviewers

**Ready for completion**: [YES / NO]
```

---

## Step 8: Handle Findings

### If any Blocker, Major, or Minor exists:

**Pass 1:**
1. Fix all findings (delegate to appropriate subagents or fix directly)
2. If the quality reviewer detected out-of-scope files, decide: revert the changes or add the files to the manifest for Pass 2
3. After all fixes are committed, proceed to Pass 2 (restart from Step 2, with updated manifest)

**Pass 2:**
1. Fix all findings
2. If any Blocker, Major, or Minor remains after fixes, **stop and escalate**:

```
## Validation Escalation

Findings remain after 2 full validation passes.

### Unresolved Issues
| Reviewer | Severity | File | Summary |
|----------|----------|------|---------|
| [correctness/coverage/quality] | [severity] | [path] | [issue] |

### Pass History
| Pass | Blockers | Majors | Minors | Info |
|------|----------|--------|--------|------|
| 1    | [X]      | [X]    | [X]    | [X]  |
| 2    | [X]      | [X]    | [X]    | [X]  |

These issues may require architectural changes or user decisions.
Please review and advise how to proceed.
```

### If only Info findings or clean:
- Proceed to Step 9

---

## Step 9: Commit the Documents

Ensure the following files are committed:
- `specs/active/[folder]/validation-report.md`
- `specs/active/[folder]/review-correctness.md`
- `specs/active/[folder]/review-coverage.md`
- `specs/active/[folder]/review-quality.md`
- Any archived pass artifacts (`*-pass-1.md` if this is Pass 2)

---

## Output

```
## Validation Complete

**Pass**: [1 or 2]
**Report**: `specs/active/[folder]/validation-report.md`

### Summary
| Reviewer | Blockers | Majors | Minors | Info |
|----------|----------|--------|--------|------|
| Correctness | [X] | [X] | [X] | — |
| Coverage | [X] | [X] | [X] | — |
| Quality | [X] | [X] | [X] | [X] |
| **Total** | **[X]** | **[X]** | **[X]** | **[X]** |

| Check | Result |
|-------|--------|
| Requirements | [X]/[Y] implemented |
| Tests | [X] passing, [Y]% coverage |
| Out-of-scope files | [X] detected |

### Overall: [PASS / NEEDS FIXES / ESCALATED]
```

**If PASS**: Ready for completion. Run: `/sdd-complete`

**If NEEDS FIXES (Pass 1)**: Fixing findings, then running Pass 2.

**If ESCALATED (Pass 2 with remaining issues)**: User decision required.
