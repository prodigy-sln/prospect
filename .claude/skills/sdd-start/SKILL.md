---
name: sdd-start
description: "Start work: classify work-type and rigor, create branch and spec folder, then hand off to the resolver"
argument-hint: "[description or ISSUE-KEY]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion
---

# Start

Take a request from description to a resolvable spec folder.

## Step 1: Classify

Recommend and confirm with the user in ONE question round:

- **work-type** — `feature` (new or changed behavior) · `fix` (defined by a
  defect; root cause + regression) · `decision` (the deliverable is ADRs,
  contracts, conventions) · `docs` (documentation only) · `chore`
  (non-behavioral: refactor, tooling, dependencies)
- **rigor** — `low` (isolated, no cross-cutting impact) · `medium`
  (default) · `high` (mandatory floor when auth, payments, personal data,
  compliance, or destructive migrations are touched) · `xhigh`/`max`
  (contested plans, many stakeholders)

Record both in the spec frontmatter. Escalate later when new risk appears
(record the reason); downgrade only with explicit user confirmation.

## Step 2: Branch & Folder

Branch `[type]/YYYY-MM-DD-short-name` (issue-driven:
`[type]/KEY-123-short-name`), where `[type]` is `feature`, `bugfix`, or
`chore` (docs and decision work use `feature/`). Create
`specs/active/YYYY-MM-DD-short-name/` containing:

- `spec.md` — frontmatter only for now (id, title, status: active,
  work-type, rigor, branch, created) from the matching template in
  `.prospect/templates/`
- `requirements.md` with a `## Clarifications` ledger (`- [status] Q: … →
  A: …`, status one of `resolved | open | assumed`), seeded from the issue
  or conversation. `/sdd-clarify` fills it from the tracker when one is
  connected.

## Step 3: Hand off

Run `bash .prospect/scripts/sdd-next.sh [folder]` and follow the returned
prompt — it runs the specify phase for the chosen work-type and rigor.
