---
name: sdd-init-project
description: Initialize a new project with the Prospect SDD framework — gathers tech stack info and generates standards
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Initialize New Project

Configure the Prospect SDD framework for a new project by gathering requirements and generating project-specific files.

## Overview

This command:
1. Gathers project context through Q&A
2. Creates spec and product folder structure
3. Generates tech-stack-specific standards
4. Creates mission document and CLAUDE.md

---

## Step 1: Gather Project Context

Ask the user these questions (adapt based on answers):

### Round 1: Project Basics

1. **Project Name & Purpose**:
   "What is this project called, and what problem does it solve? (1-2 sentences)"

2. **Target Users**:
   "Who will use this application? (e.g., internal team, customers, developers)"

3. **Project Type**:
   "What type of project is this?
   - Web application (frontend + backend)
   - API/Backend service only
   - Frontend/UI only
   - CLI tool
   - Library/Package
   - Other: [describe]"

### Round 2: Tech Stack

4. **Backend Stack** (if applicable):
   "What backend technology?
   - .NET (C#)
   - Node.js (TypeScript/JavaScript)
   - Python (Django/FastAPI/Flask)
   - Java (Spring)
   - Go
   - Other: [specify]
   - No backend"

5. **Frontend Stack** (if applicable):
   "What frontend technology?
   - React (TypeScript)
   - Vue.js
   - Angular
   - Svelte
   - Server-rendered (Razor, Vaadin, etc.)
   - No frontend"

6. **Database** (if applicable):
   "What database?
   - SQL Server
   - PostgreSQL
   - MySQL
   - MongoDB
   - SQLite
   - No database
   - Other: [specify]"

### Round 3: Testing & Quality

7. **Test Framework**:
   "What test framework will you use?
   For backend: xUnit, NUnit, Jest, pytest, JUnit, etc.
   For frontend: Vitest, Jest, Testing Library, etc."

8. **Code Quality Tools**:
   "Any specific linting/formatting tools?
   - ESLint/Prettier (JS/TS)
   - StyleCop/EditorConfig (.NET)
   - Black/Ruff (Python)
   - Other: [specify]"

### Round 4: Integration & Workflow

9. **External Integrations**:
   "Will you use any of these? (select all that apply)
   - Jira (for ticket tracking)
   - GitHub (for source control)
   - CI/CD pipeline
   - Other: [specify]"

10. **Existing Standards**:
    "Do you have existing coding standards or conventions to incorporate?
    If yes, please share or describe them."

---

## Step 2: Create Folder Structure

Create the project-specific folders:

```bash
mkdir -p specs/active specs/implemented specs/_templates
mkdir -p standards/global
mkdir -p product
mkdir -p .claude/skills .claude/agents
```

---

## Step 3: Update CLAUDE.md

Update `CLAUDE.md` with the tech stack:

Replace the Tech Stack section at the bottom:
```markdown
## Tech Stack

<!-- Updated by /sdd-init-project -->
- Backend: [user's answer]
- Frontend: [user's answer]
- Database: [user's answer]
- Testing: [user's answer]
```

If `.github/copilot-instructions.md` exists, update it with the same tech stack info.

---

## Step 4: Generate Standards Files

Generate `standards/global/code-quality.md` and `standards/global/testing.md` based on the tech stack. Adapt naming conventions, patterns, and test framework details to the selected stack.

Generate `standards/global/git-workflow.md` with branch naming and commit conventions.

---

## Step 5: Generate Mission Document

Create `product/mission.md` from `product/mission.template.md`:

```markdown
# [Project Name]

## Mission

[1-2 sentence purpose from user input]

## Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | [from answers] |
| Frontend | [from answers] |
| Database | [from answers] |
| Testing | [from answers] |

## Key Principles

- **Spec-Driven Development (Prospect)**: All features start with a specification
- **Test-Driven Development**: Tests before implementation
- **Quality First**: Follow standards in `standards/global/`
```

---

## Step 6: Initialize Git (if not already)

```bash
git init
git add -A
git commit -m "chore: configure Prospect SDD framework for project"
```

---

## Output

```
## Project Configured

**Project**: [name]

### Files Created
- `CLAUDE.md` — Project instructions for Claude Code
- `standards/global/code-quality.md` — [stack] conventions
- `standards/global/testing.md` — TDD with [framework]
- `standards/global/git-workflow.md` — Git conventions
- `specs/active/` — For specs in development
- `specs/implemented/` — For completed specs
- `product/mission.md` — Project overview

### Next Steps
1. Review `product/mission.md`
2. Review standards in `standards/global/`
3. Start your first feature with `/sdd-start [description]`
```

---

## Notes

- This command configures Prospect for new projects
- For existing projects with code, use `/sdd-onboard` instead
- Standards are generated as starting points; customize as needed
