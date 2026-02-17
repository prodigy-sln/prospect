---
name: sdd-start
description: Start a new spec (phases 1-3 combined)
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
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__getAccessibleAtlassianResources
handoffs:
  - label: Create Tasks
    agent: sdd-tasks
    prompt: Create TDD-ordered task breakdown from the spec
    send: true
---

# Start New Specification

Combines phases 1-3: Initiate → Shape → Specify

## Input Handling

User provides: `$ARGUMENTS`

### Jira Detection

1. **Check pattern**: Does input match `[A-Z]+-[0-9]+`?
   - Yes → Attempt Jira fetch
   - No → Treat as feature description

2. **Jira MCP Detection**:
   ```
   Try: mcp__atlassian__getAccessibleAtlassianResources
   If succeeds → Jira AVAILABLE
   If fails → Jira NOT AVAILABLE
   ```

3. **If Jira available**: Fetch issue via `mcp__atlassian__getJiraIssue`
   - Extract: summary, description, acceptance criteria
   - Download attachments to `visuals/` folder

4. **Graceful degradation**:
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

Use this date (e.g., `2026-01-29`) for all folder names below.

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

### Codebase Discovery (MANDATORY - Do this FIRST)

Before asking questions, search the codebase for:
- Similar features or functionality
- Existing components that could be reused
- Relevant models, services, controllers
- API patterns to follow
- Database schemas to extend

Document findings to reference in your questions.

### Ask Targeted Questions (5-8)

Frame with sensible defaults based on codebase findings:

1. **Users & Permissions**:
   "Who will use this feature? I assume [default based on context]. Is that correct?"

2. **Core Workflow**:
   "What's the main user journey? Walk me through the happy path."

3. **Data Requirements**:
   "What data needs to be captured/displayed? Based on [existing feature], I'd expect [fields]. Anything to add/remove?"

4. **Integration Points**:
   "Does this integrate with existing features? I found [relevant code] that might be related."

5. **Validation & Business Rules**:
   "What validation rules apply? Any business constraints?"

6. **Edge Cases**:
   "What happens when [edge case]? How should errors be handled?"

7. **Out of Scope** (CRITICAL):
   "What should explicitly NOT be included in this iteration?"

8. **Visual Design**:
   "Do you have mockups or wireframes? Please add them to: `specs/active/[folder]/visuals/`"

### After Receiving Answers

1. **Check for visuals**:
   ```bash
   ls specs/active/[folder]/visuals/
   ```

2. **If images found**, analyze each for:
   - UI elements and patterns
   - User interactions
   - Fidelity level (wireframe → use for structure; mockup → follow closely)

3. **Save to requirements.md**:
   - All Q&A
   - Codebase findings
   - Visual analysis notes

---

## Phase 3: Specify

### Generate spec.md

Read `specs/_templates/spec.template.md` and fill all sections:

- **Goal**: 1-2 sentences - what problem solved, what value delivered
- **User Stories**: Max 5, format: "As a [user], I want [action] so that [benefit]"
- **Functional Requirements**: Grouped, numbered (FR-1.1, FR-1.2), each with acceptance criteria
- **Technical Considerations**: Architecture decisions, data model, API contracts
- **Test Strategy**: Unit, integration, E2E tests with coverage targets
- **Existing Code to Leverage**: Table with Feature | Location | What to Reuse
- **Visual Design**: Reference visuals, note fidelity level
- **Out of Scope**: Explicit exclusions (CRITICAL for preventing scope creep)
- **Dependencies**: Blocking and external
- **Assumptions**: Document assumptions made
- **Clarifications**: Include Q&A from shaping

### Quality Checks

- Every requirement must be testable
- No ambiguity, or mark with `[NEEDS CLARIFICATION]` (max 3-5 markers)
- Prioritize clarifications: scope > security > UX > technical
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
3. When ready, proceed to create tasks
```

Tell user to review spec before proceeding.
