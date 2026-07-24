# Git Workflow Standards (Constitution)

> Immutable. All AI-assisted development MUST comply. Violations require
> explicit justification and user approval.

## 1. Branches

- Naming: `feature/YYYY-MM-DD-short-name`, issue-driven
  `feature/KEY-123-short-name`, `bugfix/` same pattern. Kebab-case, 2–4
  words, max 50 characters total.
- The branch is created at the start of `/sdd-start`; all work — spec,
  tests, code — happens on it; it merges only after `/sdd-validate`
  passes.
- `main` and `dev` are protected: no direct commits, no force-push, all
  changes via PR, CI must pass before merge.

## 2. Commits

- Conventional Commits: `<type>(<scope>): <description>` with types
  feat, fix, test, refactor, docs, chore, style. Imperative mood, present
  tense, description ≤72 characters.
- TDD sequence per task: `test: add failing tests for X` →
  `feat: implement X` → `refactor: improve Y` (refactor only when changes
  were made). Never mix test and implementation code in one commit.
- Commit after each RED, GREEN, and REFACTOR step, and when consolidating
  docs and registering the spec. Spec changes commit separately from code.
- Never: "WIP"/"temp" as messages, committing failing tests, bundling
  unrelated changes, secrets, `.env` files, build artifacts,
  commented-out code.

## 3. Pull Requests

- Opened only by `/sdd-complete`: validation PASS, quality gate green,
  spec status `implemented`, docs consolidated, spec registered in
  `specs/REGISTRY.md`.
- Body: What / Why (spec and registry reference) / How / checklist
  (gate green · validate passed · docs consolidated and spec registered ·
  no out-of-scope changes).
- Squash merge preferred; merge commit acceptable when the history is
  meaningful; at least one reviewer approval when the team is larger
  than one.
