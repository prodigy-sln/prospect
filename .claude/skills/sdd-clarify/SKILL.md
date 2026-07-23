---
name: sdd-clarify
description: "Clarify requirements with stakeholders via issue-tracker comments before spec writing; falls back to direct user questions"
argument-hint: "[ISSUE-KEY]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion
---

# Clarify Requirements

Resolve ambiguities with stakeholders before a spec is written. Works
against the connected issue tracker (Jira, Linear, or Notion MCP); without
one, ask the user directly.

## Step 1: Collect Context

Fetch the issue (description, comments, attachments, linked issues). Read
related docs via `docs/INDEX.md` routing when present. Note what is already
answered — never ask for it again.

## Step 2: Identify What Blocks a Spec

Only questions that change what gets built qualify:

- Ambiguous outcomes ("improve", "faster", "better" — by what observable measure?)
- Missing constraints (limits, volumes, permissions, error behavior)
- Undefined edge cases (empty, duplicate, concurrent, expired)
- Unclear actors (who triggers this; who must not)
- UI features: look & feel expectations, states, references

Skip anything the codebase or existing docs can answer — look there first.

## Step 3: Ask

Maximum 7 questions, each decision-shaped: numbered, with options and a
sensible default, answerable in one line.

**Tracker available**: post ONE comment with all questions. Tell the user
it's posted; stop. When invoked again on the same issue, read the answers
from the comments and continue.

**No tracker**: ask the user directly in the conversation.

## Step 4: Record

Write every Q&A pair into `specs/active/[folder]/requirements.md` under
`## Clarifications` (create the folder via `/sdd-start` if it doesn't exist
yet — in that case record into the issue context handed to it). Unanswered
questions become Open Questions in the spec — they must be resolved before
implementation.

## Output

```
Clarified: [N] questions answered, [M] still open.
Recorded in: [requirements.md path or issue comment link]
Next: /sdd-start [ISSUE-KEY] (or resume the running sdd-start)
```
