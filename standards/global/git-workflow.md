# Git Workflow Standards (Constitution)

> **This document is IMMUTABLE.** All AI-assisted development MUST comply with these standards. Violations require explicit justification and user approval.

## Article I: Branch Strategy

### Section 1.1: Branch Naming

All feature branches MUST follow this convention:

```
feature/YYYY-MM-DD-short-name       # Human-initiated feature
feature/PROJ-123-short-name         # Jira-initiated feature (Jira key replaces date)
bugfix/YYYY-MM-DD-short-name        # Bug fix
```

Rules:
- `short-name` is 2-4 words in kebab-case derived from the feature description
- Maximum 50 characters total for the branch name
- All lowercase, no special characters except `-` and `/`

```
:white_check_mark: REQUIRED: feature/2025-01-29-user-authentication
:white_check_mark: REQUIRED: feature/PROJ-123-user-authentication
:x: PROHIBITED: feature/UserAuthentication
:x: PROHIBITED: feature/my-new-feature-that-does-auth-and-profile-and-settings
:x: PROHIBITED: fix-stuff
```

### Section 1.2: Branch Lifecycle

```
main (or dev)
  │
  └─► feature/YYYY-MM-DD-feature-name   ← Created by /sdd.initiate
        │
        │  All spec, task, and implementation work happens here
        │
        └─► [Pull Request] ← Created after /sdd.complete
              │
              └─► Merged to main by developer
```

```
:white_check_mark: REQUIRED: Create branch at start of /sdd.initiate phase
:white_check_mark: REQUIRED: All work (specs, code, tests) on feature branch
:white_check_mark: REQUIRED: Branch is merged only after /sdd.validate passes
:x: PROHIBITED: Committing spec or implementation directly to main
:x: PROHIBITED: Starting implementation before branch is created
```

---

## Article II: Commit Messages

### Section 2.1: Conventional Commits Format

All commits MUST follow the Conventional Commits specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**

| Type | When to Use |
|------|------------|
| `feat` | New feature or functionality |
| `fix` | Bug fix |
| `test` | Adding or updating tests |
| `refactor` | Code restructuring without behavior change |
| `docs` | Documentation changes (including specs) |
| `chore` | Build, tooling, or dependency changes |
| `style` | Formatting, whitespace (no logic changes) |

**Scope** (optional): The module, component, or layer affected (e.g., `auth`, `api`, `db`).

### Section 2.2: Commit Message Rules

```
:white_check_mark: REQUIRED: Imperative mood in description ("add feature" not "adds feature")
:white_check_mark: REQUIRED: Description under 72 characters
:white_check_mark: REQUIRED: Present tense ("fix bug" not "fixed bug")
:x: PROHIBITED: "WIP", "temp", "fix", "asdf" as full commit messages
:x: PROHIBITED: Committing broken/failing tests
:x: PROHIBITED: Bundling unrelated changes in a single commit
```

### Section 2.3: TDD Commit Sequence

During /sdd.implement, commits MUST follow the Red-Green-Refactor sequence:

```
test: add failing tests for [task name]        ← RED phase commit
feat: implement [task name]                     ← GREEN phase commit
refactor: improve [component name]              ← REFACTOR phase commit (optional)
```

**Examples:**
```
test: add failing tests for user login endpoint
feat: implement user login with JWT
refactor: extract token generation to service
```

---

## Article III: Pull Requests

### Section 3.1: PR Requirements

A Pull Request MUST NOT be opened until:

```
:white_check_mark: REQUIRED: /sdd.validate has produced a PASS report
:white_check_mark: REQUIRED: All tests passing on the feature branch
:white_check_mark: REQUIRED: spec.md status updated to "implemented"
:white_check_mark: REQUIRED: Spec folder moved to specs/implemented/
:x: PROHIBITED: Opening PR with failing tests
:x: PROHIBITED: Opening PR before /sdd.complete phase
```

### Section 3.2: PR Description Template

```markdown
## What
<!-- One sentence: what does this PR do? -->

## Why
<!-- Reference spec: specs/implemented/YYYY-MM-DD-feature-name/spec.md -->

## How
<!-- Brief technical summary of approach -->

## Checklist
- [ ] All tests passing
- [ ] /sdd.validate passed
- [ ] Spec moved to implemented/
- [ ] No out-of-scope changes included
```

### Section 3.3: Merge Strategy

```
:white_check_mark: PREFERRED: Squash merge for feature branches (clean history on main)
:white_check_mark: ACCEPTABLE: Merge commit when commit history is meaningful
:x: PROHIBITED: Force-pushing to main or dev
:x: PROHIBITED: Merging without at least one reviewer approval (if team > 1)
```

---

## Article IV: Commit Hygiene

### Section 4.1: Atomic Commits

Each commit MUST represent a single logical change:

```
:white_check_mark: REQUIRED: One commit per TDD phase (test / implement / refactor)
:white_check_mark: REQUIRED: Spec file changes committed separately from code changes
:x: PROHIBITED: Mixing test and implementation code in the same commit
:x: PROHIBITED: "Checkpoint" commits with multiple unrelated changes
```

### Section 4.2: What to Commit

```
:white_check_mark: ALWAYS COMMIT: Source code, tests, specs, migrations
:white_check_mark: ALWAYS COMMIT: .gitignore, configuration files (non-secret)
:x: NEVER COMMIT: Secrets, API keys, passwords, .env files
:x: NEVER COMMIT: Build artifacts, compiled output, node_modules
:x: NEVER COMMIT: IDE-specific files (unless team-shared settings)
```

### Section 4.3: Commit Timing

```
:white_check_mark: REQUIRED: Commit after each RED phase (failing tests written)
:white_check_mark: REQUIRED: Commit after each GREEN phase (tests passing)
:white_check_mark: REQUIRED: Commit after each REFACTOR phase (if changes made)
:white_check_mark: REQUIRED: Commit when moving spec to implemented/
:x: PROHIBITED: Leaving uncommitted changes overnight
:x: PROHIBITED: Committing commented-out code
```

---

## Article V: Protected Branches

### Section 5.1: Branch Protection Rules

`main` and `dev` branches are protected:

```
:x: PROHIBITED: Direct commits to main or dev
:x: PROHIBITED: Force-pushing to main or dev
:x: PROHIBITED: Bypassing required PR reviews
:white_check_mark: REQUIRED: All changes via Pull Request
:white_check_mark: REQUIRED: CI/CD checks must pass before merge
```

---

## Amendment Log

| Date | Change | Reason |
|------|--------|--------|
| | | |

> To amend this document, create a spec for the change and get explicit user approval.
