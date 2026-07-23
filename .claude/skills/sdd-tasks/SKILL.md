---
name: sdd-tasks
description: "Break an approved specification into scenario-grouped implementation tasks"
argument-hint: "[spec folder name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Task Breakdown

Turn an approved spec into `tasks.md`. Applies at `rigor: medium` and above
(`low` uses the mini-spec's scenario list directly).

## Prerequisites

- Approved `specs/active/[folder]/spec.md`, Open Questions empty
- `architecture.md`, if present, is approved

## Build the Task List

Read the spec (and architecture plan), then group scenarios into tasks
using `specs/_templates/tasks.template.md`:

- **One task = one coherent scenario group in one area.** A task lists the
  scenario IDs it satisfies and hints at the files it touches.
- **Every scenario appears in exactly one task.** Verify this before
  writing — an unassigned scenario is unimplemented work.
- Split phases only at real dependency boundaries (e.g. schema before API,
  API before UI). No boundary → one phase.
- Mark `[P]` on tasks independent of other `[P]` tasks in the same phase.
- Order tasks so each phase's test author gets a coherent slice of the
  interface to design.

## Output

Write `specs/active/[folder]/tasks.md`. Commit:
`docs(spec): add task breakdown for [feature]`.

Report a summary: phases, task count, scenario count, and confirmation
that every scenario is assigned. End with:

```
Tasks committed. Everything downstream needs is on disk — safe to /clear.
Next: /sdd-implement
```
