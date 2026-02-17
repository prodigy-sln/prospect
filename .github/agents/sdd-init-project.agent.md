---
name: sdd-init-project
description: Initialize a new project with Prospect SDD framework
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
  - mcp__atlassian__getAccessibleAtlassianResources
handoffs:
  - label: Start First Feature
    agent: sdd-start
    prompt: Start specifying the first feature for this project
    send: true
---

# Initialize New Project

Configure the Prospect SDD framework for a new project by gathering requirements and generating project-specific files.

## Overview

This command:
1. Gathers project context through Q&A
2. Creates spec and product folder structure
3. Generates tech-stack-specific standards
4. Creates mission document and README

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
   - Jira/Atlassian (for ticket tracking)
   - GitHub (for source control)
   - CI/CD pipeline
   - Other: [specify]"

10. **Existing Standards**:
    "Do you have existing coding standards or conventions to incorporate?
    If yes, please share or describe them."

---

## Step 2: Create Folder Structure

Create the project-specific folders (framework files already exist):

```bash
# Spec folders
mkdir -p specs/active specs/implemented

# Product documentation
mkdir -p product
```

---

## Step 3: Update Copilot Instructions

Update `.github/copilot-instructions.md` with the tech stack:

Replace the Tech Stack section at the bottom:
```markdown
## Tech Stack

<!-- Updated by /sdd.init-project -->
- Backend: [user's answer]
- Frontend: [user's answer]
- Database: [user's answer]
- Testing: [user's answer]
```

---

## Step 4: Generate Standards Files

### standards/global/code-quality.md

Generate based on tech stack. Examples:

**For .NET projects:**
```markdown
# Code Quality Standards

## Naming Conventions
- Classes: PascalCase
- Methods: PascalCase
- Variables: camelCase
- Constants: UPPER_SNAKE_CASE
- Interfaces: IPascalCase

## Code Organization
- One class per file
- Group related files in folders
- Max 200 lines per file (soft limit)

## SOLID Principles
- Single Responsibility: Each class has one reason to change
- Open/Closed: Open for extension, closed for modification
- Liskov Substitution: Subtypes must be substitutable
- Interface Segregation: Many specific interfaces over one general
- Dependency Inversion: Depend on abstractions

## .NET Specific
- Use explicit types over var
- Opening braces on same line
- Use nullable reference types
```

**For Node.js/TypeScript:**
```markdown
# Code Quality Standards

## Naming Conventions
- Files: kebab-case.ts
- Classes/Types: PascalCase
- Functions/Variables: camelCase
- Constants: UPPER_SNAKE_CASE

## TypeScript Specific
- Strict mode enabled
- Explicit return types on public functions
- Prefer interfaces over type aliases for objects
```

[Generate appropriate content for selected stack]

### standards/global/testing.md

Generate based on test framework:

```markdown
# Testing Standards

## TDD Workflow (NON-NEGOTIABLE)

1. RED: Write failing test first
2. GREEN: Minimal code to pass
3. REFACTOR: Improve while green

## Test Framework: [selected]

## Naming Convention
[Stack-specific naming]

## Coverage Requirements
- Minimum: 80%
- Critical paths: 100%
```

---

## Step 5: Generate Mission Document

Create `product/mission.md`:

```markdown
# [Project Name]

## Mission

[1-2 sentence purpose from user input]

## Target Users

[From user input]

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

## Getting Started

1. Clone the repository
2. [Stack-specific setup instructions]
3. Start your first feature: `/sdd.start [description]`

## Development Workflow

```
/sdd.start [feature]     # Create spec (phases 1-3)
/sdd.tasks               # Generate TDD task breakdown
/sdd.implement           # TDD implementation
/sdd.validate            # Verify vs spec
/sdd.complete            # Finalize
```
```

---

## Step 6: Update/Generate README

If no README exists, create one. If one exists, offer to add SDD section:

```markdown
# [Project Name]

[Mission statement]

## Quick Start

[Stack-specific setup]

## Development

This project uses the **Prospect** framework for **Spec-Driven Development (SDD)**.

### Starting a New Feature

```bash
# From Jira ticket
/sdd.start PROJ-123

# From description
/sdd.start "Add user authentication"
```

### Workflow

1. `/sdd.start` - Create specification
2. `/sdd.tasks` - Generate task breakdown
3. `/sdd.implement` - TDD implementation
4. `/sdd.validate` - Verify implementation
5. `/sdd.complete` - Finalize

## Standards

- Code quality: `standards/global/code-quality.md`
- Testing: `standards/global/testing.md`
```

---

## Step 7: Initialize Git (if not already)

```bash
# Only if no .git folder exists
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
- `standards/global/code-quality.md` - [stack] conventions
- `standards/global/testing.md` - TDD with [framework]
- `specs/active/` - For specs in development
- `specs/implemented/` - For completed specs
- `product/mission.md` - Project overview

### Tech Stack
- Backend: [tech]
- Frontend: [tech]
- Database: [tech]
- Testing: [framework]

### Next Steps
1. Review `product/mission.md`
2. Review standards in `standards/global/`
3. Start your first feature with `/sdd.start [description]`
```

---

## Notes

- This command configures Prospect for new projects
- For existing projects with code, use `/sdd.onboard` instead
- Standards are generated as starting points; customize as needed
