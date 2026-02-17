---
name: sdd-shape
description: "Phase 2: Collaborative requirements gathering through targeted questions and codebase discovery"
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Shape Requirements

Collaborative requirements gathering through targeted questions.

## Prerequisites

Spec folder must exist at `specs/active/[name]/`. If not, suggest running `/sdd-initiate` first.

Find the active spec using Glob:
```
specs/active/*/
```

If multiple folders exist, ask user which one to work with.

---

## Step 1: Codebase Discovery (MANDATORY — Delegate to Explore subagent)

Before asking ANY questions, use the **Task tool** with `subagent_type: Explore` to search the codebase. This preserves context on the main conversation.

### Launch Explore Subagent

Read the spec's title and initial context from `specs/active/[folder]/spec.md`, then delegate:

```
Search the codebase for context relevant to the feature: "[feature title/description]"

Report the following in a structured markdown format:

### Similar Features Found
Search for keywords related to this feature. For each match:
| Feature | Location | Relevance |
|---------|----------|-----------|
| [name]  | [path]   | [what can be reused] |

### Reusable Components
Find existing UI components, services, utilities that could be reused:
- [Component]: [path] — [how to use]

### Patterns to Follow
How are similar features structured? Note file organization, naming, and architecture:
- [Pattern]: See [path] for reference

### Integration Points
Existing APIs, services, shared data models this feature might connect to.

### Database Schemas
Tables, entities, or models that could be extended for this feature.
```

### Process Discovery Report

Save the Explore subagent's findings to `requirements.md` under "Codebase Analysis". Use these findings to frame your questions with sensible defaults in Step 2.

---

## Step 2: Ask Targeted Questions

Ask 5-8 questions. Frame with sensible defaults based on codebase findings:

1. **Users & Access Control**: Who will use this feature? What permissions are needed?
2. **Core User Journey**: Walk me through the main workflow.
3. **Data Requirements**: What data is involved? New entities or extend existing?
4. **Business Rules & Validation**: What rules govern this feature?
5. **Integration with Existing Features**: How does this connect to existing functionality?
6. **Error Handling & Edge Cases**: What could go wrong?
7. **Out of Scope (CRITICAL)**: What should explicitly NOT be included?
8. **Visual Design**: Do you have mockups or wireframes?

---

## Step 3: Process Answers

### Check for Visual Assets

```bash
ls specs/active/[folder]/visuals/
```

If files found: analyze for UI elements, layout, interactions, and fidelity level.

### Save to requirements.md

Document the full Q&A session, codebase analysis, and visual asset observations.

---

## Step 4: Summarize & Confirm

Present a requirements summary to the user and ask: "Does this accurately capture the requirements? Anything to add or correct?"

---

## Output

```
## Requirements Gathered

**Spec**: `specs/active/[folder]/`

### Summary
[1-2 sentence feature summary]

### Key Findings
- Codebase references: [count] existing features/components to leverage
- User stories identified: [count]
- Out of scope items: [count]
- Visual assets: [count] files

### Next Steps
Generate the specification: `/sdd-specify`
```
