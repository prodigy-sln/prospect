---
id: SPEC-003
title: Prospect v2 — Lightweight SDD with TDD/BDD
status: active
branch: feature/2026-07-23-prospect-v2
rigor: high
created: 2026-07-23
updated: 2026-07-23
author: Sebastian Grunow
---

# Specification: Prospect v2 — Lightweight SDD with TDD/BDD

## Goal

Rebuild Prospect so a feature costs ~5× fewer tokens while TDD discipline gets *more* enforceable, not less: fresh agent contexts only where independence adds value (test authorship, review), deterministic gates instead of agent ceremony, BDD scenarios as the test contract, a 5-level rigor ladder instead of uniform ceremony, and spec finalization that consolidates into living `docs/` instead of a stale archive.

## User Stories

- As a developer, I want small changes to flow through a minimal path (mini-spec → inline TDD → gate) so that fixing a button doesn't cost seven phases.
- As a developer, I want tests authored by an agent that has never seen the implementation so that tests define behavior instead of confirming code.
- As a developer, I want implemented specs merged into `docs/` so that documentation always describes the system as built.
- As a maintainer, I want every skill/agent file to be a lean final-state prompt with deterministic lint checks so that instructions stop drifting and being ignored.

## The Rigor Ladder (cross-cutting)

Each tier strictly adds to the previous one. Stored as `rigor:` in spec frontmatter.

| Tier | Spec | Tasks | Implement | Validate | Discuss default |
|------|------|-------|-----------|----------|-----------------|
| **low** | Mini-spec, single file, scenarios inline | — (scenarios are the list) | Inline TDD in main context | Gate script only | off |
| **medium** (default) | Full spec + scenarios | Scenario-level tasks.md | Engine B (test author per phase + inline GREEN/REFACTOR) | Gate + one combined reviewer, 1 pass | off |
| **high** | + architecture.md | same | same | Gate + 3-reviewer workflow with verification stage, 2-pass cap, user sign-off | off |
| **xhigh** | same | same | same | same | Parallel persona reviews (no debate) |
| **max** | same | same | same | same | Negotiating agent team (debate) |

## Functional Requirements

### FR-1: Rigor Tiers

- **FR-1.1**: `/sdd-start` recommends a tier and records the user-confirmed choice in spec frontmatter.
  - S1: WHEN a feature description mentions auth, payments, personal data, compliance, or destructive migrations, THE SYSTEM SHALL recommend at least `high`.
  - S2: WHEN the user requests a tier different from the recommendation, THE SYSTEM SHALL use the user's tier and record both.
- **FR-1.2**: Tiers may escalate mid-flight; they never silently downgrade.
  - S1: WHEN work at `low` reveals cross-cutting impact or new risk signals, THE SYSTEM SHALL propose escalation and record the change with a reason in the spec frontmatter.
  - S2: IF a downgrade is desired, THE SYSTEM SHALL require explicit user confirmation and record it.
- **FR-1.3**: Every downstream skill reads `rigor:` and branches per the ladder table; no tier-specific skill variants exist.

### FR-2: Spec Format — Scenarios as Test Contract

- **FR-2.1**: Every functional requirement in a spec carries acceptance scenarios in EARS (`WHEN … THE SYSTEM SHALL …`) or Given/When/Then form, with stable IDs `FR-x.y-Sz`.
- **FR-2.2**: Each scenario maps to exactly one test; the test name embeds the scenario ID.
  - S1: WHEN validation cross-references coverage, THE SYSTEM SHALL locate tests by scenario ID in test names, with no separate traceability matrix.
- **FR-2.3**: A scenario-guidelines standard (`standards/global/scenario-guidelines.md`, ≤350 words) defines: one behavior per scenario, observable outcomes only in `SHALL`/`Then` clauses, concrete example data, no UI-mechanics phrasing for non-UI requirements. It is referenced by the spec-writing and test-author prompts.
- **FR-2.4**: Two spec templates exist: full (`spec.template.md`) and mini (`spec-mini.template.md`, single file, ≤250 words of scaffold) for `low` tier.

### FR-3: Task Breakdown (medium+)

- **FR-3.1**: Tasks are scenario groups, not layer scaffolds. One task = one coherent set of scenarios in one area, with file hints.
- **FR-3.2**: `tasks.md` for a typical feature fits in ~20–40 lines; the template contains no per-layer phase skeleton, no per-task RED/GREEN sub-task splitting (the TDD cycle is the implement skill's job, not the task list's).
- **FR-3.3**: Phases group tasks only where a real dependency boundary exists (e.g. schema before API). `[P]` marks independent tasks.

### FR-4: Implement Phase — TDD Engine

