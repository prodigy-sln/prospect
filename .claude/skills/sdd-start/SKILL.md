---
name: sdd-start
description: "Start a feature: choose rigor, create branch and spec folder, gather requirements, write and audit the specification"
argument-hint: "[feature description or ISSUE-KEY]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion
---

# Start a Feature

Take a feature from description to a reviewed, audited specification.

## Step 1: Rigor

Recommend a tier and let the user confirm; record it as `rigor:` in the spec
frontmatter.

- **low** — isolated small change, no cross-cutting impact
- **medium** — default
- **high** — mandatory floor when the feature touches auth, payments,
  personal data, compliance, or destructive migrations
- **xhigh / max** — contested plans, many stakeholders (adds `/sdd-discuss`)

Escalate later whenever new risk appears (record the reason in the
frontmatter). Downgrade only with explicit user confirmation, recorded.

## Step 2: Branch & Folder

Branch `feature/YYYY-MM-DD-short-name` (issue-driven:
`feature/KEY-123-short-name`). Folder `specs/active/YYYY-MM-DD-short-name/`.

The spec file is ALWAYS `specs/active/[folder]/spec.md` — only the template
differs by tier: at `low`, create it from
`specs/_templates/spec-mini.template.md` and skip to Step 4; otherwise
create it from `specs/_templates/spec.template.md` plus an empty
`requirements.md`.

## Step 3: Shape

1. If `docs/INDEX.md` exists, read the docs it routes for this topic before
   touching code.
2. Delegate codebase discovery to an Explore subagent; request a compact
   report only: relevant components, patterns to follow, integration
   points, reuse candidates.
3. Ask the user the questions the codebase cannot answer (decision-shaped,
   with options and a default). For issue-driven features, run
   `/sdd-clarify` first.
4. **UI surface detected** → also ask look & feel: key screens; empty,
   loading, and error states; density and tone; responsive targets; visual
   references; existing components to use. Integration questions alone are
   insufficient for UI features.
5. Record everything in `requirements.md`.
6. At `xhigh`/`max`, run `/sdd-discuss` now. At lower tiers, suggest it when
   stakeholder positions conflict.

## Step 4: Specify

Write the spec from the template. Scenarios follow
`standards/global/scenario-guidelines.md`: every FR gets at least one
happy-path and one unwanted-behavior scenario; UI states become scenarios.
Out of Scope must be non-empty — if it is, ask the user what is excluded.
Incorporate `## Discussion Findings` from requirements.md when present.

## Step 5: Scenario Audit

At `medium+`, spawn `sdd-scenario-auditor` with the spec path and
scenario-guidelines path. At `low`, apply its checklist inline. Keep the gap
report for Step 7.

## Step 6: Design Exploration (UI features, when direction is unsettled)

Offer to generate 1–3 self-contained HTML mockup variants in
`specs/active/[folder]/visuals/`, each committing to a distinct direction.
Apply `standards/global/ui-design.md` and deliberate visual design:
aesthetic direction, typography, spacing — no template defaults. The user
picks or mixes; record the approved direction in the spec's Visual Design
section. It is binding for implementation.

## Step 7: Review Handoff

Present to the user together: spec summary, audit gaps (accept/reject each
suggested scenario draft — accepted drafts merge into the spec), and design
variants if any. After approval, commit: `docs(spec): add [feature] specification`.

End with:

```
Spec approved and committed. Everything downstream needs is in
specs/active/[folder]/ — safe to /clear.
Next: /sdd-architect (high+) or /sdd-tasks (medium+) or /sdd-implement (low).
```
