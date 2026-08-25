# Prospect — Spec-Driven Development Framework

This project uses **Prospect** for spec-driven development (SDD) with
test-driven development.

## Pipeline

`/sdd-start` classifies the work and creates the spec folder; from there a
deterministic resolver (`.prospect/scripts/sdd-next.sh`) reads the folder's
frontmatter and disk state, picks the next phase, and composes its prompt
from `.prospect/prompts/` fragments. `/sdd-next` runs one phase;
`/sdd-auto` loops phases unattended in fresh contexts under
`.prospect/autonomy.md`. The LLM never branches on work-type or rigor —
the matrix (`.prospect/prompts/matrix.tsv`) does.

Every spec carries `work-type:` and `rigor:` in its frontmatter.

| `work-type:` | Path (phases) | Deliverable |
|---|---|---|
| feature | specify → [architect] → [discuss] → tasks → implement → validate → complete | behavior, TDD per scenario |
| decision | specify → discuss → decide → [implement] → validate → complete | ADRs, contracts, enforcement checks |
| fix | specify (root cause; RCA at high+) → implement → validate → complete | regression tests + narrowest fix |
| docs | edit → complete | documentation only |
| chore | work → complete | non-behavioral change, gate-guarded |

Rigor scales verification, not ceremony: `low` gate-only · `medium`
(default) combined reviewer · `high` 3-reviewer workflow with verification
and sign-off · `xhigh` parallel personas · `max` negotiating personas.
Rigor also sets the spec's scenario budget: 15 · 40 · 70 · 110 · 160.
The architect phase runs only when the spec declares a non-empty
`## Architecture Delta`. Escalate rigor whenever new risk appears (record
the reason); downgrade only with explicit user confirmation.

## Key Principles

1. **Specs are the source of truth.** Acceptance scenarios (EARS) are the
   test contract: each scenario is the floor of at least one test; the 1:N
   mapping lives in the spec folder's `test-map.md`. Test names stay
   behavioral; code never carries spec or scenario IDs.
2. **TDD is non-negotiable.** Failing test output is displayed before any
   implementation. At `medium+`, tests are authored and owned by the test
   author — implementation never edits test files; disputes go to
   arbitration.
3. **Architecture is standing.** `docs/architecture.md` holds the module
   map, boundaries, and project constants; specs declare deltas only.
4. **Gates are deterministic.** `scripts/sdd-gate.*` must exit 0 at every
   phase end and before validation and completion. Gate amendments are a
   project-level decision with a runtime budget — never a spec deliverable.
5. **Artifacts have budgets.** `.prospect/scripts/sdd-artifact-lint.sh`
   enforces caps (tasks 60 lines, one map line per test, registry entries
   ≤50 words); overflow knowledge consolidates into `docs/`.
6. **Out of Scope is binding.** Unspecced work is recorded, not built.
7. **Phases resume from disk.** After any commit boundary `/clear` is safe;
   the resolver reconstructs state. `metrics.md` records per-phase
   timestamps for cost accountability.

## Commands

| Command | Purpose |
|---------|---------|
| `/sdd-init-project` | New project: Q&A → structure, standards, gate, docs index |
| `/sdd-onboard` | Existing project: detect toolchain → gate, docs index, standing architecture |
| `/sdd-start [desc]` | Classify work-type + rigor, branch, folder, hand off to resolver |
| `/sdd-next [folder]` | Resolve and run the next phase |
| `/sdd-auto [folder]` | Drive remaining phases unattended (autonomy policy) |
| `/sdd-clarify PROJ-123` | Fill the clarifications ledger via the issue tracker |
| `/sdd-discuss` | Persona challenge on demand (`--phase discuss`) |
| `/consolidate-docs [path]` | Merge any source material into docs/ |

## Locations

- Active specs: `specs/active/YYYY-MM-DD-name/` (spec, requirements ledger,
  test-map, metrics, decisions)
- Registry: `specs/REGISTRY.md` — one line ≤50 words per completed spec
- Framework runtime: `.prospect/` (resolver, prompts, templates, autonomy
  policy) — framework-owned, overwritten on update; do not edit in projects
- Living docs: `docs/` routed by `docs/INDEX.md` · Standing architecture:
  `docs/architecture.md`

## Prospect Settings

- `spec-disposal: delete` — default; `archive` (+ `retention: [days]`,
  default 180) for regulated projects or strict branch protection.
- `review-mode: team` — default; `solo` lets the complete phase merge
  directly after validation PASS (single-maintainer projects).

## Standards

@standards/global/code-quality.md
@standards/global/testing.md
@standards/global/git-workflow.md

Scenario rules (`standards/global/scenario-guidelines.md`) and review
calibration (`standards/global/validation-calibration.md`) are injected by
the phases that need them. The calibration file is tuned per project; its
content must read as direct reviewer instructions.

## Before Writing Code

1. A spec must exist — otherwise suggest `/sdd-start`.
2. Follow `tasks.md`; reference scenario IDs (FR-x.y-Sz) in tasks and
   commit messages on the feature branch — never in code or test names.
3. At `medium+`, never edit test files from the implementation context —
   send disputes to the test author.

## Tech Stack

- Backend / Frontend / Database / Testing: [Not configured — run
  `/sdd-onboard` or `/sdd-init-project`]
