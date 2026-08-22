# Documentation Index

Registry and routing guide for the living documentation. `docs/` describes
the system **as built** — never planned or future behavior. Future concepts
live in active specs and `product/roadmap.md`.

Consolidation updates this file: add the source identifier to the Sources
column of every updated file, and register newly created files.

## Structure

```
docs/
├── INDEX.md              ← you are here
├── [branch]/             ← e.g. technical/ (developers), design/, user/
│   └── [topic files]
```

## File Registry

### [directory]/

| File | Purpose | Sources |
|------|---------|---------|
| [file.md] | [what it documents] | — |

## Routing Guide

When consolidating source material, update the files mapped to its topics:

| Source material about... | Update |
|--------------------------|--------|
| [topic, e.g. authentication] | [docs file(s)] |
| Architecture decisions | [ADR file, e.g. technical/decisions.md] |
