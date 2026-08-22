# Tasks: [Feature Title]

**Spec**: [link to spec.md] · **Branch**: `feature/YYYY-MM-DD-feature-name` · **Created**: YYYY-MM-DD

One task = one coherent scenario group in one area. Split phases only at
real dependency boundaries (e.g. schema before API). `[P]` = independent of
other `[P]` tasks in the same phase. Budget: 60 lines — one line per task
plus its scenario line; status is appended as ` — done`, rationale lives in
the spec, lessons go to docs/ at completion.

## Phase 1: [Name]

- [ ] T01 [P] [Short description] — [file hints]
      Scenarios: FR-1.1-S1, FR-1.1-S2
- [ ] T02 [Short description] — [file hints]
      Scenarios: FR-1.2-S1
      Depends on: T01

## Phase 2: [Name]

- [ ] T03 [Short description] — [file hints]
      Scenarios: FR-2.1-S1, FR-2.1-S2

## Notes

[Deferred observations and follow-ups discovered during implementation.
Never delete task text; append status markers only.]
