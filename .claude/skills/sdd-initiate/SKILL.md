---
name: sdd-initiate
description: "Phase 1: Create feature branch and spec folder structure"
argument-hint: "[feature description or JIRA-KEY]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Initiate Specification

Create feature branch and spec folder structure.

## Input Handling

User provides: $ARGUMENTS

### Jira Detection

1. **Check pattern**: Does input match `[A-Z]+-[0-9]+`?
   - Yes → Attempt Jira fetch via MCP (if available)
   - No → Treat as feature description

2. **Graceful degradation**:
   - If Jira unavailable AND input is ticket ID → **ASK user**: "Jira unavailable. Please describe this feature so I can proceed."
   - If Jira unavailable AND input is description → Continue normally

---

## Generate Identifiers

### Get Current Date

```bash
date +%Y-%m-%d
```

### Branch Naming

**From Jira Issue:** `feature/[ISSUE-KEY]-[summary-slug]`
**From Description:** `feature/YYYY-MM-DD-[slug]`

### Spec Folder Naming (ALWAYS date-prefixed)

**From Jira Issue:** `specs/active/YYYY-MM-DD-[ISSUE-KEY]-[summary-slug]/`
**From Description:** `specs/active/YYYY-MM-DD-[slug]/`

Slug: 2-4 words, kebab-case

---

## Create Structure

### 1. Create Feature Branch

```bash
git checkout -b [branch-name]
```

If branch already exists, ask user: Use existing or create new?

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

### Next Steps
Proceed to shape requirements: `/sdd-shape`
```
