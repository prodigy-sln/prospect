# Prospect — Spec-Driven Development Framework

This project uses the **Prospect** framework for **Spec-Driven Development (SDD)** with Test-Driven Development (TDD).

## Development Workflow

All features follow this workflow:

```
/sdd-start [feature]  →  (/sdd-architect)  →  /sdd-tasks  →  /sdd-implement  →  /sdd-validate  →  /sdd-complete
```

## Key Principles

1. **Specs are source of truth** — Implement against specs, not imagination
2. **TDD is non-negotiable** — Tests before implementation, always
3. **Existing code first** — Search codebase before creating new components
4. **Scope control** — Out of Scope section is binding
5. **Human-in-the-loop** — User reviews spec and tasks before implementation

## Standards

Follow the standards in:

@standards/global/code-quality.md
@standards/global/testing.md
@standards/global/git-workflow.md

## Workflow Reference

```
PROJECT SETUP (Choose One)
  /sdd-init-project  — New project: Q&A → generate structure + standards
  /sdd-onboard       — Existing project: analyze codebase → generate standards

REQUIREMENTS CLARIFICATION (before /sdd-start)
  /sdd-clarify [issue-key]     — Gather requirements via issue tracker comments
                                  Works with Atlassian/Linear/Notion MCP or user interaction

FEATURE DEVELOPMENT
  /sdd-start [desc]  — Phases 1-3: branch + requirements + specification
      Phase 1: Initiate (branch + folder)
      Phase 2: Shape (codebase discovery + questions)
      ► /sdd-discuss  — (Optional) Stakeholder agent team discussion
      Phase 3: Specify (writes spec.md, incorporating discussion)
      ↓ [User reviews spec]
  /sdd-architect     — (Optional) Architecture planning before tasks
      ↓ [User reviews architecture]
  /sdd-tasks         — Phase 4: TDD-ordered task breakdown
      ↓ [User reviews tasks]
  /sdd-implement     — Phase 5: TDD implementation (Red-Green-Refactor)
      ↓
  /sdd-validate      — Phase 6: verify implementation vs spec (parallel reviewers)
      ↓
  /sdd-complete      — Phase 7: finalize, move spec to implemented/

GRANULAR CONTROL (instead of /sdd-start)
  /sdd-initiate → /sdd-shape → /sdd-specify

ISSUE-DRIVEN (unguided)
  /sdd-start-issue [issue-id]  — Full pipeline from issue to implementation
```

## Specs Location

- Active specs: `specs/active/YYYY-MM-DD-feature-name/`
- Completed specs: `specs/implemented/`
- Templates: `specs/_templates/`

## Before Writing Code

1. Check if a spec exists for this feature
2. If no spec, suggest using `/sdd-start`
3. Follow the task breakdown in `tasks.md`
4. Reference requirements (FR-X.X) from the spec

## Jira Integration

When Atlassian MCP is available:
- Start from Jira issues: `/sdd-start PROJ-123`
- Auto-fetch issue details and attachments
- Update issue status on completion
- Graceful fallback if unavailable

## Tech Stack

<!-- Updated by /sdd-init-project or /sdd-onboard -->
- Backend: [Not configured]
- Frontend: [Not configured]
- Database: [Not configured]
- Testing: [Not configured]
