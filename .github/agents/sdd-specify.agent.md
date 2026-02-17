---
name: sdd-specify
description: Phase 3 - Generate specification document
tools:
  - agent
  - read
  - execute
  - edit
  - search
  - web
  - todo
  - mcp_io_github_ups_resolve-library-id
  - mcp_io_github_ups_get-library-docs
  - search/codebase
handoffs:
  - label: Create Tasks
    agent: sdd-tasks
    prompt: Create TDD-ordered task breakdown from the spec
    send: true
---

# Generate Specification

Create complete specification from gathered requirements.

## Prerequisites

- `requirements.md` has Q&A session and codebase analysis
- If empty or missing, suggest running `/sdd.shape` first

---

## Step 1: Load Context

Read these files:

1. **Requirements**: `specs/active/[folder]/requirements.md`
   - Q&A session notes
   - Codebase analysis
   - Visual asset observations

2. **Template**: `specs/_templates/spec.template.md`
   - Structure to follow
   - All sections to fill

3. **Existing spec.md**: `specs/active/[folder]/spec.md`
   - Frontmatter already initialized

4. **Standards** (for test strategy):
   - `standards/global/testing.md`
   - `standards/global/code-quality.md`

---

## Step 2: Generate Specification

### Frontmatter (Update)

```yaml
---
id: SPEC-[XXX]
title: [Feature Title from requirements]
status: active
branch: [existing branch]
jira: [if applicable]
created: [existing date]
updated: [today's date]
author: [existing author]
---
```

### Goal

1-2 sentences answering:
- What problem does this solve?
- What value does it deliver?

### User Stories

Max 5 stories, format: "As a [user type], I want to [action] so that [benefit]"

Quality checks:
- Each has clear user type
- Action is specific and achievable
- Benefit explains the "why"

### Functional Requirements

Group related requirements, number them:

```markdown
### [Group 1: e.g., Data Entry]

- **FR-1.1**: [Specific, testable requirement]
  - Acceptance: [How to verify completion]

- **FR-1.2**: [Specific, testable requirement]
  - Acceptance: [How to verify completion]
```

Quality checks:
- Every requirement is testable
- Acceptance criteria are specific
- No ambiguous language ("should", "might", "could")
- If unclear, add `[NEEDS CLARIFICATION]` marker

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

If visuals provided:
- Reference each file
- Note key UI elements and behaviors
- Specify fidelity: high-fidelity mockup | low-fidelity wireframe
- Style guidance: Follow exactly | Use structure with existing styles

### Out of Scope (CRITICAL)

Explicit exclusions to prevent scope creep:

- ❌ [Feature NOT included]
- ❌ [Edge case NOT handled this iteration]
- ❌ [Future enhancement deferred]

**If this section is empty, go back and clarify what's excluded.**

### Dependencies

- **Blocking**: What's needed before we can start
- **External**: Services/APIs we depend on

### Assumptions

Document assumptions about user behavior, data, environment, infrastructure.

### Open Questions

Track unresolved questions. **Should be empty before implementation.**

### Clarifications

Include Q&A from shaping session.

---

## Step 3: Quality Review

Before saving, verify:

### Completeness
- [ ] Goal is clear and specific
- [ ] User stories cover main use cases
- [ ] All functional requirements are testable
- [ ] Test strategy aligns with requirements
- [ ] Existing code references included
- [ ] Out of scope is comprehensive

### Clarity
- [ ] No unresolved `[NEEDS CLARIFICATION]` markers (max 3-5 acceptable)
- [ ] Prioritize clarifications: scope > security > UX > technical
- [ ] All referenced visuals exist
- [ ] Code paths mentioned exist in codebase

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

### Code Reuse
- [count] existing features/components referenced

### Scope Control
- [count] items explicitly out of scope

### Quality Status
- Open questions: [count] (should be 0 before tasks)
- Clarifications needed: [count]

### Next Steps
1. Review the spec
2. Resolve any open questions
3. Proceed to create task breakdown
```

Tell user to review spec before proceeding.
