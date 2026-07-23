---
id: SPEC-XXX
title: [Feature Title]
status: active
rigor: medium          # low | medium | high | xhigh | max
branch: feature/YYYY-MM-DD-feature-name
jira: [PROJ-XXX — remove if not applicable]
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: [name]
---

# Specification: [Feature Title]

## Goal

[1–2 sentences: what problem this solves and what value it delivers.]

## User Stories

[Max 5. Every story must be covered by at least one scenario below.]

- As a [user type], I want to [action] so that [benefit]

## Functional Requirements

[Scenario rules: standards/global/scenario-guidelines.md. Each scenario
becomes exactly one test, mapped in this folder's test-map.md. Every FR
needs at least one happy-path and one unwanted-behavior scenario.]

### [Requirement Group]

- **FR-1.1**: [Specific, testable requirement]
  - FR-1.1-S1: WHEN [trigger] THE SYSTEM SHALL [observable outcome]
  - FR-1.1-S2: IF [error condition] THEN THE SYSTEM SHALL [observable outcome]

## Technical Considerations

- [Key decision and rationale]
- [Data model / API contracts, if applicable]

## Existing Code to Leverage

| What | Location | Reuse |
|------|----------|-------|
| [feature/component] | [path] | [pattern, component, logic] |

## Visual Design

[Only for features with UI surface — otherwise delete this section.]

- Approved direction: [visuals/variant-N.html or description] — binding for implementation
- Empty, loading, and error states are covered by scenarios above
- Project design language: standards/global/ui-design.md

## Out of Scope

[Binding. Explicitly list what will NOT be built.]

- :x: [Excluded feature/capability]

## Dependencies

- [Blocking or external dependency]

## Assumptions

- [Assumption about users, data, environment]

## Open Questions

[Must be empty before implementation starts.]

## Clarifications

### Session YYYY-MM-DD

- Q: [question] → A: [answer]
