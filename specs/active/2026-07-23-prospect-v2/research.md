# Research: SDD + TDD/BDD Best Practices & Claude Code Capabilities

**Date**: 2026-07-23
**Purpose**: Source material for the Prospect v2 redesign. Two research passes: (1) state of the art in spec-driven development with AI agents, (2) Claude Code Workflows feature, plus findings on the `/code-review` pipeline and the agent-teams feature.

---

## Part 1: State of the Art — SDD with AI Agents (2025–2026)

### Headline findings

1. **The field converged on the same pipeline** — Constitution/Standards → Specify → Plan/Design → Tasks → Implement → Validate — but frameworks diverge sharply on *ceremony*. The 2026 consensus is a three-level rigor taxonomy (spec-first / spec-anchored / spec-as-source); the most repeated lesson is "use the minimum rigor that removes ambiguity." Heavy frameworks are widely criticized as reinvented waterfall.
2. **Multi-agent is expensive and coding is the wrong domain for it.** Anthropic's data: agents ≈ 4× chat tokens, multi-agent ≈ 15×. Their guidance: multi-agent shines on parallelizable, breadth-first work and hurts in "domains that require all agents to share the same context or involve many dependencies" — i.e., exactly the TDD inner loop.
3. **The one TDD boundary worth isolating is RED↔GREEN** (a test author who never saw the implementation cannot write tests that pass by construction). Splitting GREEN and REFACTOR into separate agents is low-value: refactor needs the context green just built, and standalone refactor agents frequently have nothing to do. The lightweight camp enforces TDD via skills/hooks that verify a failing test before implementation is allowed, not via agent isolation.
4. **BDD is folded in, not bolted on.** Modern SDD writes acceptance criteria in EARS (or Given/When/Then) inside the spec and turns each criterion directly into a test — executable-spec benefits without a separate Cucumber layer. Scenario drift is a missing-context problem fixed with a short guidelines file wired into agent prompts.
5. **Best-practice spec lifecycle is delta-into-canonical, not dated archives.** Keep a living source of truth; each change merges on completion; archived change folders are audit trail only.

### Framework comparison

| Framework | Pipeline / artifacts | Agent model | Ceremony |
|---|---|---|---|
| GitHub Spec-Kit | Constitution → specify → plan → tasks → implement | No built-in subagents | Heavy — one trial: 2,577 lines of markdown for 689 lines of code, ~10× slower end-to-end, still shipped a trivial bug |
| Amazon Kiro | requirements.md (EARS) → design.md → tasks.md; wave-based parallel task execution | Agentic IDE | Heavy/structured; "too heavy for quick prototypes" |
| OpenSpec | `specs/` (source of truth) + `changes/` (proposal, design, tasks, delta specs); archive merges deltas | Agent-agnostic CLI | Light — delta-only representation |
| Agent OS v2 | Standards / Product / Specs layers | Optional subagent delegation | Medium |
| cc-sdd | Kiro-compatible flow as Claude Code skills | Minimal harness | Light |
| BMAD | Comprehensive multi-role SDLC | 21 specialized agents | Very heavy |
| Superpowers | Clarify→Design→Plan→Code→Verify with hard gates | Subagent per phase | Light install, heavy runtime |
| MUSUBI | 9-article constitution + EARS + traceability matrix | Heavy | Cited as the "too much" extreme |

### Token efficiency in multi-agent TDD

- Anthropic's 90.2%-over-single-agent result was on breadth-first *research*, not coding; "most coding tasks involve fewer truly parallelizable tasks than research."
- Pro-isolation argument (Superpowers): a fresh test-writer subagent "has never seen the implementation, [so] it cannot rationalize passing tests by construction" — the strongest case for separating RED from GREEN.
- Counter-consensus (QASkills, alexop.dev, aipatternbook): single agent with skill-based guardrails ("never write production code without a failing test; present failing test output before implementation").
- No source champions a dedicated refactor agent; refactor is a checklist/DRY step inside the implementation context.
- Community position: subagents are for read-heavy, bounded, independent work with summarized output (exploration, parallel review) — not the sequential, shared-context TDD inner loop. Route mechanical subagents to cheaper models.

### BDD integration

- EARS is the dominant acceptance-criteria notation in AI-SDD (Kiro, VS Code, Spec-Kit discussions). Five patterns; e.g. "WHEN a user submits a form with invalid data THE SYSTEM SHALL display validation errors." Forces explicit triggers/conditions/states.
- Modern pattern: criteria-in-spec become the failing tests of the RED phase directly.
- Without guidelines, AI-written Gherkin drifts: vague `Then` steps, UI-heavy scripts, multi-behavior scenarios, placeholder data. Fix: a short scenario-guidelines file injected into the relevant prompts.

### Spec lifecycle

