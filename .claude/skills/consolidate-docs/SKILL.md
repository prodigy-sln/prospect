---
name: consolidate-docs
description: "Merge a source document or spec folder into the living documentation under docs/"
argument-hint: "[path to source file or folder]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Consolidate Docs

Merge permanent reference material from a source (a completed spec folder,
design notes, a technical writeup) into the living documentation.

## Prerequisites

- `docs/INDEX.md` exists — if not, offer to generate it from
  `.prospect/templates/docs-index.template.md`, registering existing docs
- A source path was provided; otherwise ask for one

## Run

Delegate to the `docs-consolidator` agent with the source path. It routes
content via the INDEX, merges into the target files without duplicating or
overwriting other sources, and updates the INDEX Sources column.

Only as-built material lands in `docs/` — the agent skips process
artifacts (task lists, validation reports, status notes). Future concepts
belong in active specs and `product/roadmap.md`, never in `docs/`.

## After

Show the user the agent's summary (files updated, skipped, INDEX changes)
and the resulting diff. Commit:
`docs: consolidate [source name]`.
