---
name: sdd-start
description: "Start work: classify work-type and rigor, create branch and spec folder, then hand off to the resolver"
argument-hint: "[description or ISSUE-KEY] [--work-type <t> --rigor <r>] [--branch-exists]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion
---

# Start

Take a request from description to a resolvable spec folder.

Arguments: `--work-type <t> --rigor <r>` given together fix the
classification — skip Step 1's question and use them as given.
`--branch-exists` means the caller already created and checked out the
branch — use the current one (`git branch --show-current`) instead of
creating one.

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

Rigor also caps the spec's scenario budget (15 · 40 · 70 · 110 · 160), so
the size of the behavior surface is a legitimate reason to pick a higher
tier.

Escalate later when new risk appears (record the reason); downgrade only
with explicit user confirmation.

## Step 2: Branch & Folder

Branch `[type]/YYYY-MM-DD-short-name` (issue-driven:
`[type]/KEY-123-short-name`), where `[type]` is `feature`, `bugfix`, or
`chore` (docs and decision work use `feature/`). Create it unless
`--branch-exists`. Then create the folder:

```
bash .prospect/scripts/sdd-new.sh <short-name> --work-type <t> --rigor <r> \
  --title "<title>" --branch <branch> [--goal "<goal>"]
```

It prints the folder name (exit 2: the folder exists — pick another name)
and writes `spec.md` frontmatter plus `requirements.md` with the
`## Clarifications` ledger (`- [status] Q: … → A: …`, status one of
`resolved | open | assumed`). Seed the ledger from the issue or
conversation; `/sdd-clarify` fills it from a connected tracker. For `docs`
and `chore`, pass `--goal` — no specify phase writes one.

## Step 3: Hand off

Run `bash .prospect/scripts/sdd-next.sh [folder]` and follow the returned
prompt — it runs the specify phase for the chosen work-type and rigor.