- **FR-4.1 (low tier)**: The main context runs the full cycle per task: write failing test → run and display failing output → implement minimally → green → refactor own diff via checklist → commit sequence `test:` / `feat:` / `refactor:` (refactor commit only when changes were made).
  - S1: WHEN implementation code is about to be written and no failing test output for the task has been displayed in the session, THE SYSTEM SHALL stop and produce the failing test first.
- **FR-4.2 (medium+, Engine B — test author)**: At each phase start, exactly one named test-author subagent is spawned. It receives only: spec path, the phase's scenario IDs, testing-standards path, scenario-guidelines path.
  - S1: WHEN the test author completes, THE SYSTEM SHALL receive a structured contract: interface decisions (signatures, types, error contracts), test-file paths, test-name↔scenario-ID map, failing count, test command.
  - S2: WHEN the test author's tests do not fail on first run, THE TEST AUTHOR SHALL investigate (already-satisfied requirement vs. defective test) and flag rather than proceed.
- **FR-4.3 (test author identity)**: The test-author prompt frames the agent as the feature's first consumer and interface designer — "decide how this feature is used and how it fails, expressed as tests" — not as a test generator. Its interface contract is binding on the implementer; where `architecture.md` exists, the author consumes its interfaces and flags conflicts instead of diverging.
- **FR-4.4 (ownership + arbitration)**: During a phase, test files belong to the test author.
  - S1: WHEN a test fails and the implementer suspects the test is wrong, THE SYSTEM SHALL NOT edit the test file from the main context; it SHALL resume the phase's test author (named-agent message) with facts only: test name, assertion diff, scenario ID, minimal implementation excerpt.
  - S2: WHEN arbitrating, THE TEST AUTHOR SHALL judge against the spec scenario (not the implementation) and return exactly one verdict: `test-correct` (implementation must conform, with a hint), `test-wrong` (author edits and commits the fix with reasoning), or `scenario-ambiguous` (escalate to user).
  - S3: WHEN arbitrating, THE TEST AUTHOR SHALL NOT re-explore the repository; it judges from its context plus the provided facts.
- **FR-4.5 (inline GREEN/REFACTOR)**: Implementation and refactoring happen in the main context. Refactor = a ≤8-item checklist applied to the task's own diff (naming, duplication, dead code, error messages, nesting, standards fit); findings in *other* files are recorded as deferred observations, never fixed.
- **FR-4.6**: There is no refactorer agent, no implementer agent, and no verifier agent. Phase-end verification is the gate script (FR-5).
- **FR-4.7 (scope guard)**: Before any implementation edit: the change maps to a task and scenario, and is absent from Out of Scope. Otherwise: record, don't build.

### FR-5: Deterministic Quality Gate

- **FR-5.1**: `/sdd-onboard` and `/sdd-init-project` generate `scripts/sdd-gate.ps1` and/or `scripts/sdd-gate.sh` from the detected toolchain: formatter check, linter, type check, full test suite, coverage threshold. Exit code non-zero on any failure; output is a compact failure list (no prose).
- **FR-5.2**: The gate runs at every phase end (implement) and as a hard precondition of `/sdd-validate` and `/sdd-complete`.
  - S1: WHEN the gate fails at a phase end, THE SYSTEM SHALL fix the reported issues and re-run before starting the next phase.
- **FR-5.3**: No LLM re-derives gate results; skills consume the script's output verbatim.

### FR-6: Validation

- **FR-6.1 (tier split)**: `low` = gate only. `medium` = gate + one combined reviewer subagent (correctness + coverage + quality in a single prompt), 1 pass. `high+` = gate + saved workflow `.claude/workflows/sdd-validate.js` fanning out the three specialist reviewers, with verification stage, deterministic merge, 2-pass cap in code.
- **FR-6.2 (evidence bar)**: Every finding requires a `file:line` citation and a concrete failure scenario (inputs/state → wrong observable outcome).
  - S1: WHEN a reviewer produces a finding without citation or failure scenario, THE SYSTEM SHALL discard it before reporting.
- **FR-6.3 (verification stage, high+)**: Each candidate finding is checked against actual code behavior before entering the report; verdicts `confirmed`/`plausible` are recorded, and only confirmed findings can block.
- **FR-6.4 (convergence rule)**: Pass 2 may only introduce new findings of severity Major or higher.
- **FR-6.5 (calibration block)**: `standards/global/validation-calibration.md` (project-customizable) is injected verbatim into every reviewer prompt: repo-specific severity definitions, Minor cap ("at most 5; remainder as a count"), skip rules (generated code, lockfiles, CI-enforced concerns).
- **FR-6.6 (structured verdicts)**: Reviewers return structured findings (requirement, verdict, findings[{severity, file, line, summary, failure_scenario}]); the merge and PASS/FAIL decision are computed, not narrated. Only the merged verdict enters the main context.
- **FR-6.7 (fallback)**: WHEN the Workflow tool is unavailable, `high+` validation SHALL run the three reviewers as plain parallel subagents with the same prompts, evidence bar, and merge rules.

