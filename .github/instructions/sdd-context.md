# Prospect — SDD Framework Context

This file provides reference documentation for the Prospect SDD workflow. The actual instructions are in the agent files (`.github/agents/*.agent.md`).

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  PROJECT SETUP (Choose One)                                     │
│  ──────────────────────────                                     │
│                                                                 │
│  /sdd.init-project - For NEW projects                           │
│      ├── Q&A: tech stack, architecture, testing                 │
│      ├── Generate project structure from scratch                │
│      └── Generate standards based on answers                    │
│                                                                 │
│  /sdd.onboard - For EXISTING projects                           │
│      ├── Analyze codebase for tech stack, patterns              │
│      ├── Discover naming conventions, test patterns             │
│      ├── Ask only when inference is unclear                     │
│      └── Generate standards matching existing code              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  FEATURE DEVELOPMENT                                            │
│  ───────────────────                                            │
│                                                                 │
│  /sdd.start (or @sdd-start) - Phases 1-3 combined               │
│      ├── Creates feature branch                                 │
│      ├── Gathers requirements (with codebase search)            │
│      └── Generates specification                                │
│              │                                                  │
│              ▼ [User reviews spec]                              │
│                                                                 │
│  /sdd.architect (or @sdd-architect) - Optional                  │
│      └── Architecture planning before task breakdown             │
│              │                                                  │
│              ▼ [User reviews architecture]                      │
│                                                                 │
│  /sdd.tasks (or @sdd-tasks) - Phase 4                           │
│      └── Creates TDD-ordered task breakdown                     │
│              │                                                  │
│              ▼ [User reviews tasks]                             │
│                                                                 │
│  /sdd.implement (or @sdd-implement) - Phase 5                   │
│      └── TDD implementation (Red-Green-Refactor)                │
│              │                                                  │
│              ▼                                                  │
│  /sdd.validate (or @sdd-validate) - Phase 6                     │
│      └── Verifies implementation vs spec                        │
│              │                                                  │
│              ▼                                                  │
│  /sdd.complete (or @sdd-complete) - Phase 7                     │
│      └── Moves spec to implemented/, finalizes                  │
└─────────────────────────────────────────────────────────────────┘
```

## Individual Phase Commands

For granular control, use individual phases:

- `/sdd.initiate` → `/sdd.shape` → `/sdd.specify` (instead of `/sdd.start`)

## Key Principles

1. **Specs are source of truth** - AI implements against specs, not imagination
2. **TDD is non-negotiable** - Tests before implementation, always
3. **Existing code first** - Search codebase before specifying new components
4. **Scope control** - Out of Scope section is binding
5. **Human-in-the-loop** - User reviews spec before tasks, tasks before implementation

## Folder Structure

```
project/
├── .github/
│   ├── agents/             # Prospect agents with full instructions
│   ├── prompts/            # Prospect commands (wrappers)
│   └── instructions/       # Reference docs
│
├── standards/
│   └── global/
│       ├── code-quality.md # Tech-stack-specific quality rules
│       └── testing.md      # TDD requirements
│
├── specs/
│   ├── active/             # Specs in development
│   │   └── YYYY-MM-DD-feature/
│   │       ├── spec.md
│   │       ├── tasks.md
│   │       ├── requirements.md
│   │       ├── architecture.md      # Optional, from /sdd.architect
│   │       ├── validation-report.md
│   │       ├── code-review.md       # From validation phase
│   │       └── visuals/
│   │
│   ├── implemented/        # Completed specs
│   │
│   └── _templates/
│       ├── spec.template.md
│       └── tasks.template.md
│
└── product/                # Optional product docs
    ├── mission.md          # Project mission and overview
    └── roadmap.md          # Feature roadmap (if not using Jira)
```

## Jira Integration

When Atlassian MCP is available:
- Start from Jira issues: `/sdd.start PROJ-123`
- Auto-fetch issue details and attachments
- Update issue status on completion

When unavailable:
- Graceful degradation
- If ticket ID provided without Jira, ask user for description

## Roadmap → Specs

Features can originate from:
1. **Jira tickets**: `/sdd.start PROJ-123`
2. **Local roadmap**: `/sdd.start "feature from roadmap"`
3. **Ad-hoc description**: `/sdd.start "new feature idea"`

Traceability is maintained via spec frontmatter linking to source.
