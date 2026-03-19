---
name: sdd-specify
description: "Phase 3: Generate a complete specification document from gathered requirements"
argument-hint: "[specification folder name, e.g. '2024-06-01-new-login-system']"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Generate Specification

Create complete specification from gathered requirements.

## Prerequisites

- `requirements.md` has Q&A session and codebase analysis
- If empty or missing, suggest running `/sdd-shape` first

---

## Step 1: Load Context

Read these files:

1. **Requirements**: `specs/active/[folder]/requirements.md`
2. **Template**: `specs/_templates/spec.template.md`
3. **Existing spec.md**: `specs/active/[folder]/spec.md` (frontmatter already initialized)
4. **Standards**: `standards/global/testing.md`, `standards/global/code-quality.md`

---

## Step 2: Generate Specification

### Frontmatter (Update)

Update the `updated:` date to today.

### Goal

1-2 sentences: What problem does this solve? What value does it deliver?

### User Stories

Max 5 stories, format: "As a [user type], I want to [action] so that [benefit]"

### Functional Requirements

Group related requirements, number them (FR-1.1, FR-1.2, etc.). Each must have:
- Specific, testable description
- Acceptance criteria

### Technical Considerations

- Architecture decisions with rationale
- Data model (entities, fields, relationships)
- API contracts (endpoints, request/response)

### Test Strategy

Based on `standards/global/testing.md`:
- **Unit Tests**: What components/behaviors to test
- **Integration Tests**: What flows to test
- **E2E Tests**: Critical user journeys
- **Coverage Target**: Minimum % (typically 80%, critical paths 100%)

### Existing Code to Leverage

From codebase analysis:
| Feature | Location | What to Reuse |
|---------|----------|---------------|
| [Name]  | [Path]   | [Components, patterns, logic] |

### Visual Design

If visuals provided, reference each file with fidelity level and style guidance.

### Out of Scope (CRITICAL)

Explicit exclusions to prevent scope creep. **If this section is empty, go back and clarify what's excluded.**

### Dependencies, Assumptions, Open Questions, Clarifications

Fill from requirements.md and shaping session.

---

## Step 3: Quality Review

Before saving, verify:
- [ ] Goal is clear and specific
- [ ] All functional requirements are testable
- [ ] Test strategy aligns with requirements
- [ ] Out of scope is comprehensive
- [ ] No unresolved `[NEEDS CLARIFICATION]` markers (max 3-5 acceptable)

---

## Output

Write to `specs/active/[folder]/spec.md`

```
## Specification Generated

**Spec**: `specs/active/[folder]/spec.md`

### Summary
- Goal: [one-line summary]
- User Stories: [count]
- Functional Requirements: [count] across [X] groups
- Test Coverage Target: [X]%
- Out of Scope Items: [count]

### Next Steps
1. Review the spec
2. Resolve any open questions
3. (Optional) Run: `/sdd-architect` to produce the architecture plan before tasks
4. When ready, run: `/sdd-tasks`
```

Tell user to review spec before proceeding.
