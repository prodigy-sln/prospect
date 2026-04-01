# Architecture: Bridge CSE Review

## 1. Overview

Port Guildmaster's evolved review/validation pipeline into Prospect. The change replaces the single `sdd-review` agent with 3 focused reviewers, enhances the verifier and refactorer as earlier quality gates, rewrites the validate orchestrator for parallel execution, and adds a generic clarify skill.

**Scope**: `.claude/agents/`, `.claude/skills/`, `README.md`, `CLAUDE.md` — prompt/markdown files only, no executable code.

## 2. Assumptions & Constraints

- All files are markdown/YAML frontmatter — no runtime dependencies, no build step
- Install script already classifies `.claude/agents/*` and `.claude/skills/*` as "framework" — no install script changes needed
- VS Code Copilot equivalents (`.github/`) are out of scope
- sdd-clarify must work without any specific MCP tool installed (graceful fallback to user interaction)

## 3. Key Decisions

| Decision | Rationale | Alternative Considered |
|----------|-----------|----------------------|
| Split review into 3 agents (FR-1.1–1.3) | Focused scope prevents cross-contamination; enables parallel execution; each agent has clear severity definitions | Keep single agent with sections — rejected because findings bleed across concerns |
| Remove old `sdd-review.md` (FR-1.4) | Fully replaced by specialized reviewers; keeping it creates confusion about which to use | Keep as optional standalone — rejected per user decision |
| File manifest built by orchestrator (FR-4.1) | Single source of truth; all reviewers see same files; prevents reviewers from wandering the codebase differently | Each reviewer discovers files independently — rejected because inconsistent scope |
| 2-pass hard cap with escalation (FR-4.3) | Prevents infinite fix-validate loops; forces user decision on persistent issues | Unlimited passes — rejected because it wastes tokens and can loop |
| Verifier runs quality gates before tests (FR-2.1) | Deterministic failures (lint, format, types) are cheaper to check than running full test suite | Run tests first — rejected because test failures may mask formatting issues |
| Refactorer as first quality gate (FR-3.1) | Catches issues during implementation, not just at validation; mirrors validation criteria | Only check at validation — rejected because late feedback is expensive |
| MCP-agnostic clarify (FR-5.1) | Prospect is framework-agnostic; can't assume Linear, Jira, or any specific tool | Require specific MCP — rejected because it limits adoption |

## 4. Agent & Skill Relationships

### During Implementation (sdd-implement)

```
sdd-implement orchestrator
  ├── sdd-test-writer (RED)
  ├── sdd-implementer (GREEN)
  ├── sdd-refactorer (REFACTOR) ← ENHANCED: full quality checklist
  └── sdd-verifier (PHASE END)  ← ENHANCED: quality gates before tests
```

The refactorer now runs the same quality categories as the validation reviewers (correctness, architecture, quality, security, scope) but scoped to the current task's files. This is the "first quality gate."

### During Validation (sdd-validate)

```
sdd-validate orchestrator
  │
  ├── Step 2: Build file manifest (tasks.md ∪ git diff)
  │
  ├── Step 4: Launch ALL in parallel ──────────────────────┐
  │   ├── sdd-verifier         → requirements + scope      │
  │   ├── sdd-review-correctness → behavioral correctness  │
  │   ├── sdd-review-coverage    → test coverage gaps      │
  │   └── sdd-review-quality     → quality + scope control │
  │                                                        │
  ├── Step 6: Merge results ◄──────────────────────────────┘
  │   └── Aggregate findings, resolve conflicts
  │
  ├── Step 7: Generate validation-report.md
  │
  └── Step 8: Handle findings
      ├── Pass 1: Fix → Pass 2
      └── Pass 2: Fix → Escalate if issues remain
```

### Standalone (sdd-clarify)

```
sdd-clarify
  ├── Detect MCP tools (Atlassian / Linear / Notion / none)
  ├── Fetch issue context (via detected MCP)
  ├── Check conversation state (prior comments?)
  ├── Codebase discovery (Explore subagent)
  ├── Formulate non-technical questions
  └── Post as issue comment (via MCP) or present to user
```

## 5. Component Design

### New Agents

| Agent | Responsibility | Inputs | Output File |
|-------|---------------|--------|-------------|
| `sdd-review-correctness` | Verify behavior matches spec FR-X.X requirements exactly | spec, architecture, file manifest | `review-correctness.md` |
| `sdd-review-coverage` | Verify all requirements have adequate test coverage | spec, testing standards, file manifest, coverage output | `review-coverage.md` |
| `sdd-review-quality` | Check patterns, consistency, security, scope compliance | spec, code-quality standards, architecture, file manifest | `review-quality.md` |

