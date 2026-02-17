---
name: sdd-onboard
description: Onboard an existing project to Prospect SDD framework by discovering standards
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
    prompt: Start specifying a feature for this project
    send: true
---

# Onboard Existing Project

Analyze an existing codebase to discover conventions, patterns, and standards, then generate matching configuration.

## Overview

This command:
1. Scans the codebase to infer tech stack, patterns, conventions
2. Analyzes existing documentation and configuration
3. Discovers testing patterns and quality tools
4. Generates standards files matching the existing codebase
5. Only asks clarifying questions when inference is unclear

---

## Step 1: Tech Stack Discovery

### Detect Backend

Search for project files:

```bash
# .NET
ls *.sln *.csproj 2>/dev/null
cat *.csproj 2>/dev/null | grep -E "<TargetFramework|<PackageReference"

# Node.js
cat package.json 2>/dev/null | grep -E '"dependencies"|"devDependencies"'

# Python
cat requirements.txt setup.py pyproject.toml 2>/dev/null

# Java
cat pom.xml build.gradle 2>/dev/null

# Go
cat go.mod 2>/dev/null
```

**Inference rules:**
- `.sln`/`.csproj` → .NET (check TargetFramework for version)
- `package.json` with express/fastify/nest → Node.js backend
- `requirements.txt` with django/fastapi/flask → Python backend
- `pom.xml`/`build.gradle` → Java
- `go.mod` → Go

### Detect Frontend

```bash
# Check package.json for frontend frameworks
cat package.json 2>/dev/null | grep -E "react|vue|angular|svelte|next|nuxt"

# Check for frontend-specific files
ls src/App.tsx src/App.jsx src/main.ts src/App.vue 2>/dev/null
```

**Inference rules:**
- `react`/`react-dom` in dependencies → React
- `vue` in dependencies → Vue.js
- `@angular/core` → Angular
- `svelte` → Svelte
- Vaadin dependencies in Java project → Vaadin

### Detect Database

```bash
# Check connection strings, ORM configs
grep -r "ConnectionString\|DATABASE_URL\|POSTGRES\|MYSQL\|MONGO" --include="*.json" --include="*.config" --include=".env*" 2>/dev/null
cat package.json 2>/dev/null | grep -E "sequelize|typeorm|prisma|mongoose|pg|mysql"
grep -r "DbContext\|EntityFramework" --include="*.cs" 2>/dev/null | head -5
```

**Inference rules:**
- `EntityFramework` + `SqlServer` → SQL Server
- `Npgsql` → PostgreSQL
- `prisma`/`pg` in package.json → PostgreSQL
- `mongoose` → MongoDB

---

## Step 2: Code Convention Discovery

### Naming Conventions

Analyze existing code:

```bash
# Sample class/function names
grep -r "class \|interface \|function \|const \|let \|var " --include="*.cs" --include="*.ts" --include="*.js" --include="*.py" | head -30
```

**Inference:**
- Classes: PascalCase vs camelCase
- Methods/Functions: PascalCase vs camelCase vs snake_case
- Variables: camelCase vs snake_case
- Files: PascalCase vs kebab-case vs snake_case

### Code Organization

```bash
# Understand folder structure
find . -type d -name "src" -o -name "lib" -o -name "app" -o -name "components" -o -name "services" -o -name "models" -o -name "controllers" 2>/dev/null | head -20

# Check for layered architecture
ls -la src/ lib/ app/ 2>/dev/null
```

**Document patterns found:**
- Folder structure (feature-based, layer-based, hybrid)
- File organization (one class per file, grouped by feature, etc.)
- Typical file sizes

### Existing Patterns

Search for common patterns:

```bash
# Repository pattern
grep -r "Repository\|IRepository" --include="*.cs" --include="*.ts" 2>/dev/null | head -5

# Service pattern
grep -r "Service\|IService" --include="*.cs" --include="*.ts" 2>/dev/null | head -5

# Dependency injection
grep -r "AddScoped\|AddTransient\|AddSingleton\|@Injectable\|@Inject" --include="*.cs" --include="*.ts" 2>/dev/null | head -5
```

---

## Step 3: Quality Tools Discovery

### Linting & Formatting

```bash
# Check for config files
ls .eslintrc* .prettierrc* .editorconfig stylecop.json .rubocop.yml pyproject.toml 2>/dev/null

# Read configs
cat .eslintrc* .prettierrc* .editorconfig 2>/dev/null
```

**Document found rules:**
- ESLint rules in use
- Prettier configuration
- EditorConfig settings
- StyleCop/Analyzer rules

### Pre-commit Hooks

