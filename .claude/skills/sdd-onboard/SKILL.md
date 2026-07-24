---
name: sdd-onboard
description: "Onboard an existing project: detect the toolchain, generate the quality gate, docs index, and UI design standard"
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Onboard an Existing Project

Analyze the codebase and generate the project-specific pieces the SDD
pipeline depends on. Never overwrite an existing generated file without
showing the user a diff first.

## Step 1: Detect

Delegate codebase analysis to an Explore subagent; request a compact
report: languages and frameworks; formatter, linter, type checker, test
runner and their config files; test layout and naming; coverage tooling;
UI stack and design assets (tokens, theme files, component library,
stylesheets); existing docs locations.

## Step 2: Quality Gate

Generate `scripts/sdd-gate.sh` and/or `scripts/sdd-gate.ps1` from the
detected toolchain, running in order: formatter check (no auto-fix), linter
(zero warnings), type check, full test suite, coverage threshold from
`standards/global/testing.md`. Any failure → non-zero exit and a compact
failure list, no prose. Run the gate once to prove it works; a red result
on the existing codebase is a finding for the user, not a generation error.

## Step 3: Docs Index

If `docs/INDEX.md` is missing, generate it from
`specs/_templates/docs-index.template.md`: register existing documentation
files with purpose per file, and write a routing guide from the project's
topics. `docs/` holds as-built documentation only.

## Step 4: UI Design Standard (UI projects)

Generate `standards/global/ui-design.md` from the real app: design-token
source of truth, component library and reuse rules ("extend existing
components before creating new"), typography and spacing scale, color
usage, tone, accessibility bar, and explicit anti-generic guidance (no
template defaults, no stock gradients). Extract from code and assets;
ask the user only what the code cannot show (brand intent, tone).

## Step 5: Project Instructions

Update `CLAUDE.md` tech-stack section with the detected stack and the gate
script path. Fill `standards/global/validation-calibration.md` skip rules
with project specifics (generated dirs, vendored code).

## Output

```
Onboarded.
Gate: scripts/sdd-gate.* [green/red on current codebase]
Docs index: [generated/existing] · UI standard: [generated/n-a]
Next: /sdd-start [feature]
```
