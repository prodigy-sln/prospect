---
name: sdd-complete
description: "Phase 7: Finalize the feature — move spec to implemented, update status, generate summary"
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Complete Specification

Finalize the feature and move spec to implemented.

## Prerequisites

- Validation report shows PASS: `specs/active/[folder]/validation-report.md`
- All tests passing
- No outstanding issues

If validation hasn't passed, suggest running `/sdd-validate` first.

---

## Step 1: Verify Ready for Completion

Read the validation report and confirm:
- [ ] Overall status is PASS
- [ ] All requirements implemented
- [ ] All tests passing
- [ ] No scope violations

**If any check fails, do NOT proceed.** Run `/sdd-validate` again.

---

## Step 2: Update Spec Status

Edit `specs/active/[folder]/spec.md` frontmatter:

```yaml
---
status: implemented  # Changed from 'active'
completed: [today's date]  # Add this line
updated: [today's date]
---
```

---

## Step 3: Move to Implemented

```bash
mv specs/active/[folder-name] specs/implemented/[folder-name]
```

Final structure:
```
specs/implemented/[folder-name]/
├── spec.md
├── tasks.md
├── requirements.md
├── validation-report.md
└── visuals/
```

---

## Step 4: Update Jira (if applicable)

If spec has `jira:` in frontmatter and Jira MCP is available:
1. Transition issue to "Done" (or appropriate status)
2. Add completion comment with summary

---

## Step 5: Generate Completion Summary

```markdown
# Completion Summary: [Feature Title]

**Completed**: [today's date]
**Branch**: `[branch-name]`
**Spec**: `specs/implemented/[folder-name]/spec.md`

## What Was Built
[Brief description]

### Key Components
- [Component 1]: [path] - [description]

### Test Coverage
- Total tests: [X]
- Coverage: [Y]%

## Next Steps for User
1. Review changes on branch `[branch-name]`
2. Create Pull Request to merge into main
3. Code review
4. Merge and deploy
```

---

## Step 6: Final Git Status

```bash
git status
git log --oneline -10
```

---

## Output

```
## Feature Complete

**[Feature Title]** has been successfully implemented and validated.

### Spec Location
`specs/implemented/[folder-name]/`

### Branch
`[branch-name]` — Ready for PR

### Summary
- Requirements: [X]/[X] implemented
- Tests: [X] passing
- Coverage: [Y]%

### Jira
[Updated to Done | No Jira integration]

### Next Steps
1. Create Pull Request
2. Code Review
3. Merge to main
4. Deploy
```

---

## Workflow Complete

```
Phase 1: Initiate — Branch and folder created
Phase 2: Shape — Requirements gathered
Phase 3: Specify — Spec document written
Phase 4: Tasks — TDD task breakdown created
Phase 5: Implement — TDD implementation done
Phase 6: Validate — Implementation verified
Phase 7: Complete — Feature finalized

→ Ready for: Pull Request → Review → Merge → Deploy
```

---

## Rollback (if needed)

If completion was premature:

```bash
mv specs/implemented/[folder-name] specs/active/[folder-name]
```

Update spec.md frontmatter:
- `status: active`
- Remove `completed:` line
