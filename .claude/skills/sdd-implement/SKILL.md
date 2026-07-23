---
name: sdd-implement
description: "TDD implementation: a test author writes each phase's failing tests, implementation follows inline until the gate is green"
argument-hint: "[spec folder name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, SendMessage
---

# Implement

## Prerequisites

Read: `specs/active/[folder]/spec.md`, `tasks.md` (medium+),
`architecture.md` (if present), `standards/global/testing.md`,
`standards/global/code-quality.md`. Resume from the first unchecked task.

## Low Tier — single context

Work scenario by scenario from the mini-spec:

1. Write the failing test yourself (scenario ID in the test name).
2. Run it and **display the failing output** — writing implementation
   before displayed failing output is prohibited.
3. Implement the minimum to pass; run to green.
4. Refactor your own diff against the checklist below.
5. Commit sequence: `test:` → `feat:` → `refactor:` (last one only when
   changes were made).

Then run the gate (below) and finish.

## Medium+ — per phase

### 1. RED: delegate to the test author

Spawn `sdd-test-author` as a **named agent** (`test-author-phase-N`),
passing only: spec path, this phase's scenario IDs, paths to `testing.md`,
`scenario-guidelines.md`, and `architecture.md` (if present).

Receive its Test Contract: interface decisions, test↔scenario map, failing
count, test command. **The interface decisions are binding.** If it reports
already-satisfied scenarios or architecture conflicts, surface them to the
user before continuing.

### 2. GREEN: implement inline, task by task

Read the failing tests for the task's scenarios and implement the minimum
that satisfies them. Run the tests; iterate to green. Commit:
`feat: implement [task]`.

**Test files belong to the test author.** If a failing test looks wrong:

- Do NOT edit it. Send the named test author the facts only: test name,
  assertion diff, scenario ID, minimal implementation excerpt. No argument,
  no proposed fix.
- Apply the verdict: `test-correct` → make the implementation conform;
  `test-wrong` → the author fixes and commits, re-run; `scenario-ambiguous`
  → ask the user.

### 3. REFACTOR: own diff only

Checklist over the task's diff: naming · duplication · dead code · error
messages · nesting depth · standards fit. Fix in-diff issues, run tests
after each change, commit `refactor: improve [component]` only when
something changed. Issues in files outside the diff go to `tasks.md` under
`## Notes` as deferred observations — never fix them in passing.

### 4. Track and gate

Mark the task done in `tasks.md` (append status; never rewrite task text).
At phase end run `scripts/sdd-gate.*` — it must exit 0 before the next
phase begins. On failure: fix exactly what the output reports, re-run.
Never proceed on a red gate.

## Scope Guard

Before any implementation edit: does it map to a task and scenario, and is
it absent from Out of Scope? If not — record it under `## Notes`, don't
build it.

## Session End

Report per phase: tasks completed, tests passing, gate status, deferred
observations. Next: `/sdd-validate`.
