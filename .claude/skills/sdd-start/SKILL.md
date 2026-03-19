---
name: sdd-start
description: Start a new Prospect spec — combines phases 1-3 (Initiate, Shape, Specify) into a single command
argument-hint: "[feature description or JIRA-KEY]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Start New Specification

Combines phases 1-3: Initiate → Shape → Specify

## Input Handling

User provides: $ARGUMENTS

### Jira Detection

1. **Check pattern**: Does input match `[A-Z]+-[0-9]+`?
   - Yes → Attempt Jira fetch
   - No → Treat as feature description

2. **Jira MCP Detection**:
   Try fetching Jira resources. If MCP tools are available, use them.
   If unavailable and input is a ticket ID, ask user for a description instead.
   If ticket is found, move to in progress and assign to current user.

3. **Graceful degradation**:
   - If Jira unavailable AND input is ticket ID → **ASK user**: "Jira unavailable. Please describe this feature so I can proceed."
   - If Jira unavailable AND input is description → Continue normally
   - Never proceed with just a ticket ID and no context

---

## Phase 1: Initiate

### Get Current Date

First, get today's date for folder naming:

```bash
date +%Y-%m-%d
```

Use this date for all folder names below.

### Generate Identifiers

**Branch naming:**
- From Jira: `feature/[ISSUE-KEY]-[summary-slug]`
- From description: `feature/YYYY-MM-DD-[slug]`

**Spec folder naming (ALWAYS date-prefixed):**
- From Jira: `specs/active/YYYY-MM-DD-[ISSUE-KEY]-[summary-slug]/`
- From description: `specs/active/YYYY-MM-DD-[slug]/`

Slug: 2-4 words, kebab-case (e.g., `2026-01-29-state-management-system`)

### Create Structure

```bash
git checkout -b [branch-name]
mkdir -p specs/active/[folder-name]/visuals
```

1. Copy `specs/_templates/spec.template.md` → `spec.md`
2. Update frontmatter: id, title, branch, status: active, created, updated
3. Create `requirements.md` with initial context

---

## Phase 2: Shape

### Codebase Discovery (MANDATORY — Delegate to Explore subagent)

Before asking questions, use the **Task tool** with `subagent_type: Explore` to search the codebase. This preserves context on the main conversation.

Delegate with this prompt:

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

Save findings to reference in your questions. Document in `requirements.md` under "Codebase Analysis".

### Ask Targeted Questions (5-8)

Frame with sensible defaults based on codebase findings:

1. **Users & Permissions**: Who will use this feature?
2. **Core Workflow**: What's the main user journey?
3. **Data Requirements**: What data needs to be captured/displayed?
4. **Integration Points**: Does this integrate with existing features?
5. **Validation & Business Rules**: What validation rules apply?
6. **Edge Cases**: What happens when things go wrong?
7. **Out of Scope** (CRITICAL): What should explicitly NOT be included?
8. **Visual Design**: Do you have mockups or wireframes?

### After Receiving Answers

1. **Check for visuals**: `ls specs/active/[folder]/visuals/`
2. **If images found**, analyze for UI elements, patterns, fidelity level
3. **Save to requirements.md**: All Q&A, codebase findings, visual analysis

---

## Phase 2.5: Discuss (Optional — Agent Team)

After shaping is complete and requirements.md is saved, invoke `/sdd-discuss` to get multi-perspective feedback before writing the spec.

This spawns a stakeholder agent team (always including an Architect, plus 1-2 additional personas relevant to the feature) that discusses the feature plan, answers open questions, and surfaces concerns. Their findings are appended to `requirements.md` under `## Discussion Findings`.

**When to invoke**: Always offer this to the user. It's especially valuable when:
- There are unresolved open questions from shaping
- The feature touches multiple systems or stakeholder concerns
- Trade-offs between competing priorities are non-obvious
- The user wants a sanity check before committing to a spec

**When to skip**: The user explicitly declines, or the feature is trivially scoped.

Ask the user: *"Would you like me to run /sdd-discuss to get stakeholder feedback (Architect + relevant personas) before I write the spec?"*

If yes, invoke the `sdd-discuss` skill via the Skill tool. After it completes, continue to Phase 3 below — the Specify phase will incorporate the discussion findings from `requirements.md`.

---

## Phase 3: Specify

### Generate spec.md

Read `specs/_templates/spec.template.md` and fill all sections:

- **Goal**: 1-2 sentences — what problem solved, what value delivered
- **User Stories**: Max 5, format: "As a [user], I want [action] so that [benefit]"
- **Functional Requirements**: Grouped, numbered (FR-1.1, FR-1.2), each with acceptance criteria
- **Technical Considerations**: Architecture decisions, data model, API contracts
- **Test Strategy**: Unit, integration, E2E tests with coverage targets
- **Existing Code to Leverage**: Table with Feature | Location | What to Reuse
- **Visual Design**: Reference visuals, note fidelity level
- **Out of Scope**: Explicit exclusions (CRITICAL for preventing scope creep)
- **Dependencies**: Blocking and external
- **Assumptions**: Document assumptions made
- **Clarifications**: Include Q&A from shaping and discussion findings (if `/sdd-discuss` was run)

### Quality Checks

- Every requirement must be testable
- No ambiguity, or mark with `[NEEDS CLARIFICATION]` (max 3-5 markers)
- Out of scope must be comprehensive
- Existing code must be referenced where applicable

---

## Output

```
## Specification Complete

**Branch**: `[branch-name]`
**Spec**: `specs/active/[folder]/spec.md`

### Stats
- User Stories: [count]
- Functional Requirements: [count]
- Existing Code References: [count]
- Out of Scope Items: [count]

### Next Steps
1. Review the spec
2. Add any missing visuals
3. (Optional) Run: `/sdd-architect` to capture the architecture plan before tasks
4. When ready, run: `/sdd-tasks`
```

Tell user to review spec before proceeding.
