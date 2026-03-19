---
name: sdd-architect
description: Optional architecture planning between specification and tasks
argument-hint: "[specification folder name, e.g. '2026-02-27-feature']"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Architecture Planning (Optional)

Produce a concise architecture plan between `sdd-specify` and `sdd-tasks` so implementation is clear and scoped. Favor platform-level patterns and shared surfaces over feature-local stopgaps (e.g., define the home screen globally, not inside a single feature) to keep the future vision intact.

## Prerequisites

- `specs/active/[folder]/spec.md` is complete and reviewed
- Out of scope and open questions are resolved or explicitly noted
- Requirements and visuals (if any) are available

---

## Step 1: Load Context

Read these files, if not already in context:

1. **Specification**: `specs/active/[folder]/spec.md`
2. **Requirements**: `specs/active/[folder]/requirements.md`
3. **Standards**: `standards/global/testing.md`, `standards/global/code-quality.md`
4. **Visuals** (optional): `specs/active/[folder]/visuals/`

---

## Step 2: Synthesize Drivers

- Identify goal, users, and critical flows from the spec (reference FR-IDs)
- Extract constraints: performance, security, offline, platform, integrations
- Note out-of-scope items that affect architecture boundaries

---

## Step 3: Delegate to Architect Agent (optional but recommended)

Use the **Task tool** with `subagent_type: "sdd-architect"`.

Prompt to send:

```
Generate an architecture plan for [feature]. Inputs: spec.md, requirements.md, standards, system-architecture.md, ux-and-navigation.md, ai-and-voice-integration.md, product-vision.md. 
Produce:
- Key decisions (with rationale and trade-offs)
- Component breakdown (modules, responsibilities, public interfaces)
- Data contracts (schemas/payload shapes, validation rules)
- Control/interaction flows (step lists; sequence text is fine)
- Integration points and existing code to reuse (paths, patterns)
- Risk/mitigation and edge cases
- Testing hooks (what to test at each layer)
Keep it concise and actionable for task breakdown.
```

Merge agent output with your own findings; ensure consistency with the spec.

---

## Step 4: Write `architecture.md`

Create `specs/active/[folder]/architecture.md` with sections:

1. **Overview** — goal, scope, primary users
2. **Assumptions & Constraints** — platform, performance, security, offline, dependencies
3. **Key Decisions** — bullet list with rationale and alternatives
4. **Overall Architecture & Feature Connection Points** — system context, layers, and explicitly labeled connection points for the feature
5. **Component Design** — modules/services/widgets, responsibilities, public APIs, reuse points
6. **Data Contracts** — entities/payloads, field definitions, validation, error shapes
7. **Control Flows** — textual sequence of major flows (no diagrams required)
8. **Integration Points** — existing code references and how to extend them
9. **Refactorings** — scoped refactors required or recommended, with rationale and impact
10. **Risks & Mitigations** — what can go wrong and how to handle
11. **Testing Approach** — what to test per layer to honor the spec’s test strategy
12. **Deviation from Spec** — if any, clearly note and explain
13. **Open Questions** — max 3, only if strictly necessary

Keep it brief; favor lists over prose. Link decisions to FR-IDs where applicable.

---

## Step 5: Quality Checks

- Aligns with spec and respects Out of Scope
- Decisions are actionable for task breakdown
- Interfaces and data shapes are unambiguous and testable
- Identifies reuse of existing components where possible
- Flags risks early; no unresolved ambiguities beyond "Open Questions"

---

## Output

Write the plan to `specs/active/[folder]/architecture.md` and summarize:

```
## Architecture Plan Ready

**Spec**: `specs/active/[folder]/spec.md`
**Architecture**: `specs/active/[folder]/architecture.md`

### Highlights
- Decisions: [count]
- Components: [count]
- Integration points: [count]
- Risks flagged: [count]

### Next Steps
1. Review the architecture plan
2. Adjust if needed
3. Proceed to: `/sdd-tasks`
```

Tell the user to review the architecture before generating tasks.
