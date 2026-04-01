---
id: SPEC-001
title: Bridge CSE Review — Specialized Reviewers, Quality Gates, and Clarify Skill
status: implemented
branch: feature/2026-04-01-bridge-cse-review
created: 2026-04-01
updated: 2026-04-01
completed: 2026-04-01
---

# Specification: Bridge CSE Review — Specialized Reviewers, Quality Gates, and Clarify Skill

## Goal

Port the evolved SDD review/validation pipeline from Guildmaster into the Prospect framework: split the monolithic code review into 3 focused reviewers running in parallel, add deterministic quality gates to the verifier, expand the refactorer's quality checklist, and add a generic requirements clarification skill. Ensure consistency across the entire framework.

## User Stories

- As a framework user, I want validation to run 3 specialized reviewers in parallel so that correctness, coverage, and quality findings don't bleed into each other
- As a framework user, I want the verifier to run formatter/linter/type-checker gates before tests so that deterministic failures are caught fast
- As a framework user, I want the refactorer to act as a first quality gate during implementation so that issues are caught early, not just at validation
- As a framework user, I want a generic `/sdd-clarify` skill so that I can gather requirements from stakeholders via any issue tracker before spec writing
- As a framework maintainer, I want all agents, skills, README, and CLAUDE.md to reference the new review structure consistently

## Functional Requirements

### FR-1: Specialized Review Agents

- **FR-1.1**: Create `sdd-review-correctness` agent that verifies implementation behavior matches spec requirements exactly
  - Acceptance: Agent produces per-requirement verdicts (PASS/PARTIAL/FAIL) with file:line evidence
- **FR-1.2**: Create `sdd-review-coverage` agent that verifies all spec requirements have adequate test coverage
  - Acceptance: Agent produces requirement-to-test map with coverage gaps per acceptance criterion
- **FR-1.3**: Create `sdd-review-quality` agent that checks code patterns, consistency, error handling, security, and scope compliance
  - Acceptance: Agent detects out-of-scope file changes via git diff and applies two-developer test to Minor severity
- **FR-1.4**: Remove the old monolithic `sdd-review` agent
  - Acceptance: File `.claude/agents/sdd-review.md` is deleted; no remaining references to it anywhere in the framework

### FR-2: Enhanced Verifier

- **FR-2.1**: Add deterministic quality gates (formatter, linter, type checker) that run BEFORE test execution
  - Acceptance: Verifier auto-detects project tooling, runs checks, and fails fast if any gate fails
- **FR-2.2**: Update output format to include Quality Gates table
  - Acceptance: Output includes gate-by-gate PASS/FAIL/N/A with details

### FR-3: Enhanced Refactorer

- **FR-3.1**: Expand quality review checklist to cover correctness, architecture, error handling, security, and scope control
  - Acceptance: Checklist mirrors validation-phase criteria so issues are caught at implementation time
- **FR-3.2**: Add Quality Review Results table and Deferred Observations section to output format
  - Acceptance: Output includes per-category PASS/issue status and a section for out-of-scope observations

### FR-4: Rewritten Validate Skill

- **FR-4.1**: Build file manifest from tasks.md + git diff for all reviewers to share
  - Acceptance: Manifest is the union of task-mentioned files and feature-related git changes
- **FR-4.2**: Launch verifier + 3 reviewers in parallel (not sequentially)
  - Acceptance: All 4 agents delegated simultaneously via Task tool
- **FR-4.3**: Support 2-pass validation with escalation
  - Acceptance: Pass 1 artifacts archived before Pass 2; hard cap at 2 passes; escalation to user if issues remain
- **FR-4.4**: Define explicit completion criteria: PASS = zero Blockers, Majors, Minors across all reviewers
  - Acceptance: Validation report clearly states criteria and aggregates findings

### FR-5: Generic Clarify Skill

- **FR-5.1**: Create `/sdd-clarify` skill that gathers requirements from stakeholders via issue tracker comments
  - Acceptance: Skill detects available MCP tools (Atlassian, Linear, Notion) and uses whichever is available
- **FR-5.2**: Support multiple clarification rounds (initial + follow-ups)
  - Acceptance: Skill detects prior clarification comments and builds on stakeholder replies