**Boundary rules** (each agent's "NOT my concern" list prevents overlap):
- Correctness: does NOT check test coverage, code style, naming, performance
- Coverage: does NOT check correctness, code style, architecture, performance
- Quality: does NOT check behavioral correctness or test existence

### Modified Agents

| Agent | Key Changes |
|-------|-------------|
| `sdd-refactorer` | Added 6-category quality checklist (correctness, architecture, code quality, error handling, security, scope). Output includes Quality Review Results table + Deferred Observations |
| `sdd-verifier` | Added Step 1 (quality gates: formatter, linter, type checker) with auto-detection. Fail-fast before tests. Output includes Quality Gates table |

### New Skill

| Skill | Key Design Points |
|-------|------------------|
| `sdd-clarify` | MCP detection at runtime via tool availability check. Supports Atlassian (Jira/Confluence), Linear, Notion. Falls back to user interaction. Non-technical language mandate. Multi-round support |

### Modified Skills

| Skill | Key Changes |
|-------|-------------|
| `sdd-validate` | File manifest building; 4 parallel agent launches; 2-pass system with archival; explicit PASS criteria (zero Blockers/Majors/Minors); escalation |
| `sdd-implement` | Remove `sdd-review` from phase-end verifier delegation (line ~150). Verifier-only at phase end; full review suite is for validate |

### Removed

| File | Reason |
|------|--------|
| `sdd-review.md` | Replaced by 3 specialized reviewers. Validate skill no longer references it |

## 6. Data Contracts

### File Manifest (passed by validate orchestrator to all reviewers)

```markdown
### File Manifest
path/to/file1.ts
path/to/file2.ts
path/to/test1.test.ts
```

Built from: `files mentioned in tasks.md` ∪ `git diff --name-only main...HEAD` (filtered to feature-related files).

### Reviewer Output — Shared Severity Definitions

All 3 reviewers use the same severity scale but each defines its own criteria:

| Severity | Meaning | Blocks Completion? |
|----------|---------|-------------------|
| Blocker | Release-blocking defect | Yes |
| Major | Must fix before completion | Yes |
| Minor | Should fix (objectively verifiable) | Yes |
| Info | Suggestion, non-blocking | No |

**PASS** = zero Blockers + zero Majors + zero Minors across ALL reviewers.

### Validation Report Structure

```
validation-report.md
├── Summary table (per-reviewer status)
├── Correctness Review Summary (from review-correctness.md)
├── Coverage Review Summary (from review-coverage.md)
├── Quality Review Summary (from review-quality.md)
├── Test Results
├── Verifier Results
├── Info Findings (consolidated, non-blocking)
└── Sign-off checklist
```

### MCP Detection Pattern (sdd-clarify)

```
1. Check for Atlassian MCP tools → use Jira/Confluence
2. Check for Linear MCP tools → use Linear
3. Check for Notion MCP tools → use Notion
4. None available → ask user directly, skip issue commenting
```

## 7. Control Flows

### Validate Pass 1

1. Load spec, tasks, standards, architecture
2. Build file manifest (tasks.md + git diff)
3. Check for prior validation artifacts → none → Pass 1
4. Launch 4 agents in parallel (verifier + 3 reviewers)
5. Run test suite while agents work
6. Wait for all agents; collect reports
7. Merge results; aggregate finding counts; resolve conflicts
8. Generate `validation-report.md`
9. If zero Blockers/Majors/Minors → PASS → commit and output
10. If findings exist → fix them → proceed to Pass 2

### Validate Pass 2

1. Archive Pass 1 artifacts as `*-pass-1.md`
2. Update manifest (add any out-of-scope files from quality reviewer)
3. Launch fresh agents (do NOT provide Pass 1 artifacts — prevents anchoring)
4. Same flow as Pass 1
5. If zero findings → PASS
6. If findings remain → ESCALATED → present to user

### Clarify Flow

1. User invokes `/sdd-clarify PROJ-123`
2. Detect available MCP tools
3. Fetch issue details via detected MCP (or ask user for context)
4. Check for prior clarification comments
5. Delegate codebase discovery to Explore subagent
6. Formulate 5-8 non-technical questions
7. Post as issue comment (via MCP) or present to user
8. On re-invocation: read new replies, ask follow-ups, signal when ready

## 8. Integration Points

| Existing Code | How It's Extended |
|---------------|-------------------|
| `sdd-validate/SKILL.md` | Complete rewrite — old content replaced with parallel orchestration |
| `sdd-implement/SKILL.md` | Line ~150: change "Delegate to sdd-verifier and sdd-review" → "Delegate to sdd-verifier" |
| `sdd-start/SKILL.md` | Jira MCP detection pattern reused in sdd-clarify |
| `README.md` file tree | Add 3 new agents, remove old review, add clarify skill |
| `CLAUDE.md` | Update Workflow Reference and Subagents description |

## 9. Refactorings

| Refactoring | Rationale | Impact |
|-------------|-----------|--------|
| Remove all `sdd-review` references | Agent deleted; references become stale | `sdd-implement/SKILL.md`, `README.md`, `CLAUDE.md` |
| Update spec folder artifact list in README | New review artifacts (`review-correctness.md`, `review-coverage.md`, `review-quality.md`) replace `code-review.md` | `README.md` folder structure section |

## 10. Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Stale `sdd-review` references missed | Medium | Grep entire repo for "sdd-review" after changes; verify zero hits except the 3 specialized agents |
| MCP tool detection in sdd-clarify is fragile | Low | Use explicit tool name checks; graceful fallback to user interaction |
| Reviewer scope overlap despite boundary rules | Low | Each agent's "NOT my concern" list is explicit; validate skill prompt reinforces boundaries |

## 11. Testing Approach

No executable code — verification is manual:

1. **Reference check**: `grep -r "sdd-review" .claude/ CLAUDE.md README.md` — should only match `sdd-review-correctness`, `sdd-review-coverage`, `sdd-review-quality`
2. **File tree check**: Compare actual `.claude/agents/` and `.claude/skills/` listing against README documentation
3. **Cross-reference check**: Every agent referenced in a skill exists as a file; every skill in CLAUDE.md exists as a folder
4. **Frontmatter check**: All agents have valid `name`, `description`, `allowed-tools`, `model` fields

## 12. Deviation from Spec

None anticipated. All requirements map directly to Guildmaster source material with generalizations noted in the spec.

## 13. Open Questions

None.