```bash
cat .pre-commit-config.yaml .husky/pre-commit 2>/dev/null
```

---

## Step 4: Testing Discovery

### Test Framework

```bash
# .NET
grep -r "xunit\|nunit\|mstest" --include="*.csproj" 2>/dev/null
ls *Test*.csproj *Tests*.csproj 2>/dev/null

# Node.js
cat package.json 2>/dev/null | grep -E "jest|vitest|mocha|jasmine"

# Python
cat pyproject.toml setup.cfg 2>/dev/null | grep -E "pytest|unittest"

# Java
grep -r "junit\|testng" --include="pom.xml" --include="build.gradle" 2>/dev/null
```

### Test Patterns

```bash
# Sample test files
find . -name "*.test.ts" -o -name "*.spec.ts" -o -name "*Test.cs" -o -name "test_*.py" 2>/dev/null | head -10

# Read a sample test
cat $(find . -name "*.test.ts" -o -name "*Test.cs" 2>/dev/null | head -1) 2>/dev/null | head -50
```

**Infer:**
- Test naming convention
- Test organization (alongside code vs separate folder)
- Assertion style
- Mocking approach

### Coverage

```bash
# Check for coverage config
grep -r "coverageThreshold\|min_coverage\|<CoverletOutput" --include="*.json" --include="*.csproj" --include="pyproject.toml" 2>/dev/null
```

---

## Step 5: Documentation Discovery

### Existing Docs

```bash
# Find documentation
ls README.md CONTRIBUTING.md docs/ wiki/ 2>/dev/null
cat README.md CONTRIBUTING.md 2>/dev/null | head -100
```

**Extract:**
- Setup instructions
- Development workflow
- Coding guidelines mentioned
- Architecture overview

### Code Comments

```bash
# Check comment style
grep -r "//\|/\*\|#\|'''" --include="*.cs" --include="*.ts" --include="*.py" 2>/dev/null | head -20
```

**Infer:**
- Comment style (XML docs, JSDoc, docstrings)
- Documentation thoroughness

---

## Step 6: Integration Discovery

### Jira/Atlassian

```
Try: mcp__atlassian__getAccessibleAtlassianResources
If succeeds → Note Jira project keys available
```

### CI/CD

```bash
ls .github/workflows/ .gitlab-ci.yml Jenkinsfile azure-pipelines.yml 2>/dev/null
cat .github/workflows/*.yml 2>/dev/null | head -50
```

### Git Workflow

```bash
# Check branch naming
git branch -a 2>/dev/null | head -20

# Check commit message style
git log --oneline -20 2>/dev/null
```

---

## Step 7: Generate Discovery Report

Before generating standards, present findings to user:

```markdown
## Codebase Analysis Report

### Tech Stack Detected
| Layer | Technology | Confidence |
|-------|------------|------------|
| Backend | [detected] | High/Medium/Low |
| Frontend | [detected] | High/Medium/Low |
| Database | [detected] | High/Medium/Low |
| Testing | [detected] | High/Medium/Low |

### Code Conventions Found
- **Naming**: [PascalCase classes, camelCase methods, etc.]
- **Organization**: [layered/feature-based/hybrid]
- **Patterns**: [Repository, Service, DI, etc.]

### Quality Tools
- **Linting**: [ESLint with X rules / StyleCop / etc.]
- **Formatting**: [Prettier / EditorConfig / etc.]
- **Pre-commit**: [Yes/No - list hooks]

### Testing Patterns
- **Framework**: [xUnit/Jest/pytest/etc.]
- **Style**: [Arrange-Act-Assert / Given-When-Then / etc.]
- **Coverage**: [X% target / not configured]

### Documentation
- **README**: [Yes/No - summary]
- **Contributing guide**: [Yes/No]
- **Code comments**: [XML docs / JSDoc / minimal]

### Integrations
- **Jira**: [Available - projects: X, Y / Not available]
- **CI/CD**: [GitHub Actions / GitLab CI / etc.]
- **Git workflow**: [feature branches / trunk-based / etc.]

---

### Clarifications Needed

[Only if confidence is Low or unclear]

1. [Question about unclear aspect]
2. [Question about unclear aspect]
```

---

## Step 8: Ask Clarifying Questions (Only If Needed)

Only ask questions when:
- Confidence is "Low" on critical aspects
- Conflicting patterns detected
- Missing critical information

Example questions:

**If test coverage unclear:**
"I found tests but no coverage threshold configured. What minimum coverage should be required? (Default: 80%)"

**If naming inconsistent:**
"I found mixed naming conventions (some PascalCase, some camelCase for methods). Which should be the standard?"

**If architecture unclear:**
"The codebase has both feature-based and layer-based organization. Which pattern should new code follow?"