- OpenSpec's delta-into-canonical model is the reference pattern: on completion, ADDED/MODIFIED/REMOVED deltas merge into canonical docs; the change folder moves to an archive as audit trail.
- Universal SDD weak spot: all tools "struggle with iterative changes like 'change button from blue to green'" — a lightweight fast path is essential.
- Named risks: over-specification, spec rot, false confidence ("a passing spec test only guarantees matching the spec").

### Key sources

- Anthropic: Building Effective Agents; How we built our multi-agent research system (anthropic.com/engineering)
- GitHub Spec-Kit announcement (github.blog); Scott Logic, "Putting Spec-Kit Through Its Paces" (blog.scottlogic.com, 2025-11-26)
- Kiro specs docs (kiro.dev/docs/specs); OpenSpec concepts (github.com/Fission-AI/OpenSpec)
- Superpowers TDD writeup (baeseokjae.github.io); QASkills TDD best practices (qaskills.sh); aipatternbook Red/Green pattern
- Automation Panda, "BDD/Gherkin Guidelines for AI" (2026-04-27); EARS: MakerNeo, Visure
- Academic: "SDD: From Code to Contract" (arxiv 2602.00180); SEET 2026 Gherkin/LLM paper (arxiv 2607.01980)

---

## Part 2: Claude Code Capabilities

### Workflows (deterministic multi-agent orchestration)

- Saved workflows live in `.claude/workflows/` (project) as JavaScript: `export const meta = { name, description, phases }` + script body using `agent()`, `pipeline()`, `parallel()`, `phase()`, `log()`; parameterizable via an `args` global.
- **Consent model**: the Workflow tool may be called when the user asks for a workflow, uses the ultracode keyword/setting, or **invokes a skill whose instructions tell Claude to call Workflow** — the skill file is user-owned authorization. This makes "skill → saved workflow" a compliant pattern for `/sdd-validate`.
- `agent()` supports: JSON-Schema-validated structured output, per-agent `model`/`effort` overrides, `label`, `agentType` (reuses `.claude/agents/*` definitions), `isolation: 'worktree'`.
- Concurrency ~16 local; intermediate results stay in script variables — only the final return lands in the calling context. Resumable (completed agent calls cached). No `Date.now()`/filesystem in scripts.
- Trade-off: each workflow agent is still a fresh context. Workflows make orchestration deterministic and keep intermediate output out of the main context; they do not make shared-context work cheaper. Right for validation fan-out; wrong for the TDD inner loop.

### /code-review pipeline (learnings adopted for sdd-validate)

- Architecture: **parallel specialist finders → verification step that checks each candidate against actual code behavior (the false-positive killer) → dedupe → severity ranking → report** with extended reasoning per finding.
- Severity: Important / Nit / Pre-existing. Findings carry file:line and a concrete failure scenario.
- `REVIEW.md` at repo root is injected verbatim into every reviewer as highest-priority instructions. Effective patterns: redefine severity for the repo, cap nit volume ("at most five, rest as a count"), skip rules (generated code, lockfiles, CI-enforced concerns), repo-specific always-checks, an evidence bar ("behavior claims need a file:line citation, not an inference from naming"), and a **re-review convergence rule** ("after the first review, suppress new nits; Important findings only").
- Source: code.claude.com/docs/en/code-review

### Agent teams (as of v2.1.178+)

- Experimental; gated behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. **`TeamCreate`/`TeamDelete` no longer exist** — a team forms when the first teammate is spawned; cleanup is automatic at session end. The `team_name` input on the Agent tool is ignored.
- Teammates are full sessions with own context; they message each other directly by name (`SendMessage`); idle notifications reach the lead automatically; a shared task list supports claiming and dependencies.
- Teammates can be spawned from `.claude/agents/*` subagent definitions (body appended to system prompt; `tools` allowlist and `model` honored).
- Named agents remain addressable after completing — a send resumes them from their transcript with context intact (basis for the test-author arbitration protocol).
- Docs' own use cases endorse the debate structure: adversarial teammates disproving each other's theories beat anchored solo judgment.
- Known limitations: no session resumption of in-process teammates, task status can lag, one team per session, no nested teams, lead is fixed.
- Source: code.claude.com/docs/en/agent-teams

### Living-docs-workflow (C:\_code2\living-docs-workflow) — adopted forward half

- `docs/INDEX.md`: machine-readable registry (structure, per-file purpose + Sources column, routing guide mapping topics → doc files).
- `docs-consolidator` agent: reads INDEX → reads source material → extracts permanent reference info (skips process artifacts) → merges into target docs without duplicating/overwriting → updates INDEX Sources.
- **Not adopted** (user decision, tried in practice): the reverse loop (analyze-doc-changes → Linear issues → tracking YAMLs). Doc edits triggering issues triggering doc updates destroyed fleshed-out future concepts and made the state of any docs sentence ambiguous (future concept vs. implemented reality). v2 rule: consolidation into `docs/` happens only at `/sdd-complete` from validated implementations, so `docs/` is as-built reality by construction.