### FR-7: Discussion Phase

- **FR-7.1 (personas as agents)**: Stakeholder personas are subagent definitions. Stock personas shipped: `persona-architect` (technical advocate — defends feasibility/cost; explicitly NOT the architecture designer), `persona-product-owner` (value, prioritization, deferral), `persona-compliance` (data protection, security posture). Projects add their own.
- **FR-7.2 (xhigh — parallel review)**: Personas run as parallel one-shot subagents on a shared ≤500-word brief; each returns structured output: concerns with severity, answers to open questions, one "what's missing".
  - S1: WHEN synthesis completes, THE SYSTEM SHALL surface every inter-persona tension to the user unresolved — no silent dropping, no unilateral resolution.
- **FR-7.3 (max — negotiating team)**: Personas run as an agent team. Coordination is peer-driven: each persona's spawn prompt names the other personas and requires (a) initial review to lead and peers, (b) at least one direct reply to a peer's strongest disagreement, (c) a final position stating what moved.
  - S1: WHEN synthesizing, THE LEAD SHALL NOT produce the synthesis until every persona has sent an initial review and at least one peer reply; missing personas are messaged individually.
  - S2: The synthesis SHALL include a discussion log (who challenged whom, what changed) and label outcomes: agreed / deferred (by whom) / deadlocked (user decides).
- **FR-7.4 (degradation)**: WHEN `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is not enabled and tier is `max`, THE SYSTEM SHALL run the xhigh form and state that it did so.
- **FR-7.5**: `/sdd-discuss` is invocable manually at any tier; `sdd-start` auto-suggests it when FR-1.1-S1 risk signals appear. Findings append to `requirements.md` under `## Discussion Findings` for the specify step.

### FR-8: Completion — Consolidation into docs/

- **FR-8.1**: `docs/` contains as-built reality only. Future concepts live in active specs and `product/roadmap.md`.
- **FR-8.2**: `/sdd-complete` (after gate + validation PASS): updates spec status, invokes the docs-consolidator on the spec folder, then moves the folder to `specs/archive/YYYY-MM-DD-name/` (audit trail), then commits, then creates the PR — so docs changes ship and get reviewed with the code.
- **FR-8.3 (vendored consolidator)**: The `docs-consolidator` agent and `/consolidate-docs` skill are vendored from living-docs-workflow, tracker-agnostic (no Linear/tracking-file machinery). Behavior: read `docs/INDEX.md` → read spec folder → extract permanent reference material (requirements→behavior docs, architecture decisions→ADRs, user-facing changes→user docs), skip process artifacts (tasks, validation reports) → merge without duplicating or overwriting other sources → update INDEX Sources column.
- **FR-8.4**: `/sdd-onboard` and `/sdd-init-project` generate `docs/INDEX.md` (structure, file registry with Sources, routing guide) when absent.
- **FR-8.5**: WHEN `docs/INDEX.md` is absent at completion time, THE SYSTEM SHALL offer to generate it; if declined, it SHALL append a completion summary to `docs/CHANGELOG-features.md` as minimal fallback.

### FR-9: Context Boundaries

- **FR-9.1**: `sdd-start` (after spec approval) and `sdd-tasks` end their output with an explicit boundary note: everything downstream needs is on disk; `/clear` is recommended before the next phase.
- **FR-9.2**: Shape-phase codebase discovery is delegated to a read-only exploration subagent returning a compact findings report; raw file dumps stay out of the main context.
- **FR-9.3**: WHEN `docs/INDEX.md` exists, discovery SHALL consult `docs/` before exploring code.

### FR-10: Prompt Standards & Framework Lint

- **FR-10.1**: Every skill/agent/template file is a final-state prompt: imperative, present-tense; zero references to process history, prior versions, removed tools, or change rationale; constraints stated once at the point of action; known failure modes enforced via verifiable artifacts (e.g. "display the failing test output before implementing") rather than exhortation.
- **FR-10.2 (word budgets)**: skills ≤700 words; agents ≤550; templates ≤450 (mini-spec ≤250); guidelines ≤350. Total prompt surface (`.claude/` + templates + new standards files) ≤9,000 words (v1: ~18,600).
- **FR-10.3 (lint script)**: `tests/framework/lint.sh` checks deterministically: word budgets per file class; forbidden tokens (`TeamCreate`, `TeamDelete`, removed skill/agent names, history phrases: "previously", "no longer", "changed from", "instead of the old"); required sections per file class (agents: context received / process / output contract); all file paths referenced by prompts exist. Runs in the release workflow.
  - S1: WHEN lint fails, THE RELEASE WORKFLOW SHALL fail.

