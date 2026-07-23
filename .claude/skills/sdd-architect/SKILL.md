---
name: sdd-architect
description: "Architecture planning between specification and tasks — default at rigor high and above"
argument-hint: "[spec folder name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Architecture Planning

Produce a binding architecture plan from an approved spec. Default step at
`rigor: high` and above; available on demand at any tier.

## Prerequisites

- Approved `specs/active/[folder]/spec.md` with empty Open Questions
- `## Discussion Findings` in requirements.md, if a discussion ran

## Run

Delegate to the `sdd-architect` agent with the spec folder path and the
paths to `standards/global/code-quality.md` and `CLAUDE.md`. It writes
`specs/active/[folder]/architecture.md`: decisions with rejected
alternatives, interfaces, data contracts, integration points, risks.

## Review Handoff

Present the plan's decision table and interfaces to the user. The plan is
binding for the test author and implementation once approved — changes
after approval require updating architecture.md first.

If the agent reports a scenario that no reasonable design satisfies, treat
it as a spec defect: return to the spec with the user before proceeding.

Commit: `docs(spec): add architecture plan for [feature]`.

```
Architecture approved and committed — safe to /clear.
Next: /sdd-tasks
```
