# Project Instructions — Prospect

This project uses the **Prospect** framework for **Spec-Driven Development (SDD)** with Test-Driven Development (TDD).

## Development Workflow

All features follow this workflow:

```
/sdd.start [feature]  →  (/sdd.architect)  →  /sdd.tasks  →  /sdd.implement  →  /sdd.validate  →  /sdd.complete
```

## Key Principles

1. **Specs are source of truth** - Implement against specs, not imagination
2. **TDD is non-negotiable** - Tests before implementation, always
3. **Existing code first** - Search codebase before creating new components
4. **Scope control** - Out of Scope section is binding
5. **Human-in-the-loop** - User reviews spec and tasks before implementation

## Standards

Follow the standards in:
- `standards/global/code-quality.md` - Naming, organization, patterns
- `standards/global/testing.md` - TDD workflow, test conventions

## Specs Location

- Active specs: `specs/active/YYYY-MM-DD-feature-name/`
- Completed specs: `specs/implemented/`

## Before Writing Code

1. Check if a spec exists for this feature
2. If no spec, suggest using `/sdd.start`
3. Follow the task breakdown in `tasks.md`
4. Reference requirements (FR-X.X) from the spec

## Tech Stack

<!-- Updated by /sdd.init-project or /sdd.onboard -->
- Backend: [Not configured]
- Frontend: [Not configured]
- Database: [Not configured]
- Testing: [Not configured]
