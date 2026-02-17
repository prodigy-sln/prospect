---
id: SPEC-XXX
title: [Feature Title]
status: active
branch: feature/YYYY-MM-DD-feature-name
jira: [PROJ-XXX or remove if not applicable]
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: [developer-name]
---

# Specification: [Feature Title]

## Goal

[1-2 sentences describing the core objective. What problem does this solve? What value does it deliver?]

## User Stories

- As a [user type], I want to [action] so that [benefit]
- As a [user type], I want to [action] so that [benefit]
- [Add more as needed, max 5 primary stories]

## Functional Requirements

### [Requirement Group 1]

- **FR-1.1**: [Specific, testable requirement]
  - Acceptance: [How to verify this is complete]
- **FR-1.2**: [Specific, testable requirement]
  - Acceptance: [How to verify this is complete]

### [Requirement Group 2]

- **FR-2.1**: [Specific, testable requirement]
  - Acceptance: [How to verify this is complete]

[Continue for all requirement groups]

## Technical Considerations

### Architecture Decisions

- [Key architectural decision and rationale]
- [Integration points with existing systems]
- [Performance considerations]

### Data Model

[If applicable - entities, relationships, key fields]

| Entity | Key Fields | Relationships |
|--------|------------|---------------|
| [Name] | [Fields]   | [Relations]   |

### API Contracts

[If applicable - endpoints, request/response formats]

```
[METHOD] /api/v1/[resource]
Request: { ... }
Response: { ... }
```

## Test Strategy

### Unit Tests

- [Component/Module]: [What behaviors to test]
- [Component/Module]: [What behaviors to test]

### Integration Tests

- [Integration point]: [What flows to test]
- [Integration point]: [What flows to test]

### End-to-End Tests

- [User journey]: [Critical path to validate]

### Test Coverage Target

- Minimum coverage: [X]%
- Critical paths: 100% coverage required

## Existing Code to Leverage

### Similar Features

| Feature | Location | What to Reuse |
|---------|----------|---------------|
| [Name]  | [Path]   | [Components, patterns, logic] |

### Shared Components

- [Component]: [Path] — [How to use/extend]
- [Component]: [Path] — [How to use/extend]

### Patterns to Follow

- [Pattern name]: See [path] for reference implementation

## Visual Design

[If mockups/wireframes provided]

### [visuals/filename.png]

- [Key UI element and behavior]
- [Key UI element and behavior]
- Fidelity: [high-fidelity mockup | low-fidelity wireframe]

## Out of Scope

[CRITICAL: Explicitly list what will NOT be built to prevent scope creep]

- :x: [Feature/capability explicitly excluded]
- :x: [Feature/capability explicitly excluded]
- :x: [Future enhancement - not in this iteration]

## Dependencies

### Blocking Dependencies

- [Dependency]: [What's needed before we can start]

### External Dependencies

- [Service/API]: [How we depend on it]

## Assumptions

[Document any assumptions made during specification]

- [Assumption about user behavior, data, environment, etc.]
- [Assumption about available infrastructure or services]

## Open Questions

[Track any unresolved questions - should be empty before implementation]

- [ ] [Question that needs answer before/during implementation]

---

## Clarifications

[Added during /sdd.shape phase]

### Session YYYY-MM-DD

- Q: [Question asked] → A: [Answer provided]
- Q: [Question asked] → A: [Answer provided]
