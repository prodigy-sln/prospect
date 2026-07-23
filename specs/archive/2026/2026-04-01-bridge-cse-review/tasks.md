# Task Breakdown: Bridge CSE Review

**Spec**: `specs/active/2026-04-01-bridge-cse-review/spec.md`
**Architecture**: `specs/active/2026-04-01-bridge-cse-review/architecture.md`
**Branch**: `feature/2026-04-01-bridge-cse-review`
**Created**: 2026-04-01

## Overview

| Metric | Count |
|--------|-------|
| Total Tasks | 14 |
| Phases | 5 |

**Note**: This is a framework change (prompt/markdown files). No executable code or traditional TDD applies. Tasks are ordered by dependency: new agents first (no dependencies), then agents that reference them, then skills that orchestrate them, then documentation.

## Task Format

```
- [ ] [ID] [P?] [Domain] Description — path/to/file
      └── Acceptance: [How to verify completion]
```

- `[P]` = Parallelizable (can run concurrently with other [P] tasks)
- Domain tags: `[AGENT]` `[SKILL]` `[DOCS]` `[VERIFY]`

---

## Phase 1: New Review Agents

**Dependencies**: None
**Goal**: 3 specialized review agents exist, ported from Guildmaster with generic language

- [ ] T001 [P] [AGENT] Create correctness review agent — `.claude/agents/sdd-review-correctness.md`
      └── FR: FR-1.1
      └── Source: Guildmaster `sdd-review-correctness.md`
      └── Acceptance: Agent file exists with valid frontmatter; reviews behavioral correctness only; produces per-requirement verdicts; "NOT my concern" list excludes coverage/style/performance

- [ ] T002 [P] [AGENT] Create coverage review agent — `.claude/agents/sdd-review-coverage.md`
      └── FR: FR-1.2
      └── Source: Guildmaster `sdd-review-coverage.md`
      └── Acceptance: Agent file exists with valid frontmatter; maps requirements to tests; identifies coverage gaps per acceptance criterion; "NOT my concern" list excludes correctness/style/architecture

- [ ] T003 [P] [AGENT] Create quality review agent — `.claude/agents/sdd-review-quality.md`
      └── FR: FR-1.3
      └── Source: Guildmaster `sdd-review-quality.md`
      └── Acceptance: Agent file exists with valid frontmatter; checks patterns/consistency/security/scope; detects out-of-scope files via git diff; two-developer test for Minor severity; "NOT my concern" list excludes correctness/coverage

**Phase 1 Checklist**:
- [ ] All 3 agents have consistent frontmatter format (name, description, allowed-tools, model)
- [ ] No Guildmaster-specific or game-specific language
- [ ] Each agent's scope boundary is explicitly stated

---

## Phase 2: Enhanced Agents

**Dependencies**: None (independent of Phase 1)
**Goal**: Refactorer and verifier upgraded with Guildmaster improvements

- [ ] T004 [P] [AGENT] Update refactorer with quality checklist — `.claude/agents/sdd-refactorer.md`
      └── FR: FR-3.1, FR-3.2
      └── Source: Guildmaster `sdd-refactorer.md`
      └── Acceptance: 6-category quality checklist present (correctness, architecture, code quality, error handling, security, scope); output includes Quality Review Results table; Deferred Observations section for out-of-scope findings; "first quality gate" framing

- [ ] T005 [P] [AGENT] Update verifier with deterministic quality gates — `.claude/agents/sdd-verifier.md`
      └── FR: FR-2.1, FR-2.2
      └── Source: Guildmaster `sdd-verifier.md`
      └── Acceptance: Step 1 runs formatter/linter/type-checker BEFORE tests; auto-detects tooling from project config; fail-fast if gates fail; output includes Quality Gates table; no Guildmaster-specific references

**Phase 2 Checklist**:
- [ ] Refactorer quality checklist mirrors validation criteria
- [ ] Verifier quality gates are platform-agnostic (examples for JS/Go/.NET/Python)
- [ ] No FORGE-XX or project-specific prefixes

---

## Phase 3: Skills

**Dependencies**: Phase 1 (validate skill references new review agents), Phase 2 (validate references enhanced verifier)
**Goal**: Validate skill rewritten, implement skill updated, clarify skill created

- [ ] T006 [SKILL] Rewrite validate skill for parallel 3-reviewer orchestration — `.claude/skills/sdd-validate/SKILL.md`
      └── FR: FR-4.1, FR-4.2, FR-4.3, FR-4.4
      └── Source: Guildmaster `sdd-validate/SKILL.md`
      └── Acceptance: File manifest built from tasks.md + git diff; 4 agents launched in parallel (verifier + 3 reviewers); 2-pass system with archival and escalation; explicit PASS criteria (zero Blockers/Majors/Minors); references `sdd-review-correctness`, `sdd-review-coverage`, `sdd-review-quality` (not old `sdd-review`)
      └── Depends on: T001, T002, T003, T005

