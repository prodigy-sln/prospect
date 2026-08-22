---
name: sdd-clarify
description: "Fill the clarifications ledger from stakeholders via issue-tracker comments; never claims completeness"
argument-hint: "[ISSUE-KEY]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion
---

# Clarify Requirements

Resolve requirement ambiguities through the connected issue tracker (Jira,
Linear, or Notion MCP); without one, ask the user directly. All state lives
in the spec folder's `requirements.md` `## Clarifications` ledger — one
line per question: `- [resolved|open|assumed] Q: … → A: …`. The specify
phase asks only `open` entries; this skill's job is emptying that list, and
it never declares clarification finished — the ledger's statuses are the
only truth.

## Steps

1. **Collect**: fetch the issue (description, comments, attachments,
   links); read docs via `docs/INDEX.md` routing. Mark ledger questions the
   material already answers as `resolved` with the answer.
2. **Identify** what still blocks a spec — only questions that change what
   gets built: ambiguous outcomes (observable measure?), missing
   constraints (limits, permissions, error behavior), undefined edge cases
   (empty, duplicate, concurrent, expired), unclear actors, UI look & feel.
   Skip anything the codebase answers — look first. Add them as `open`.
3. **Ask**: maximum 7, decision-shaped, each with options and a default.
   Tracker: post ONE comment with all questions, tell the user, stop; on
   re-invocation read the answers and update the ledger. No tracker: ask
   the user directly.
4. **Record**: every answer updates its ledger line to `resolved`.
   Questions deliberately answered by assumption become `assumed` with the
   assumption stated.

## Output

```
Ledger: [N] resolved · [M] open · [K] assumed — requirements.md
Next: /sdd-start (or resume it) — the specify phase asks only open entries.
```