---

## Step 9: Create Spec Folders

Create the project-specific folders (framework files already exist):

```bash
# Spec folders (if not present)
mkdir -p specs/active specs/implemented

# Product documentation
mkdir -p product
```

---

## Step 10: Update Copilot Instructions

Update `.github/copilot-instructions.md` with discovered tech stack:

Replace the Tech Stack section at the bottom:
```markdown
## Tech Stack

<!-- Updated by /sdd.onboard -->
- Backend: [detected technology]
- Frontend: [detected technology]
- Database: [detected technology]
- Testing: [detected framework]
```

---

## Step 11: Generate Standards Files

### code-quality.md

Generate based on discoveries:

```markdown
# Code Quality Standards

> Auto-generated from codebase analysis on [date]
> Review and adjust as needed

## Tech Stack

- **Backend**: [detected]
- **Frontend**: [detected]
- **Database**: [detected]

## Naming Conventions

[Based on discovered patterns]

### Classes/Types
- Style: [PascalCase]
- Example: `UserService`, `OrderRepository`

### Methods/Functions
- Style: [camelCase/PascalCase]
- Example: `getUserById`, `ProcessOrder`

### Variables
- Style: [camelCase]
- Example: `userId`, `orderTotal`

### Files
- Style: [kebab-case/PascalCase]
- Example: `user-service.ts` or `UserService.cs`

## Code Organization

[Based on discovered structure]

- **Architecture**: [layered/feature-based]
- **File placement**: [describe pattern]
- **Max file size**: [soft limit based on observed patterns]

## Patterns in Use

[List discovered patterns]

- [x] Repository pattern
- [x] Service layer
- [x] Dependency injection
- [ ] CQRS
- [ ] Event sourcing

## Quality Tools

### Linting
[Discovered config or recommendation]

### Formatting
[Discovered config or recommendation]

## Code Review Checklist

- [ ] Follows naming conventions
- [ ] Placed in correct folder/layer
- [ ] Uses existing patterns
- [ ] No code duplication
- [ ] Appropriate error handling
```

### testing.md

Generate based on discoveries:

```markdown
# Testing Standards

> Auto-generated from codebase analysis on [date]

## Test Framework

- **Framework**: [detected]
- **Assertion library**: [detected]
- **Mocking**: [detected]

## TDD Workflow (NON-NEGOTIABLE)

1. RED: Write failing test first
2. GREEN: Minimal code to pass
3. REFACTOR: Improve while green

## Test Organization

[Based on discovered patterns]

- **Location**: [alongside code / separate folder]
- **Naming**: [*.test.ts / *Test.cs / test_*.py]

## Naming Convention

[Based on discovered patterns]

```
[detected pattern]
Example: test_[unit]_[scenario]_[expected]
         or describe/it blocks
```

## Coverage Requirements

- **Minimum**: [detected or default 80%]
- **Critical paths**: 100%

## Example Test Structure

[Include sample from codebase]

```[language]
[sample test from codebase]
```
```

---

## Step 12: Generate Mission (Optional)

If README contains project description, generate `product/mission.md`:

```markdown
# [Project Name]

## Mission

[Extracted from README or inferred]

## Tech Stack

[From discovery]

## Development Workflow

This project uses the **Prospect** framework for **Spec-Driven Development (SDD)**.

See `standards/global/` for coding standards.
```

---

## Output

```markdown
## Prospect Onboarding Complete

**Project**: [name from package.json/.csproj/etc.]

### Discovered Tech Stack
| Layer | Technology |
|-------|------------|
| Backend | [tech] |
| Frontend | [tech] |
| Database | [tech] |
| Testing | [framework] |

### Files Generated
- `standards/global/code-quality.md` - Based on codebase analysis
- `standards/global/testing.md` - Based on test patterns found
- `specs/active/` - For specs in development
- `specs/implemented/` - For completed specs
- `product/mission.md` - From README (if applicable)

### Standards Inferred From
- Naming: [X files analyzed]
- Patterns: [X patterns detected]
- Tests: [X test files analyzed]
- Config: [list configs found]

### Manual Review Recommended
- [ ] Review `standards/global/code-quality.md`
- [ ] Review `standards/global/testing.md`
- [ ] Adjust coverage thresholds if needed
- [ ] Add any team-specific conventions

### Next Steps
1. Review generated standards
2. Commit configuration files
3. Start your first feature: `/sdd.start [description]`
```

---

## Notes

- This agent infers from code; always review generated standards
- Low-confidence inferences are marked for user review
- Existing linting/formatting configs are respected and documented
- The goal is to match existing conventions, not impose new ones
