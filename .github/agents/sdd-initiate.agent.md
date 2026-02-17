---
name: sdd-initiate
description: Phase 1 - Create feature branch and spec folder
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
  - label: Shape Requirements
    agent: sdd-shape
    prompt: Gather requirements through targeted questions
    send: true
---

# Initiate Specification

Create feature branch and spec folder structure.

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
   - Extract: summary → spec title, description → initial context
   - Download attachments to `visuals/` folder

4. **Graceful degradation**:
   - If Jira unavailable AND input is ticket ID → **ASK user**: "Jira unavailable. Please describe this feature so I can proceed."
   - If Jira unavailable AND input is description → Continue normally
   - Never proceed with just a ticket ID and no context

---

## Generate Identifiers

### Get Current Date

First, get today's date for folder naming:

```bash
date +%Y-%m-%d
```

Use this date (e.g., `2026-01-29`) for all folder names below.

### Branch Naming

**From Jira Issue:**
```
Branch: feature/[ISSUE-KEY]-[summary-slug]
Example: feature/PROJ-123-add-user-authentication
```

**From Description:**
```
Branch: feature/YYYY-MM-DD-[slug]
Example: feature/2026-01-29-user-auth-oauth
```

### Spec Folder Naming (ALWAYS date-prefixed)

**From Jira Issue:**
```
Folder: specs/active/YYYY-MM-DD-[ISSUE-KEY]-[summary-slug]/
Example: specs/active/2026-01-29-PROJ-123-add-user-authentication/
```

**From Description:**
```
Folder: specs/active/YYYY-MM-DD-[slug]/
Example: specs/active/2026-01-29-user-auth-oauth/
```

Slug: 2-4 words, kebab-case

---

## Create Structure

### 1. Create Feature Branch

```bash
git checkout -b [branch-name]
```

If branch already exists, ask user:
- Use existing branch?
- Create new branch with different name?

### 2. Create Folder Structure

```bash
mkdir -p specs/active/[folder-name]/visuals
```

### 3. Initialize spec.md

Copy from `specs/_templates/spec.template.md` and update frontmatter:

```yaml
---
id: SPEC-[XXX]
title: [Feature Title]
status: active
branch: [branch-name]
jira: [ISSUE-KEY or remove line]
created: [today's date]
updated: [today's date]
author: [from git config user.name]
---
```

### 4. Create requirements.md

```markdown
# Requirements Gathering: [Feature Title]

## Initial Context

[Jira description or user input]

## Codebase Analysis

[To be filled during shaping]

## Q&A Session

[To be filled during shaping]

## Visual Assets

[To be filled during shaping]
```

---

## Output

```
## Specification Initialized

**Branch**: `[branch-name]`
**Folder**: `specs/active/[folder-name]/`

### Created Files
- `spec.md` — Specification (from template)
- `requirements.md` — For requirements gathering
- `visuals/` — For mockups and wireframes

### Initial Context
[Summary of Jira issue or description]

### Next Steps
Proceed to shape requirements
```
