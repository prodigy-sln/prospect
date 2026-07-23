# Requirements: Prospect v2

**Created**: 2026-07-23
**Source**: Framework review + research session (see `research.md`) + design discussion with Sebastian Grunow

## Problem Statement

1. **Token intensity.** The v1 implement phase spawns 3 subagents per task (test-writer, implementer, refactorer) plus a verifier per phase — ~58 fresh-context spawns for a 15-task feature, each re-reading spec/standards and re-exploring the codebase. Estimated 2–3.5M tokens per feature.
2. **Refactorer no-ops.** The refactorer agent, lacking the implementer's context and reviewing small task-scoped diffs already written to standards, routinely reports "no changes" — paying ~50k tokens for a ritual PASS table.
3. **Lost narrative.** No agent holds the feature end-to-end; codebase knowledge learned by one agent dies with its context and is relearned by the next ("the whole idea is not grasped").
4. **Spec afterlife.** `specs/implemented/` is a stale, dated archive. Desired: consolidation of implemented specs into living documentation in `docs/`.
5. **Prompt drift.** Skill/agent files accumulated process history, change rationale, and restated philosophy; agents ignore the buried load-bearing instructions.

## Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | **TDD engine "B"**: one isolated test-author subagent per phase; implementation + refactoring inline in the main context | RED↔GREEN is the only boundary where research shows agent isolation pays (prevents tests that pass by construction); batching per phase amortizes the spawn cost |
| D2 | **Test author = interface designer**: framed as the first consumer of the feature; its summary is a binding interface contract | TDD is a design activity; interface design must happen without implementation bias |
| D3 | **Resume-arbitration**: implementer never edits tests; disputed test failures go back to the *resumed* test author (named agent, context intact) for a verdict | Extends the isolation boundary through the whole phase at incremental cost; the author retains the "why" of each test |
| D4 | **No refactorer / verifier agents**: refactoring is an inline checklist step; verification is a deterministic gate script | Refactor needs the implementer's context; gates (format/lint/typecheck/tests/coverage) need no LLM |
| D5 | **BDD scenarios in the spec** (EARS or Given/When/Then), each becoming exactly one test with the scenario ID in the test name | Executable-spec payoff without a Cucumber layer; traceability falls out of naming |
| D6 | **5 rigor tiers**: low / medium / high / xhigh / max, mirroring Claude Code effort levels; stored in spec frontmatter; escalate freely, never silently downgrade | Most-cited SDD failure is uniform ceremony; single monotone dimension, each tier strictly adds |
| D7 | **Validation tier-split** with `/code-review` learnings: evidence bar (file:line + concrete failure scenario or discarded), verification stage before reporting, pass-2 convergence rule (Major+ only), calibration block injected verbatim into every reviewer | Kills false positives and noisy-Minor churn; the current 2-pass/anchoring machinery papers over the convergence problem |
| D8 | **Saved Workflow for high+ validation** (`.claude/workflows/`), invoked by the skill (sanctioned consent); plain-subagent fallback when Workflow is unavailable | Deterministic merge logic and pass caps in code, not prose; structured verdicts keep reviewer output out of the main context |
| D9 | **Discussion phase kept, two intensities**: xhigh = parallel independent persona reviews with ALL tensions surfaced to the user; max = negotiating agent team (self-propelled debate protocol). max degrades to xhigh without `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | User experience confirms the negotiation itself produces scoping decisions (e.g. DPO vs architect vs PO deferrals); past failure was the lead skipping coordination — fixed by peer-driven protocol, not moderator choreography |
| D10 | **Discuss-architect is an advocate, not a designer**; `/sdd-architect` (designer) runs after discussion | Roles don't overlap; sequence: discuss → specify → architect |
| D11 | **Finalization = consolidation into `docs/`** via vendored docs-consolidator + `docs/INDEX.md` (from living-docs-workflow, forward half only, tracker-agnostic); spec folder archived afterward | `docs/` contains as-built reality only; future concepts live in active specs and product/roadmap — resolves the "is this sentence implemented or planned?" ambiguity |
| D12 | **No reverse doc loop** (analyze-doc-changes → issues) | Tried in practice: doc edits triggering issues triggering doc updates destroyed fleshed-out future concepts and blurred ground truth |
| D13 | **Context boundaries**: skills end with explicit "safe to /clear" notes after spec approval and before implement; shape's codebase discovery via a compact-report subagent; discovery reads `docs/INDEX.md` first | The spec IS the compacted context; fresh implement contexts can't be contaminated by discussed-but-rejected ideas |
| D14 | **All prompt files rewritten as final-state prompts** and linted deterministically (word budgets, forbidden references, required sections) | Fresh files must not reference process history or change rationale; enforcement via script, not convention |
| D15 | **Drop VS Code Copilot toolchain** entirely | User decision; halves the maintenance surface |
| D16 | **Skills dropped**: sdd-start-issue, granular trio (sdd-initiate / sdd-shape / sdd-specify as standalone). **Kept**: sdd-clarify | User decision; sdd-start covers the combined flow |
| D17 | **Scenario audit step**: an independent auditor subagent (medium+; inline rubric at low) checks spec scenarios for completeness — unwanted-behavior coverage, EARS pattern sweep, operation symmetry, prose-constraint leaks, story coverage, observable outcomes, contradictions — and presents a gap list with suggested scenario drafts alongside the user's spec review | Scenarios are the contract every later stage inherits; a gap is invisible downstream (validation passes against an incomplete spec); the writing context cannot audit itself |
| D18 | **UI design integrated**: per-project `ui-design.md` standard (generated by onboard/init), shape asks look & feel questions when UI surface is detected (UI states become scenarios), optional design exploration produces 1–3 HTML mockup variants with the chosen direction recorded in the spec's Visual Design section and binding on implementation. Conditional on UI surface, not tier | Pipelines ask "where to integrate" but never "how should this look"; the model designs well only when explicitly prompted with durable direction; the visual direction must be chosen before implementation, not improvised during it |

## Constraints

- Framework remains a copy-in/install-in template for (primarily new) projects; no runtime dependencies beyond Claude Code.
- Installer update mechanics (checksums, `.prospect-incoming` conflict files) must keep working; v2 is a breaking release (v2.0.0).
- Installer changes are shell code with existing test suites → test-first applies there.
- `max` tier depends on the experimental agent-teams feature; `high+` validation prefers the Workflow tool — both need documented fallbacks.
