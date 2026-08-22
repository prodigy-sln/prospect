# Prospect — Spec-Driven Development Framework

*By [prodigy.solutions](https://prodigy.solutions)*

A lightweight spec-driven development (SDD) framework for Claude Code:
BDD scenarios as the test contract, TDD with an isolated test author,
deterministic quality gates, a work-type router with a script-resolved
pipeline, and living documentation that always describes the system as
built.

## Quick Start

| Situation | Command |
|-----------|---------|
| New project | `/sdd-init-project` |
| Existing project | `/sdd-onboard` |
| Start work | `/sdd-start [description or ISSUE-KEY]` |
| Continue | `/sdd-next` — or `/sdd-auto` to run unattended |

## Installation

```bash
# Bash (Linux/macOS/Git Bash)
curl -fsSL https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.sh | bash

# PowerShell (Windows)
irm https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.ps1 | iex
```

Pin a version by passing a tag (`… | bash -s -- v3.0.0`). Re-run the same
command to update: framework files (`.claude/`, `.prospect/`) update
silently when unmodified, files you modified are saved alongside as
`<filename>.prospect-incoming`, and your content (`specs/active/`,
`specs/archive/`, `specs/REGISTRY.md`, `docs/`, `product/mission.md`,
`product/roadmap.md`) is never touched. Treat `.prospect/` as
framework-owned: customize `standards/`, not the runtime.

When there are incoming files the installer offers to merge them with Claude
Code, and prints the command when it cannot ask. The brief it hands over names
the version range the update spans and points at the release notes for it, so
the merge follows what the framework changed and why. Installing into a
repository that already carries a file Prospect ships (its own `CLAUDE.md`,
say) offers the framework version as `.prospect-incoming` rather than
overwriting it.

## The Pipeline

`/sdd-start` classifies the work; after that a deterministic resolver
(`.prospect/scripts/sdd-next.sh`) reads the spec folder's frontmatter and
on-disk state, picks the next phase, and composes its prompt from fragment
files. The model never decides which rigor or work-type branch it is in —
a data file (`.prospect/prompts/matrix.tsv`) does. `/sdd-next` runs one
phase; `/sdd-auto` loops phases in fresh contexts under an explicit
autonomy policy (`.prospect/autonomy.md`) that decides which approvals may
be auto-recorded and which stop for you.

Every spec declares a **work-type** — ceremony follows the work, not one
ladder:

| `work-type:` | Path | Deliverable |
|---|---|---|
| **feature** | specify → [architect] → [discuss] → tasks → implement → validate → complete | behavior, TDD per scenario |
| **decision** | specify → discuss → decide → [checks] → validate → complete | ADRs, contracts, enforcement checks |
| **fix** | specify (root cause; structured RCA at `high+`) → implement → validate → complete | regression tests + narrowest fix |
| **docs** | edit → complete | documentation only |
| **chore** | work → complete | non-behavioral, gate-guarded |

**Rigor** scales verification: `low` gate-only · `medium` (default)
combined reviewer · `high` three specialist reviewers with per-finding
adversarial verification and sign-off · `xhigh` parallel stakeholder
personas · `max` negotiating persona team. The architect phase runs only
when a feature declares a non-empty `## Architecture Delta` against the
standing `docs/architecture.md`.

The pillars:

- **Scenarios are the contract.** EARS acceptance criteria
  (`WHEN … THE SYSTEM SHALL …`); each scenario is the floor of at least
  one test, mapped 1:N in `test-map.md` — test names stay behavioral, code
  carries no spec references. An independent auditor checks the spec for
  gaps *and* over-specification before you review it; past ~40 scenarios
  every addition needs your confirmation.
- **TDD with honest tests.** At `medium+` a test author that has never
  seen any implementation designs the interface and writes the failing
  tests; implementation happens inline and must conform, with disputes
  arbitrated by the author. Where mutation tooling exists, `high+` work
  spot-checks the diff — a surviving mutant names a missing test.
- **Deterministic everything.** `scripts/sdd-gate.*` (generated for your
  toolchain) proves formatter, linter, types, tests, coverage;
  `.prospect/scripts/sdd-artifact-lint.sh` caps artifact growth (task
  lists, test maps, registry entries); the resolver stamps per-phase
  timestamps into `metrics.md` so cost is measured, not guessed. Gate
  amendments are a project-level decision — never a spec deliverable.
- **UI is designed, not improvised.** Projects get a `ui-design.md`
  standard; UI features get look & feel questions and optional HTML mockup
  variants — the chosen direction is binding.
- **Living docs.** Completion consolidates each finished spec into `docs/`
  (routed by `docs/INDEX.md`), merges architecture deltas into the
  standing doc, registers one ≤50-word line in `specs/REGISTRY.md`, and
  disposes of the spec folder (delete or archive mode). `review-mode:
  solo` lets single-maintainer projects merge directly after a green
  validation.

## What's Included

```
.claude/
├── skills/            # sdd-start · sdd-next · sdd-auto · sdd-clarify ·
│                      # sdd-discuss · sdd-onboard · sdd-init-project ·
│                      # consolidate-docs
├── agents/            # test author, scenario auditor, reviewers,
│                      # architect, docs consolidator, discussion personas
└── workflows/
    └── sdd-validate.js  # reviewer fan-out with per-finding verification
.prospect/             # framework runtime (overwritten on update)
├── scripts/           # sdd-next.sh resolver · sdd-artifact-lint.sh
├── prompts/           # matrix.tsv + phase fragments per work-type
├── templates/         # spec, mini, decision, fix, tasks, docs-index
└── autonomy.md        # what /sdd-auto may decide without you
CLAUDE.md              # project instructions
standards/global/      # code quality, testing, git, scenarios, calibration
specs/                 # active/ · REGISTRY.md
product/               # mission & roadmap templates
```

## Requirements

- [Claude Code](https://claude.com/claude-code) — current version
- `rigor: max` discussions additionally need
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (they fall back to parallel
  persona reviews without it); high-tier validation prefers the Workflow
  tool and falls back to parallel subagents

## License

See [LICENSE](LICENSE).
