# Prospect — Spec-Driven Development Framework

*By [prodigy.solutions](https://prodigy.solutions)*

A reusable spec-driven development (SDD) framework for AI-assisted coding tools that guides TDD-based development through structured phases.

## Supported Tools

| Tool | Status | Invocation |
|------|--------|------------|
| **VS Code Copilot** | Supported | `/sdd.start`, `@sdd-start` |
| **Claude Code** | Supported | `/sdd-start`, `/sdd-start-issue` |

## Quick Start

### New Project

| VS Code Copilot | Claude Code |
|-----------------|-------------|
| `/sdd.init-project` | `/sdd-init-project` |

The AI will ask about your tech stack, architecture, and preferences, then generate a complete project structure with Prospect configured.

### Existing Project

| VS Code Copilot | Claude Code |
|-----------------|-------------|
| `/sdd.onboard` | `/sdd-onboard` |

The AI will analyze your codebase to discover tech stack, naming conventions, linting rules, and test patterns, then generate matching standards files.

### Manual Installation

If you prefer manual setup:
1. **Copy this folder** to your project root
2. **Customize standards** in `standards/global/` for your tech stack
3. **Start a feature** with `/sdd.start` (Copilot) or `/sdd-start` (Claude Code)

---

## Installation

### Quick Install

```bash
# Bash (Linux/macOS/Git Bash)
curl -fsSL https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.sh | bash

# PowerShell (Windows)
irm https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.ps1 | iex
```

The script detects whether you are running interactively and prompts you to choose which toolchain(s) to install (Claude Code, VS Code Copilot, or both). Shared files (`standards/`, `specs/`, `product/`) are always installed.

### Script Options

| Flag (bash) | Flag (PowerShell) | Description |
|-------------|-------------------|-------------|
| `--claude` | `-Claude` | Install Claude Code toolchain only |
| `--copilot` | `-Copilot` | Install VS Code Copilot toolchain only |
| `--all` | `-All` | Install both toolchains (default) |
| `--help` | `-Help` | Show usage information |

To install a specific version instead of the latest release:

```bash
# Bash — pin to a version tag
curl -fsSL https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.sh | bash -s -- v1.2.0

# PowerShell — pin to a version tag
irm https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.ps1 | iex -Args v1.2.0
```

### Updating

Re-run the same install command at any time to update to the latest release:

```bash
curl -fsSL https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.sh | bash
```

The update process is safe for your customizations:

- **Unmodified framework files** — updated silently to the new version.
- **Files you have modified** — the new version is saved alongside as `<filename>.prospect-incoming`. Review the diff and merge manually (or ask your AI coding tool to help).
- **Your content** — `specs/active/`, `specs/implemented/`, `product/mission.md`, and `product/roadmap.md` are never touched.

After an update that produced conflicts, the script prints a summary of all `.prospect-incoming` files with the paths you need to review.

<details>
<summary>Manual Installation (fallback)</summary>

Copy the Prospect framework contents to your project:

```bash
cp -r prospect/.github /path/to/your/project/     # VS Code Copilot
cp -r prospect/.claude /path/to/your/project/      # Claude Code
cp -r prospect/CLAUDE.md /path/to/your/project/    # Claude Code
cp -r prospect/standards /path/to/your/project/    # Shared
cp -r prospect/specs /path/to/your/project/        # Shared
cp -r prospect/product /path/to/your/project/      # Optional
```

</details>

Your project structure should include:

```
your-project/
├── .prospect-version                  # Installed version tag (e.g. v1.0.0)
├── .prospect-manifest.json            # Per-file checksums for update tracking
├── CLAUDE.md                          # Claude Code project instructions
│
├── .claude/                           # Claude Code
│   ├── skills/                        #   Slash commands (/sdd-*)
│   │   ├── sdd-init-project/SKILL.md
│   │   ├── sdd-onboard/SKILL.md
│   │   ├── sdd-start/SKILL.md
│   │   ├── sdd-start-issue/SKILL.md  #   Issue-driven unguided pipeline
│   │   ├── sdd-clarify/SKILL.md     #   Requirements clarification via issue tracker
│   │   ├── sdd-initiate/SKILL.md
│   │   ├── sdd-shape/SKILL.md
│   │   ├── sdd-discuss/SKILL.md      #   Optional agent team discussion
│   │   ├── sdd-specify/SKILL.md
│   │   ├── sdd-architect/SKILL.md    #   Optional architecture planning
│   │   ├── sdd-tasks/SKILL.md
│   │   ├── sdd-implement/SKILL.md
│   │   ├── sdd-validate/SKILL.md
│   │   └── sdd-complete/SKILL.md
│   │
│   └── agents/                        #   TDD subagents
│       ├── sdd-architect.md           #   Architecture planning agent
│       ├── sdd-test-writer.md
│       ├── sdd-implementer.md
│       ├── sdd-refactorer.md          #   Quality-gated refactoring
│       ├── sdd-review-correctness.md  #   Correctness review (behavioral)
│       ├── sdd-review-coverage.md     #   Coverage review (test gaps)
│       ├── sdd-review-quality.md      #   Quality review (patterns, security, scope)
│       └── sdd-verifier.md            #   Quality gates + test verification
│
├── .github/                           # VS Code Copilot
│   ├── agents/                        #   Agent definitions (14 files)
│   ├── prompts/                       #   Command wrappers (10 files)
│   ├── instructions/sdd-context.md    #   Shared context
│   └── copilot-instructions.md        #   Copilot-specific instructions
│
├── standards/                         # Shared (both tool chains)
│   └── global/
│       ├── code-quality.md
│       ├── testing.md
│       └── git-workflow.md
│
├── specs/                             # Shared
│   ├── active/
│   ├── implemented/
│   └── _templates/
│       ├── spec.template.md
│       └── tasks.template.md
│
├── product/                           # Optional, shared
│   ├── mission.template.md
│   └── roadmap.template.md
│
└── [your project files]
```

---

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  PROJECT SETUP (New Projects Only)                              │
│  ─────────────────────────────────                              │
│  /sdd.init-project                                              │
│    ├── Q&A: tech stack, architecture, testing                   │
│    ├── Generate project structure                               │
│    ├── Generate standards for your stack                        │
│    └── Create mission.md                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  FEATURE DEVELOPMENT (Repeatable)                               │
│  ────────────────────────────────                               │
│                                                                 │
│  /sdd.clarify (Optional — before /sdd.start)                    │
│      └── Gather requirements from stakeholders via issue tracker │
│              │                                                  │
│              ▼ [Stakeholder responds]                           │
│                                                                 │
│  /sdd.start (Phases 1-3 combined)                               │
│      ├── Creates feature branch                                 │
│      ├── Searches codebase for similar features                 │
│      ├── Gathers requirements through Q&A                       │
│      ├── (Optional) /sdd.discuss — Agent team discussion        │
│      └── Generates specification                                │
│              │                                                  │
│              ▼ [User reviews spec]                              │
│                                                                 │
│  /sdd.architect (Optional)                                      │
│      └── Architecture planning before task breakdown             │
│              │                                                  │
│              ▼ [User reviews architecture]                      │
│                                                                 │
│  /sdd.tasks (Phase 4)                                           │
│      └── Creates TDD-ordered task breakdown                     │
│              │                                                  │
│              ▼ [User reviews tasks]                             │
│                                                                 │
│  /sdd.implement (Phase 5)                                       │
│      └── TDD implementation (Red-Green-Refactor)                │
│              │                                                  │
│              ▼                                                  │
│  /sdd.validate (Phase 6)                                        │
│      └── Parallel reviewers: correctness, coverage, quality     │
│              │                                                  │
│              ▼                                                  │
│  /sdd.complete (Phase 7)                                        │
│      └── Moves spec to implemented/, finalizes                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Commands

### Project Setup

| Phase | VS Code Copilot | Claude Code | Description |
|-------|----------------|-------------|-------------|
| Setup (new) | `/sdd.init-project` | `/sdd-init-project` | Initialize new project |
| Setup (existing) | `/sdd.onboard` | `/sdd-onboard` | Onboard existing project |

### Feature Development

| Phase | VS Code Copilot | Claude Code | Description |
|-------|----------------|-------------|-------------|
| — (optional) | — | `/sdd-clarify [issue]` | Requirements clarification via issue tracker |
| 1-3 combined | `/sdd.start [desc]` | `/sdd-start [desc]` | Start new spec |
| 1 | `/sdd.initiate` | `/sdd-initiate` | Create branch and folder |
| 2 | `/sdd.shape` | `/sdd-shape` | Gather requirements |
| 2.5 (optional) | — | `/sdd-discuss` | Agent team discussion (Claude Code only) |
| 3 | `/sdd.specify` | `/sdd-specify` | Generate specification |
| — (optional) | `/sdd.architect` | `/sdd-architect` | Architecture planning |
| 4 | `/sdd.tasks` | `/sdd-tasks` | Create TDD task breakdown |
| 5 | `/sdd.implement` | `/sdd-implement` | TDD implementation |
| 6 | `/sdd.validate` | `/sdd-validate` | Verify vs spec (parallel reviewers) |
| 7 | `/sdd.complete` | `/sdd-complete` | Finalize feature |
| — | — | `/sdd-start-issue [id]` | Issue-driven unguided pipeline |

### Using Agents Directly (VS Code Copilot)

Invoke agents with `@`:
- `@sdd-start` — Start new feature spec
- `@sdd-tasks` — Create task breakdown
- etc.

---

## Product Planning (Optional)

Prospect includes optional product-level documents:

### Mission Document (`product/mission.md`)

Defines project purpose, target users, and tech stack. Generated by `/sdd.init-project` or created manually from `mission.template.md`.

### Roadmap (`product/roadmap.md`)

Optional local roadmap for feature planning. **Not required** if using external tools like Jira.

**Roadmap → Specs flow:**
```
Roadmap Item → /sdd.start "feature name" → Spec in specs/active/
```

**Jira → Specs flow:**
```
Jira Epic/Ticket → /sdd.start PROJ-123 → Spec in specs/active/
```

---

## Key Features

### Guided Phase Transitions

After each phase completes, the agent suggests the next command. In VS Code Copilot this appears as a clickable handoff button; in Claude Code as a text prompt with the next `/sdd-*` command.

### TDD-First Approach

All implementation follows Red-Green-Refactor:
1. **RED**: Write failing tests first
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Improve while keeping tests green

### Existing Code Discovery

Before specifying new features, Prospect searches your codebase for:
- Similar features to reference
- Reusable components
- Patterns to follow

### Scope Control

The "Out of Scope" section prevents feature creep:
- Explicitly lists what's NOT included
- Enforced during implementation
- Verified during validation

### Agent Team Discussion (Optional, Claude Code only)

During shaping, `/sdd-discuss` spawns a stakeholder agent team — always including an Architect, plus 1-2 additional personas relevant to the feature (e.g., End User, Domain Expert, Product Owner) — to evaluate the plan from different perspectives before the spec is written. Uses [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams).

### Architecture Planning (Optional)

`/sdd-architect` produces a concise architecture plan between specification and task breakdown, covering key decisions, component design, data contracts, and integration points.

### Parallel Code Review During Validation

`/sdd-validate` launches 3 specialized reviewers in parallel alongside the verifier:
- **Correctness reviewer** — verifies implementation behavior matches spec requirements exactly
- **Coverage reviewer** — verifies all requirements have adequate test coverage
- **Quality reviewer** — checks code patterns, consistency, security, and scope compliance

Each reviewer has strict scope boundaries to prevent finding overlap, and uses a shared file manifest built by the orchestrator. Validation supports up to 2 passes with automatic escalation.

### Requirements Clarification

`/sdd-clarify` gathers requirements from stakeholders via issue tracker comments before spec writing. Works with Atlassian (Jira), Linear, or Notion MCP integrations when available; falls back to direct user interaction.

### Issue-Driven Pipeline

`/sdd-start-issue` takes a Jira issue ID or description and runs the full pipeline (start → architect → tasks → implement → validate) without requiring user interaction at each step.

### Jira Integration (Optional)

If Atlassian MCP is available:
- Start from Jira issues: `/sdd.start PROJ-123`
- Auto-fetch issue details and attachments
- Graceful fallback if unavailable

---

## Folder Structure

### specs/active/

Specs currently in development:

```
specs/active/2025-01-29-user-auth/
├── spec.md                # The specification
├── tasks.md               # Task breakdown
├── requirements.md        # Raw requirements from shaping
├── architecture.md        # Architecture plan (optional, from /sdd-architect)
├── validation-report.md   # Generated by validate phase
├── review-correctness.md  # Correctness review (behavioral verification)
├── review-coverage.md     # Coverage review (test gap analysis)
├── review-quality.md      # Quality review (patterns, security, scope)
└── visuals/               # Mockups, wireframes
```

### specs/implemented/

Completed specs (moved on completion).

### standards/global/

Quality standards (customize for your stack):
- `code-quality.md` - Code quality rules
- `testing.md` - TDD and testing requirements

### product/

Optional product documentation:
- `mission.md` - Project mission and overview
- `roadmap.md` - Feature roadmap (if not using external tool)

---

## Best Practices

1. **New projects**: Use `/sdd.init-project` (Copilot) or `/sdd-init-project` (Claude Code)
2. **Always start features with a spec** — Don't skip it
3. **Review before proceeding** — Check specs and tasks before implementation
4. **Follow TDD strictly** — Tests before code, always
5. **Respect scope** — Out of scope means out of scope
6. **Follow the workflow** — Let phase transitions guide you

---

## Architecture

Prospect supports two AI coding tools with parallel file structures:

### VS Code Copilot (`.github/`)

- **Prompt files** (`.github/prompts/`): Minimal wrappers for `/sdd.*` invocation
- **Agent files** (`.github/agents/`): Full instructions with handoff buttons

### Claude Code (`.claude/`)

- **Skills** (`.claude/skills/sdd-*/SKILL.md`): Slash commands for `/sdd-*` invocation
- **Subagents** (`.claude/agents/sdd-*.md`): TDD worker agents (test-writer, implementer, refactorer, verifier), architecture agent, and 3 specialized review agents (correctness, coverage, quality)
- **CLAUDE.md**: Project instructions with `@` imports to shared standards

### Shared (both tool chains)

- **Standards** (`standards/global/`): Immutable quality constitutions
- **Templates** (`specs/_templates/`): Spec and task templates
- **Specs** (`specs/active/`, `specs/implemented/`): Feature specifications
- **Context** (`.github/instructions/sdd-context.md`): Workflow reference

---

## License

MIT - Use freely in your projects.

---

*Prospect is developed by [prodigy.solutions](https://prodigy.solutions)*
