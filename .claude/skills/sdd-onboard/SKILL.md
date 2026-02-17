---
name: sdd-onboard
description: Onboard an existing project to Prospect SDD framework by analyzing codebase and discovering standards
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Onboard Existing Project

Analyze an existing codebase to discover conventions, patterns, and standards, then generate matching Prospect SDD configuration.

## Overview

This command:
1. Delegates codebase scanning to an Explore subagent (preserves main context)
2. Presents discovery report with detected tech stack, conventions, and tools
3. Generates standards files matching the existing codebase
4. Only asks clarifying questions when inference is unclear

---

## Step 1: Delegate Codebase Discovery (via Explore subagent)

Use the **Task tool** with `subagent_type: Explore` to scan the codebase. This preserves context on the main conversation by offloading heavy file scanning to an isolated subagent.

### Launch Explore Subagent

Delegate with this prompt:

```
Perform a comprehensive codebase analysis for onboarding to the Prospect SDD framework.
Return a structured discovery report covering ALL of the following sections:

### 1. Tech Stack Detection
Search for project files and report what you find:
- Backend: .sln/.csproj (→ .NET), package.json with express/fastify/nest (→ Node.js), requirements.txt with django/fastapi/flask (→ Python), pom.xml/build.gradle (→ Java), go.mod (→ Go)
- Frontend: react/react-dom (→ React), vue (→ Vue.js), @angular/core (→ Angular), svelte (→ Svelte), Vaadin dependencies (→ Vaadin)
- Database: connection strings, ORM configs, database driver dependencies
- For each detection, note the version where identifiable and confidence level (High/Medium/Low)

### 2. Code Convention Discovery
- Naming: Analyze 5-10 source files for class, method, variable, file naming styles
- Organization: Is the folder structure feature-based, layer-based, or hybrid?
- Patterns: Search for repository pattern, service layer, dependency injection, CQRS, and other architectural patterns

### 3. Quality Tools Discovery
Search for config files: .eslintrc*, .prettierrc*, .editorconfig, stylecop.json, .pre-commit-config.yaml, tslint.json, .stylelintrc*, and any linting/formatting configs

### 4. Testing Discovery
- Test framework: detect from project files (xUnit, NUnit, Jest, Vitest, pytest, JUnit, etc.)
- Test naming conventions: analyze existing test files for naming patterns
- Test organization: how are tests structured (co-located, separate test/ folder, etc.)
- Assertion style: what assertion library is used
- Coverage configuration: any coverage tools configured

### 5. Documentation Discovery
- Read README.md for project description, setup instructions, architecture notes
- Check for CONTRIBUTING.md, CHANGELOG.md, ADRs
- Note any inline documentation conventions observed

### 6. Integration Discovery
- CI/CD: search for .github/workflows/, .gitlab-ci.yml, Jenkinsfile, azure-pipelines.yml
- Git workflow: check branch naming from `git branch -a`, commit message patterns from recent commits
- Check for existing CLAUDE.md, .github/copilot-instructions.md, or similar AI tool configs

Format the report as a single markdown document with clear section headers and tables.
```

### Process Discovery Report

The Explore subagent returns a structured report. Use this report for all subsequent steps — do NOT re-scan the codebase.

---

## Step 2: Generate Discovery Report

Present findings to user before generating standards:

```markdown
## Codebase Analysis Report

### Tech Stack Detected
| Layer | Technology | Confidence |
|-------|------------|------------|
| Backend | [detected] | High/Medium/Low |
| Frontend | [detected] | High/Medium/Low |
| Database | [detected] | High/Medium/Low |
| Testing | [detected] | High/Medium/Low |

### Clarifications Needed
[Only if confidence is Low or unclear]
```

---

## Step 3: Create Folders and Files

```bash
mkdir -p specs/active specs/implemented specs/_templates
mkdir -p standards/global
mkdir -p product
```

---

## Step 4: Update CLAUDE.md

Create or update `CLAUDE.md` with discovered tech stack. If `.github/copilot-instructions.md` exists, update it too.

---

## Step 5: Generate Standards Files

Generate `standards/global/code-quality.md` and `standards/global/testing.md` matching the discovered patterns.

Generate `standards/global/git-workflow.md` based on observed branch and commit conventions.

---

## Step 6: Generate Mission (Optional)

If README contains project description, generate `product/mission.md`.

---

## Output

```
## Prospect Onboarding Complete

**Project**: [name]

### Discovered Tech Stack
| Layer | Technology |
|-------|------------|
| Backend | [tech] |
| Frontend | [tech] |
| Database | [tech] |
| Testing | [framework] |

### Files Generated
- `CLAUDE.md` — Project instructions for Claude Code
- `standards/global/code-quality.md` — Based on codebase analysis
- `standards/global/testing.md` — Based on test patterns found
- `standards/global/git-workflow.md` — Based on git history
- `specs/active/` — For specs in development
- `specs/implemented/` — For completed specs

### Next Steps
1. Review generated standards
2. Commit configuration files
3. Start your first feature: `/sdd-start [description]`
```

---

## Notes

- This agent infers from code; always review generated standards
- Low-confidence inferences are marked for user review
- Existing linting/formatting configs are respected and documented
- The goal is to match existing conventions, not impose new ones
