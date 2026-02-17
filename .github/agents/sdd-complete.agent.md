---
name: sdd-complete
description: Phase 7 - Finalize and move spec to implemented
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
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__getJiraIssue
---

# Complete Specification

Finalize the feature and move spec to implemented.

## Prerequisites

- Validation report shows PASS: `specs/active/[folder]/validation-report.md`
- All tests passing
- No outstanding issues

If validation hasn't passed, suggest running `/sdd.validate` first.

---

## Step 1: Verify Ready for Completion

Read validation report:

```bash
cat specs/active/[folder]/validation-report.md
```

Confirm:
- [ ] Overall status is PASS
- [ ] All requirements implemented
- [ ] All tests passing
- [ ] No scope violations

**If any check fails, do NOT proceed.** Run `/sdd.validate` again.

---

## Step 2: Update Spec Status

Edit `specs/active/[folder]/spec.md` frontmatter:

```yaml
---
id: SPEC-XXX
title: [Feature Title]
status: implemented  # Changed from 'active'
branch: [branch-name]
jira: [PROJ-XXX]
created: [original date]
updated: [today's date]
completed: [today's date]  # Add this line
author: [original author]
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

If spec has `jira:` in frontmatter:

1. **Check Jira MCP availability**:
   ```
   Try: mcp__atlassian__getJiraIssue with issue key
   ```

2. **If available, transition issue**:
   ```
   mcp__atlassian__transitionJiraIssue
   - issueKey: [from spec frontmatter]
   - transition: "Done" (or appropriate status)
   ```

3. **Add completion comment** (if supported):
   ```
   Spec completed and validated.
   - All requirements implemented
   - Tests passing with [X]% coverage
   - Moved to specs/implemented/
   ```

---

## Step 5: Generate Completion Summary

```markdown
# Completion Summary: [Feature Title]

**Completed**: [today's date]
**Branch**: `[branch-name]`
**Spec**: `specs/implemented/[folder-name]/spec.md`

## What Was Built

[Brief description of the feature]

### Key Components

- [Component 1]: [path] - [description]
- [Component 2]: [path] - [description]

### API Endpoints (if applicable)

| Method | Endpoint | Description |
|--------|----------|-------------|
| [GET] | /api/[...] | [desc] |

### Database Changes (if applicable)

- [Table/Migration]: [description]

## Test Coverage

- Total tests: [X]
- Coverage: [Y]%
- Critical paths: 100%

## Files Changed

[List key files added/modified]

## Next Steps for User

1. Review changes on branch `[branch-name]`
2. Create Pull Request to merge into main
3. Code review
4. Merge and deploy
```

---

## Step 6: Final Git Status

Show what's ready:

```bash
git status
git log --oneline -10
```

---

## Output

```
## Feature Complete ✓

**[Feature Title]** has been successfully implemented and validated.

### Spec Location
`specs/implemented/[folder-name]/`

### Branch
`[branch-name]` - Ready for PR

### Summary
- Requirements: [X]/[X] implemented
- Tests: [X] passing
- Coverage: [Y]%

### Jira
[Updated PROJ-XXX to Done | No Jira integration]

### Next Steps

1. **Create Pull Request**
   ```bash
   gh pr create --title "[Feature Title]" --body "..."
   ```

2. **Code Review** - Have team review

3. **Merge** - Merge to main when approved

4. **Deploy** - Follow deployment process
```

---

## Workflow Complete

```
✓ Phase 1: Initiate - Branch and folder created
✓ Phase 2: Shape - Requirements gathered
✓ Phase 3: Specify - Spec document written
✓ Phase 4: Tasks - TDD task breakdown created
✓ Phase 5: Implement - TDD implementation done
✓ Phase 6: Validate - Implementation verified
✓ Phase 7: Complete - Feature finalized

→ Ready for: Pull Request → Review → Merge → Deploy
```

---

## Rollback (if needed)

If completion was premature:

```bash
# Move back to active
mv specs/implemented/[folder-name] specs/active/[folder-name]
```

Update spec.md frontmatter:
- `status: active`
- Remove `completed:` line