### FR-11: Removals & Installer

- **FR-11.1**: Removed from the repo: `.github/agents/`, `.github/prompts/`, `.github/instructions/`, `.github/copilot-instructions.md` (Copilot toolchain); skills `sdd-start-issue`, `sdd-initiate`, `sdd-shape`, `sdd-specify`; agents `sdd-implementer`, `sdd-refactorer`, `sdd-verifier` (agent — the gate script replaces it). `.github/workflows/release.yml` stays.
- **FR-11.2**: `install.sh` / `install.ps1`: remove toolchain selection (Claude-only), keep version pinning, checksum manifest, and `.prospect-incoming` conflict handling; add new files (workflows, gate templates, docs index template) to the manifest. Existing installer/e2e tests updated **first** (test-first applies — this is tested shell code).
- **FR-11.3**: `README.md` and `CLAUDE.md` rewritten for the v2 pipeline; version bumps to v2.0.0.

## Technical Considerations

### Target file tree (framework-owned)

```
.claude/
├── agents/
│   ├── sdd-architect.md            # designer (high+), rewritten
│   ├── sdd-test-author.md          # Engine B, interface-designer framing
│   ├── sdd-reviewer.md             # combined reviewer (medium)
│   ├── sdd-review-correctness.md   # specialists (high+), rewritten w/ evidence bar
│   ├── sdd-review-coverage.md
│   ├── sdd-review-quality.md
│   ├── docs-consolidator.md        # vendored, tracker-agnostic
│   ├── persona-architect.md
│   ├── persona-product-owner.md
│   └── persona-compliance.md
├── skills/
│   ├── sdd-init-project/  sdd-onboard/  sdd-start/  sdd-clarify/
│   ├── sdd-discuss/  sdd-architect/  sdd-tasks/  sdd-implement/
│   ├── sdd-validate/  sdd-complete/  consolidate-docs/
└── workflows/
    └── sdd-validate.js
specs/
├── _templates/ (spec, spec-mini, tasks, docs-index)
├── active/   └── archive/          # archive replaces implemented/
standards/global/ (code-quality, testing, git-workflow, scenario-guidelines, validation-calibration)
scripts/  (sdd-gate templates; per-project gate generated by onboard/init)
tests/framework/lint.sh
```

### Engine B mechanics

Test author spawned as a **named** agent (`test-author-phase-N`); names remain addressable after completion — arbitration resumes the transcript at incremental cost. Arbitration is fact-based (implementer reports, never argues); default presumption: the test is correct until the scenario says otherwise.

### Validation workflow sketch

`sdd-validate.js`: `phase('Review')` → `parallel` 3 reviewers via `agentType` with structured-output schemas (cheaper model) → `phase('Verify')` → per-finding verification agents → computed merge (evidence bar, severity rules, pass cap) → return merged verdict only.

### Model routing

Judgment (spec writing, architecture, arbitration, synthesis): session model. Mechanical (reviewers, verification checks, consolidation): Sonnet-class via agent `model:` fields.

## Out of Scope

- :x: VS Code Copilot port of v2 (toolchain removed, no follow-up planned)
- :x: Reverse doc loop (doc-edit analysis → issue creation) — rejected after real-world trial
- :x: Hook-based TDD enforcement (tdd-guard-style edit blocking) — candidate for v2.1
- :x: `TeammateIdle` hook hardening of the max-tier discussion
- :x: CI-triggered docs consolidation workflow (local consolidation at complete is the v2 path)
- :x: Changes to Jira/issue-tracker integration beyond keeping current graceful-fallback behavior
- :x: Migration tooling for v1 installs beyond the existing checksum/`.prospect-incoming` mechanism

## Verification Approach (this spec)

The deliverable is prompts + shell code. Verification:
1. **Deterministic**: `tests/framework/lint.sh` (FR-10.3) green; installer test suites (bash/pwsh/e2e) green; word budgets met.
2. **Structural review**: every FR checked against the produced files (standard validation flow, `rigor: high`).
3. **Dogfood**: the first real feature after merge runs the full v2 pipeline end-to-end; friction found feeds v2.1.

## Dependencies

- Claude Code with named-agent resume (arbitration), Workflow tool (high+ validation; FR-6.7 fallback exists), agent teams behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (max tier; FR-7.4 fallback exists).

## Assumptions

- Framework targets primarily new projects; existing projects adopt `docs/INDEX.md` via `/sdd-onboard`.
- Projects using v1 accept a breaking v2.0.0 (spec folder layout, skill surface, removed toolchain).

## Open Questions

None — design decisions recorded in `requirements.md` (D1–D16).
