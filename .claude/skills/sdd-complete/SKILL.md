---
name: sdd-complete
description: "Finalize a validated feature: consolidate into docs/, register the spec, open the PR — then dispose of the spec folder after approval"
argument-hint: "[spec folder name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Complete

Completion is a two-phase state machine. Determine the state, run the
matching phase:

| State | Action |
|-------|--------|
| Validation PASS, no PR open | Phase 1: Publish |
| PR open and approved, spec still in `specs/active/` | Phase 2: Finalize |
| PR open, not yet approved | Report review status, stop |

The disposal mode comes from CLAUDE.md Prospect settings:
`spec-disposal: delete` (default) or `archive` with `retention: [days]`.

## Phase 1: Publish

Prerequisites: `validation-report.md` PASS (low tier: green gate note in
`spec.md`); at high+ the user has signed off; working tree clean.

1. Run `scripts/sdd-gate.*` once more — red gate = stop.
2. Spec frontmatter: `status: implemented`, `completed: [today]`.
3. Consolidate into `docs/`: when `docs/INDEX.md` exists, delegate to the
   `docs-consolidator` agent with the spec folder path. When missing, offer
   to generate it from `specs/_templates/docs-index.template.md`; if
   declined, append a completion summary to `docs/CHANGELOG-features.md`.
4. **Archive mode only**: `git mv` the folder to
   `specs/archive/YYYY/[folder]/`, and in the same commit `git rm` archive
   folders older than the retention setting.
5. Commit: `docs: consolidate [feature] into living docs`.
6. Open the PR: title = feature title; body = what/why/how, validation
   verdict, outstanding Info findings, checklist (gate green, validation
   PASS, docs consolidated, no out-of-scope changes). Delete mode: state in
   the body that the spec folder is removed on finalize after approval.
7. Append one line to `specs/REGISTRY.md` and push:
   `[folder] · [date] · [rigor] · [topic tags] · [one-line summary] · PR #N`
8. Outstanding Info findings → one issue each in the connected tracker
   (reference the registry line); without a tracker, they stay in the PR
   body. Spec has `jira:` and Jira MCP available → transition the issue to
   Done with a completion comment.

Delete mode ends Phase 1 with: *"After the PR is approved, run
`/sdd-complete` again to finalize."* Archive mode: merging the PR is the
last step — nothing further runs.

## Phase 2: Finalize (delete mode)

Verify via `gh`: PR approved, all checks green. Otherwise report and stop.

1. `git rm -r specs/active/[folder]` — commit
   `chore: remove spec working folder`, push.
2. Squash-merge: `gh pr merge --squash`. The folder was added and removed
   within the branch, so `main` never carries it; the registry line and
   docs changes do land.
3. If branch protection dismissed the approval on that push, tell the user
   one re-approval of the single deletion commit is required, then merge.

## Output

```
[Published | Finalized]: [title]
Docs: [files updated] · Registry: [line appended]
PR: [url] · Spec disposal: [pending finalize | removed | archived to path]
```