- **FR-5.3**: Include codebase discovery before question formulation
  - Acceptance: Delegates to Explore subagent and uses findings to ask informed questions
- **FR-5.4**: Use non-technical language in all stakeholder-facing output
  - Acceptance: No SDD jargon, no slash commands, no phase names in posted comments
- **FR-5.5**: Add install-agent hints in skill metadata for issue tracker dependencies
  - Acceptance: Skill description or comments note which MCP integrations it can use

### FR-6: Framework Consistency

- **FR-6.1**: Update `sdd-implement/SKILL.md` to remove orphaned `sdd-review` reference in verifier delegation
  - Acceptance: Phase-end verification delegates to `sdd-verifier` only (review is for validate phase)
- **FR-6.2**: Update `README.md` file tree, feature descriptions, and commands table
  - Acceptance: README reflects new agents, removed agent, new skill, updated review description
- **FR-6.3**: Update `CLAUDE.md` workflow reference if it references the old review structure
  - Acceptance: No stale references to single `sdd-review` agent

## Technical Considerations

### Architecture Decisions

- 3 specialized reviewers replace 1 monolithic reviewer — better parallelism, focused findings, no cross-contamination
- File manifest is built by the validate orchestrator and passed to all reviewers — single source of truth
- sdd-clarify is MCP-agnostic: detects Atlassian/Linear/Notion MCP at runtime, falls back to user interaction
- Quality gates in verifier are auto-detected from project config files (package.json, .eslintrc, tsconfig, etc.)

### Source Material

All new/modified files are ported from `C:\code\prodigy.solutions\Guildmaster\.claude\` with these generalizations:
- Remove game-specific language and Guildmaster-specific references
- Replace `linear-cli` with MCP tool detection pattern
- Keep FR references generic (no project-specific issue key prefixes)

## Test Strategy

This is a framework change (prompt files, not executable code). Verification is:
- Manual review of all files for consistency
- Grep for stale references to `sdd-review` (should find zero)
- Confirm file tree matches README documentation

### Test Coverage Target

- N/A (no executable code)

## Existing Code to Leverage

| Feature | Location | What to Reuse |
|---------|----------|---------------|
| Guildmaster review agents | `Guildmaster/.claude/agents/sdd-review-*.md` | Port directly, remove game-specific language |
| Guildmaster refactorer | `Guildmaster/.claude/agents/sdd-refactorer.md` | Port directly |
| Guildmaster verifier | `Guildmaster/.claude/agents/sdd-verifier.md` | Port directly |
| Guildmaster validate skill | `Guildmaster/.claude/skills/sdd-validate/SKILL.md` | Port directly |
| Guildmaster clarify skill | `Guildmaster/.claude/skills/sdd-clarify/SKILL.md` | Generalize from Linear to MCP-agnostic |
| Prospect Jira patterns | `sdd-start/SKILL.md` Jira Detection section | Reuse MCP detection approach |

## Out of Scope

- :x: Gap-check skill (belongs in living docs framework)
- :x: Changes to sdd-start, sdd-tasks, sdd-complete, sdd-discuss, sdd-specify, sdd-shape
- :x: Changes to sdd-onboard, sdd-init-project, sdd-start-issue
- :x: VS Code Copilot equivalents (.github/ files)
- :x: Changes to standards/ or specs/_templates/
- :x: Install script logic changes (new files are auto-classified as "framework")

## Dependencies

### Blocking Dependencies

- None

### External Dependencies

- Guildmaster project files (read-only source)

## Assumptions

- The Guildmaster versions of these files are the authoritative evolved versions
- The install script's `classify_file` function already handles new `.claude/agents/*` and `.claude/skills/*` files as "framework" category
- No VS Code Copilot (.github/) equivalents are needed in this iteration

## Open Questions

- None

---

## Clarifications

### Session 2026-04-01

- Q: sdd-review disposition? → A: Remove it. The 3 specialized reviewers replace it.
- Q: sdd-clarify? → A: Port generic version, add hints for install agent (MCP detection, no linear-cli)
- Q: gap-check? → A: Out of scope — belongs in living docs framework
- Q: Update sdd-implement? → A: Yes, update if references old review structure
- Q: Scope of other skills? → A: Out of scope. Changes should feel consistent throughout the whole framework.
