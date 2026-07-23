# Prospect — Spec-Driven Development Framework

This project uses **Prospect** for spec-driven development (SDD) with
test-driven development.

## Workflow

```
/sdd-start [feature]  →  (/sdd-discuss)  →  (/sdd-architect)  →  /sdd-tasks
    →  /sdd-implement  →  /sdd-validate  →  /sdd-complete
```

Every spec carries a rigor tier in its frontmatter. Each tier strictly adds
to the previous one; escalate whenever new risk appears (record the reason),
downgrade only with explicit user confirmation.

| `rigor:` | Spec | Tasks | Implement | Validate | Discuss |
|----------|------|-------|-----------|----------|---------|
| low | mini-spec | — | inline TDD | gate script | — |
| medium (default) | full + scenarios | scenario groups | test author + inline | gate + combined reviewer | — |
| high | + architecture | same | same | gate + reviewer workflow, sign-off | — |
| xhigh | same | same | same | same | parallel persona reviews |
| max | same | same | same | same | negotiating agent team |

## Key Principles

1. **Specs are the source of truth.** Acceptance scenarios (EARS) are the
   test contract: each scenario becomes exactly one test named with its ID.
2. **TDD is non-negotiable.** Failing test output is displayed before any
   implementation. At `medium+`, tests are authored and owned by the test
   author — implementation never edits test files; disputes go to
   arbitration.
3. **`docs/` is as-built reality.** Completed specs consolidate into
   `docs/` via `docs/INDEX.md` routing. Future concepts live in
   `specs/active/` and `product/roadmap.md`, never in `docs/`.
4. **Gates are deterministic.** `scripts/sdd-gate.*` must exit 0 at every
   phase end, before validation, and before completion.
5. **Out of Scope is binding.** Unspecced work is recorded, not built.
6. **Phases resume from disk.** After spec or tasks approval, `/clear` is
   safe and recommended — no phase depends on conversation history.

## Commands

| Command | Purpose |
|---------|---------|
| `/sdd-init-project` | New project: Q&A → structure, standards, gate, docs index |
| `/sdd-onboard` | Existing project: detect toolchain → gate, docs index, UI standard |
| `/sdd-clarify PROJ-123` | Resolve requirement ambiguities via issue tracker |
| `/sdd-start [desc]` | Rigor, branch, shaping, spec, scenario audit, design exploration |
| `/sdd-discuss` | Persona challenge of the plan (xhigh/max default; on demand anywhere) |
| `/sdd-architect` | Binding architecture plan (high+ default) |
| `/sdd-tasks` | Scenario-grouped task breakdown |
| `/sdd-implement` | TDD implementation per the tier's engine |
| `/sdd-validate` | Gate + tier-scaled review |
| `/sdd-complete` | Consolidate into docs/, archive spec, open PR |
| `/consolidate-docs [path]` | Merge any source material into docs/ |

## Locations

- Active specs: `specs/active/YYYY-MM-DD-name/` · Archive: `specs/archive/`
- Templates: `specs/_templates/` · Living docs: `docs/` (routed by `INDEX.md`)
- Quality gate: `scripts/sdd-gate.*`

## Standards

@standards/global/code-quality.md
@standards/global/testing.md
@standards/global/git-workflow.md

Scenario rules (`standards/global/scenario-guidelines.md`) and review
calibration (`standards/global/validation-calibration.md`) are injected by
the skills that need them.

## Before Writing Code

1. A spec must exist — otherwise suggest `/sdd-start`.
2. Follow `tasks.md`; reference scenario IDs (FR-x.y-Sz) in tests and
   commits.
3. At `medium+`, never edit test files from the implementation context —
   send disputes to the test author.

## Tech Stack

- Backend / Frontend / Database / Testing: [Not configured — run
  `/sdd-onboard` or `/sdd-init-project`]
