# Prospect — Spec-Driven Development Framework

*By [prodigy.solutions](https://prodigy.solutions)*

A lightweight spec-driven development (SDD) framework for Claude Code:
BDD scenarios as the test contract, TDD with an isolated test author,
deterministic quality gates, tiered rigor, and living documentation that
always describes the system as built.

## Quick Start

| Situation | Command |
|-----------|---------|
| New project | `/sdd-init-project` |
| Existing project | `/sdd-onboard` |
| Build a feature | `/sdd-start [description or ISSUE-KEY]` |

## Installation

```bash
# Bash (Linux/macOS/Git Bash)
curl -fsSL https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.sh | bash

# PowerShell (Windows)
irm https://raw.githubusercontent.com/prodigy-sln/prospect/main/install.ps1 | iex
```

Pin a version by passing a tag (`… | bash -s -- v2.0.0`). Re-run the same
command to update: unmodified framework files update silently, files you
modified are saved alongside as `<filename>.prospect-incoming` for manual
merge, and your content (`specs/active/`, `specs/archive/`, `docs/`,
`product/mission.md`, `product/roadmap.md`) is never touched.

<details>
<summary>Manual installation</summary>

```bash
cp -r prospect/.claude   /path/to/your/project/
cp -r prospect/CLAUDE.md /path/to/your/project/
cp -r prospect/standards /path/to/your/project/
cp -r prospect/specs     /path/to/your/project/
cp -r prospect/product   /path/to/your/project/   # optional
```

</details>

## The Workflow

```
/sdd-start ──► (/sdd-discuss) ──► (/sdd-architect) ──► /sdd-tasks
                                                          │
/sdd-complete ◄── /sdd-validate ◄── /sdd-implement ◄──────┘
```

Every spec carries a **rigor tier** — pay only for the ceremony the change
warrants:

| `rigor:` | Adds |
|----------|------|
| **low** | Mini-spec with inline scenarios, inline TDD, quality gate only |
| **medium** (default) | Full spec, scenario audit, isolated test author, combined review |
| **high** | Architecture plan, specialist reviewer workflow with verification, sign-off |
| **xhigh** | Parallel stakeholder-persona reviews of the plan |
| **max** | Personas negotiate as an agent team (debate, common ground, deferrals) |

The pillars:

- **Scenarios are the contract.** Acceptance criteria are written in EARS
  form (`WHEN … THE SYSTEM SHALL …`); each scenario becomes exactly one
  test carrying the scenario ID. An independent auditor checks the spec
  for gaps before you review it.
- **TDD with honest tests.** At `medium+` a test author that has never seen
  any implementation designs the interface and writes the failing tests;
  implementation happens inline and must conform. Disputed failures go
  back to the test author for arbitration — implementation never edits
  tests.
- **Deterministic gates.** `scripts/sdd-gate.*` (generated for your
  toolchain) runs formatter, linter, type check, tests, and coverage. No
  agent re-derives what a script can prove.
- **UI is designed, not improvised.** Projects get a `ui-design.md`
  standard; UI features get look & feel questions and optional HTML mockup
  variants — the chosen direction is binding.
- **Living docs.** `/sdd-complete` consolidates each finished spec into
  `docs/` (routed by `docs/INDEX.md`), then archives the spec folder.
  `docs/` always reads as-built; future concepts live in specs and the
  roadmap.

## What's Included

```
.claude/
├── skills/            # /sdd-* commands + /consolidate-docs
├── agents/            # test author, scenario auditor, reviewers,
│                      # architect, docs consolidator, discussion personas
└── workflows/
    └── sdd-validate.js  # reviewer fan-out with per-finding verification
CLAUDE.md              # project instructions
standards/global/      # code quality, testing, git, scenarios, calibration
specs/                 # active/ · archive/ · _templates/
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
