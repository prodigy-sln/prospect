---
name: sdd-complete
description: "Finalize a validated feature: consolidate the spec into docs/, archive it, open the PR"
argument-hint: "[spec folder name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Complete

## Prerequisites

- `validation-report.md` shows PASS (low tier: green gate note in the
  mini-spec); at high+ the user has signed off
- Working tree clean, all work committed

If validation hasn't passed, run `/sdd-validate` — do not proceed.

## Step 1: Final Gate

Run `scripts/sdd-gate.*` once more. Red gate = stop.

## Step 2: Spec Status

Update spec frontmatter: `status: implemented`, add `completed: [today]`.

## Step 3: Consolidate into docs/

`docs/` describes the system as built; this step keeps it true.

- `docs/INDEX.md` exists → delegate to the `docs-consolidator` agent with
  the spec folder path. It merges permanent reference material into the
  routed docs and updates the INDEX.
- No `docs/INDEX.md` → offer to generate it from
  `specs/_templates/docs-index.template.md` (registering existing docs),
  then consolidate. If the user declines, append a completion summary
  (feature, behavior, key decisions, spec archive link) to
  `docs/CHANGELOG-features.md`.

## Step 4: Archive

```bash
git mv specs/active/[folder] specs/archive/[folder]
```

Commit the move together with the docs updates:
`docs: consolidate [feature] into living docs and archive spec`.

## Step 5: Loose Ends

- Outstanding non-blocking findings (Info) → create one issue each in the
  connected tracker; without a tracker, list them in the PR body.
- Spec has `jira:` and Jira MCP is available → transition the issue to Done
  with a completion comment.

## Step 6: Pull Request

Create the PR to the default branch:

- Title: `[Feature title]`
- Body: what/why/how summary, link to `specs/archive/[folder]/`,
  validation verdict, outstanding Info findings, checklist (gate green,
  validation PASS, docs consolidated, no out-of-scope changes)

## Output

```
Feature complete: [title]
Docs: [files updated] · Spec: specs/archive/[folder]/
PR: [url]
```