- [ ] T007 [SKILL] Update implement skill to remove orphaned sdd-review reference — `.claude/skills/sdd-implement/SKILL.md`
      └── FR: FR-6.1
      └── Acceptance: Phase-end verifier delegation (~line 150) says "Delegate to sdd-verifier subagent" only (no "and sdd-review"); rest of file unchanged
      └── Depends on: T005

- [ ] T008 [SKILL] Create generic clarify skill — `.claude/skills/sdd-clarify/SKILL.md`
      └── FR: FR-5.1, FR-5.2, FR-5.3, FR-5.4, FR-5.5
      └── Source: Guildmaster `sdd-clarify/SKILL.md`
      └── Acceptance: MCP detection for Atlassian/Linear/Notion at runtime; falls back to user interaction if no MCP available; multi-round support; non-technical language mandate; codebase discovery via Explore subagent; no `linear-cli` references; install-agent hints in description/comments about MCP dependencies

**Phase 3 Checklist**:
- [ ] Validate skill references only the 3 specialized reviewers (not old sdd-review)
- [ ] Implement skill has no sdd-review references
- [ ] Clarify skill works without any MCP tool installed

---

## Phase 4: Cleanup & Documentation

**Dependencies**: Phase 3 (all agent/skill changes committed before doc updates)
**Goal**: Old review agent removed; README and CLAUDE.md reflect new structure

- [ ] T009 [AGENT] Remove old monolithic review agent — `.claude/agents/sdd-review.md`
      └── FR: FR-1.4
      └── Acceptance: File deleted; `git status` shows deletion
      └── Depends on: T006, T007 (ensure nothing references it before deleting)

- [ ] T010 [DOCS] Update README.md — file tree, features, commands
      └── FR: FR-6.2
      └── Acceptance: File tree shows 3 new agents, no old `sdd-review.md`, new `sdd-clarify` skill; "Code Review During Validation" section updated to describe 3 parallel reviewers; commands table includes `/sdd-clarify`; spec folder structure shows `review-correctness.md`, `review-coverage.md`, `review-quality.md` instead of `code-review.md`
      └── Depends on: T009

- [ ] T011 [DOCS] Update CLAUDE.md — workflow reference
      └── FR: FR-6.3
      └── Acceptance: No references to single `sdd-review` agent; subagents list updated; workflow diagram accurate; `/sdd-clarify` mentioned if applicable
      └── Depends on: T009

**Phase 4 Checklist**:
- [ ] `sdd-review.md` deleted
- [ ] README file tree matches actual `.claude/` contents
- [ ] CLAUDE.md has no stale references

---

## Phase 5: Verification

**Dependencies**: Phase 4
**Goal**: Confirm zero stale references and full consistency

- [ ] T012 [VERIFY] Grep for stale sdd-review references
      └── Acceptance: `grep -r "sdd-review" .claude/ CLAUDE.md README.md` returns ONLY matches for `sdd-review-correctness`, `sdd-review-coverage`, `sdd-review-quality`; zero hits for bare `sdd-review` as an agent name

- [ ] T013 [VERIFY] Cross-check file tree against README
      └── Acceptance: Every `.claude/agents/sdd-*.md` file is listed in README; every `.claude/skills/sdd-*/SKILL.md` is listed; no phantom entries

- [ ] T014 [VERIFY] Validate frontmatter consistency across all agents
      └── Acceptance: All 8 agent files have `name`, `description`, `allowed-tools`, `model` fields; names match filenames; descriptions are accurate

**Phase 5 Checklist**:
- [ ] Zero stale `sdd-review` references
- [ ] README matches actual file tree
- [ ] All agent frontmatter valid and consistent

---

## Execution Summary

### Recommended Order

```
Phase 1 (New Agents) ──── T001, T002, T003 [parallel]
    │
Phase 2 (Enhanced) ────── T004, T005 [parallel, parallel with Phase 1]
    │
    ▼
Phase 3 (Skills) ──────── T006 → T007 → T008 [T006 depends on Phase 1+2]
    │
    ▼
Phase 4 (Cleanup) ─────── T009 → T010, T011 [parallel after T009]
    │
    ▼
Phase 5 (Verify) ──────── T012, T013, T014 [parallel]
```

### Parallel Opportunities

- **T001 + T002 + T003 + T004 + T005**: All 5 agent files can be created/updated in parallel (no inter-dependencies)
- **T010 + T011**: README and CLAUDE.md updates can run in parallel after T009
- **T012 + T013 + T014**: All verification tasks are independent

### Dependencies Graph

```
T001 ─┐
T002 ─┼──→ T006 ──→ T009 ──→ T010
T003 ─┘      │                  │
T005 ─┬──────┘         T011 ◄──┘
      └──→ T007
T004 (independent)
T008 (independent, after T006 for consistency review)
T012, T013, T014 (after Phase 4)
```

---

## Notes

- All source material is read from `C:\code\prodigy.solutions\Guildmaster\.claude\`
- Guildmaster files are the authoritative source; generalize by removing game-specific language
- Install script needs no changes — `.claude/agents/*` and `.claude/skills/*` auto-classify as "framework"
