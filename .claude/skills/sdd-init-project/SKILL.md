---
name: sdd-init-project
description: "Initialize a new project with the SDD framework: gather stack and preferences, generate structure, standards, and gate"
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Initialize a New Project

Set up a fresh project for the SDD pipeline through a short Q&A, then
generate everything the pipeline depends on.

## Step 1: Q&A

Ask (decision-shaped, with defaults):

1. Backend / frontend / database stack and test frameworks
2. Formatter, linter, type checker preferences (default: the stack's
   standard tools)
3. Coverage targets (default: per `standards/global/testing.md`)
4. UI product? → brand and tone, visual references, accessibility bar,
   component library (existing or to establish)
5. Issue tracker in use (or none)
6. Documentation branches wanted under `docs/` (default: technical/, user/)

## Step 2: Generate Structure

Create the project skeleton for the chosen stack, plus:

- `docs/INDEX.md` from `.prospect/templates/docs-index.template.md` with
  the chosen branches and an initial routing guide
- `docs/architecture.md` skeleton: module map, dependency directions,
  volatility table, project constants — specs declare only deltas against it
- `product/mission.md` and `product/roadmap.md` from `product/` templates
- `CLAUDE.md`: tech-stack section and the Prospect settings block
  (`spec-disposal`, `review-mode: solo | team` — ask; recommend `solo` for
  a single maintainer)

## Step 3: Quality Gate

Generate `scripts/sdd-gate.sh` and/or `scripts/sdd-gate.ps1` wiring the
chosen tools in order: formatter check, linter (zero warnings), type
check, test suite, coverage threshold, and a final stage calling
`bash .prospect/scripts/sdd-artifact-lint.sh` on the active spec folder
when one exists. Non-zero exit on any failure with a compact failure list.
Run it once on the skeleton to prove it's green.

## Step 4: UI Design Standard (UI projects)

Write `standards/global/ui-design.md` from the Q&A: design-token strategy,
component reuse rules, typography and spacing scale, tone, accessibility
bar, anti-generic guidance (no template defaults). This file is injected
into every UI-touching prompt later — make it opinionated.

## Step 5: Calibration

Fill the skip rules in `standards/global/validation-calibration.md` with
the project's generated paths and CI-enforced checks.

## Output

```
Project initialized.
Stack: [summary] · Gate: scripts/sdd-gate.* (green)
Docs: docs/INDEX.md · Standards: [list]
Next: /sdd-start [first feature]
```
