---
id: SPEC-XXX
title: [Defect Title]
status: active
work-type: fix
rigor: medium          # low | medium | high | xhigh | max
branch: bugfix/YYYY-MM-DD-short-name
jira: [PROJ-XXX — remove if not applicable]
created: YYYY-MM-DD
author: [name]
---

# Fix: [Defect Title]

## Defect

- **Observed**: [what happens, with the concrete reproduction input]
- **Expected**: [what should happen]
- **Reproduced**: [date/command — or the strongest evidence when
  reproduction is uneconomical]

## Root Cause

[The responsible mechanism, traced in code with file:line — never guessed
from symptoms.]

## Regression Scenarios

[One per distinct wrong behavior; each becomes at least one failing test
before the fix. Rules: standards/global/scenario-guidelines.md]

- S1: WHEN [reproduction trigger] THE SYSTEM SHALL [correct outcome]

## Out of Scope

- [Adjacent cleanups observed but not fixed here]
