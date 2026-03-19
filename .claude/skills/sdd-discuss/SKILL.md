---
name: sdd-discuss
description: "Discuss open questions and the feature plan with a stakeholder agent team — invoked during /sdd-start between Shape and Specify"
argument-hint: "[spec folder name, e.g. '2026-03-18-user-auth']"
allowed-tools: Read, Glob, Grep, Bash, Agent, TeamCreate, TeamDelete, SendMessage, TodoWrite
---

# Discuss Feature Plan (Agent Team)

Spawn an agent team with stakeholder personas to discuss the feature plan, answer open questions from the Shape phase, and surface concerns before the spec is written. You act as the **moderator** who synthesizes their feedback.

**The Architect is always included.** Choose 1-2 additional personas that represent the most relevant stakeholders for this feature. Pick personas whose perspectives would create productive tension — e.g., a domain expert who cares about correctness vs. an end user who cares about simplicity.

**Examples of stakeholder personas** (adapt to the project):
- **Product Owner** — business value, prioritization, ROI
- **End User / Customer Persona** — usability, confusion points, delight
- **Domain Expert** — correctness, edge cases, compliance
- **Security Engineer** — threat model, data handling, auth
- **DevOps / SRE** — operability, monitoring, deployment risk
- **Designer / UX** — information architecture, interaction patterns
- **QA Lead** — testability, risk areas, regression concerns
- **Game Designer** — balance, engagement, player experience (for games)

**Workflow position**: Invoked during `/sdd-start`, between Phase 2 (Shape) and Phase 3 (Specify). The open questions from shaping and the user's answers become the discussion input. The discussion output feeds directly into the Specify phase.

```
/sdd-start
  Phase 1: Initiate (branch + folder)
  Phase 2: Shape (codebase discovery + questions → user answers)
  ► /sdd-discuss (team discusses the plan + open questions)
  Phase 3: Specify (writes spec.md, incorporating discussion findings)
```

## Prerequisites

- `specs/active/[folder]/requirements.md` exists with shaping Q&A and codebase findings
- The user has answered the shaping questions
- Open questions, unresolved decisions, or the overall feature direction need multi-perspective input

---

## Step 1: Compose the Discussion Brief

Read `specs/active/[folder]/requirements.md` (and any other context already gathered during shaping).

Compose a **discussion brief** (max 500 words) that includes:
- **Feature goal**: What problem this solves, what value it delivers
- **Core workflow**: The main user journey as understood so far
- **Key decisions made**: Answers the user already provided during shaping
- **Open questions**: Anything marked as unresolved, ambiguous, or needing further input
- **Out of scope**: What was explicitly excluded
- **Codebase context**: Relevant existing patterns, integration points, reusable components found during discovery

The brief must be self-contained — teammates should be able to evaluate the feature without reading additional files (though they can read project docs to ground their perspective).

---

## Step 2: Select Personas and Create the Agent Team

**Choose the team composition:**
1. Read `CLAUDE.md`, `product/mission.md` (if exists), and the requirements to understand the project domain.
2. The **Architect** is always included.
3. Select **1-2 additional personas** from the stakeholder list above (or invent fitting ones) based on what matters most for this feature. Ask yourself: whose perspective would catch blind spots the Architect would miss?
4. If the user has specified personas, use those instead.

Create a team named `discuss-{spec-folder-slug}` (e.g. `discuss-user-auth`).

Then spawn teammates using the Agent tool with `team_name` set to the team name. Each should be a `general-purpose` agent in **plan mode** (`mode: "plan"`) using the **Sonnet model** (`model: "sonnet"`) — they advise, they don't write code.

### Teammate: Architect ("architect") — Always included

```
You are the **Technical Architect** for this project.

Your job: evaluate this feature plan for technical feasibility, architecture fit, and implementation risk. Answer open questions from a technical perspective.

FIRST, read these files to ground your review:
- CLAUDE.md (project conventions)
- Any architecture docs or technical documentation in the project
- Browse the codebase to understand existing patterns

Then evaluate the plan against these criteria:

1. **Architecture fit** — Does this align with existing patterns? Or does it introduce new patterns that need justification?
2. **Complexity assessment** — Is this appropriately scoped? Any YAGNI violations or premature abstractions?
3. **Performance concerns** — Any risks with data volume, latency, or resource usage?
4. **Extensibility** — Can this be extended without major rework?
5. **Integration risks** — What could go wrong when this connects to existing systems?
6. **Open questions** — Answer each open question from a technical perspective. Propose concrete solutions.
7. **Missing considerations** — Are there technical aspects the plan should address but doesn't?

Be direct. Label concerns as **blocker**, **major**, or **minor**. Propose alternatives for any problems you flag.

## Communication

You are part of a discussion team. The team lead is the moderator.

1. Send your initial review to the team lead via SendMessage.
2. You may also message other teammates directly by name to challenge their points, ask questions, or propose compromises.
3. Stay focused on the feature plan under discussion. Keep exchanges short and constructive.
4. When the moderator asks you to wrap up, send your final position to the team lead.

FEATURE PLAN TO DISCUSS:
{brief}
```

### Additional Teammates — Template

For each additional persona, follow this structure:

```
You are the **[Role Title]** for this project.

Your job: evaluate this feature plan from the perspective of [what they care about]. Answer open questions from a [domain] perspective.

FIRST, read [relevant project docs — e.g., product docs, design docs, user-facing docs] to ground your review.

Then evaluate the plan against these criteria:

1. [Criterion relevant to this role]
2. [Criterion relevant to this role]
3. ...
6. **Open questions** — Answer each open question from your perspective.
7. **What's missing** — What would [their stakeholder group] expect that isn't addressed?

[Tone guidance — e.g., "Be opinionated", "Be blunt", "Focus on risk"]

## Communication

You are part of a discussion team. The team lead is the moderator.

1. Send your initial review to the team lead via SendMessage.
2. You may also message other teammates directly by name to challenge their points, ask questions, or propose compromises.
3. Stay focused on the feature plan under discussion. Keep exchanges short and constructive.
4. When the moderator asks you to wrap up, send your final position to the team lead.

FEATURE PLAN TO DISCUSS:
{brief}
```

Tailor the criteria, tone, and docs-to-read for each persona. Make them opinionated and specific to their role — generic reviewers add no value.

---

## Step 3: Moderate the Discussion

You are the **moderator**, not a participant. Your job is to keep the discussion focused, productive, and convergent.

### Phase A: Collect Initial Reviews

Wait for all teammates to send their initial reviews. Do NOT intervene until all have responded.

### Phase B: Spark Cross-Discussion

After all reviews are in, identify the **most productive tension points** — places where perspectives clash or complement each other. Then nudge specific teammates to engage each other directly:

Examples:
- "architect: the [other persona] wants X — is that feasible? Message them directly with your take."
- "[persona]: the architect flagged a concern with Y. Does a simpler version still work from your perspective? Tell [other persona] what you think."

Pick **2-3 prompts max**. Teammates can also initiate peer messages on their own — let organic discussion happen.

### Phase C: Drive to Conclusion

After two to three rounds of cross-discussion (or when the conversation starts looping), broadcast a wrap-up message:

"We're wrapping up. Each of you: send me your **final position** — your top 2-3 takeaways and any positions that changed during the discussion."

Wait for all final messages before proceeding.

---

## Step 4: Shut Down the Team

After all feedback is collected:

1. Send `shutdown_request` to each teammate
2. Wait for shutdown confirmations
3. Run TeamDelete to clean up

---

## Step 5: Synthesize and Return Results

Present the discussion summary **directly in the conversation** (do NOT write to a file).

Also **append the key findings to `requirements.md`** under a new section `## Discussion Findings` so that the Specify phase (Phase 3) can incorporate them into the spec. Include:
- Resolved open questions (with the answer and which persona provided it)
- New requirements or constraints surfaced during discussion
- Agreed design direction for contested points
- Unresolved tensions flagged for the user

### Output Format

```markdown
## Discussion Summary: [Feature Title]

### [Persona 1 Name]
- [Key finding with severity label]
- [Answers to open questions, if any]

### [Persona 2 Name]
- [Key finding]
- [Answers to open questions, if any]

### [Persona 3 Name] (if applicable)
- [Key finding]
- [Answers to open questions, if any]

### Cross-Cutting Themes
- [Theme that 2+ personas raised independently]

### Resolved Questions
- [Question]: [Answer] (source: [persona])

### Recommended Changes to the Plan
1. [Concrete recommendation with rationale from the discussion]
2. [...]

### Unresolved Tensions
- [Points where perspectives conflict — the user must decide]

### Next Steps
- Address unresolved tensions (if any)
- The Specify phase will incorporate these findings into spec.md
```

---

## Important Notes

- **Lead is moderator only**: You facilitate, prompt, and synthesize — you do NOT inject your own opinions into the discussion. Let the personas do the thinking.
- **Peer-to-peer is encouraged**: Teammates can and should message each other directly. The lead sparks cross-discussion but doesn't relay messages between them.
- **Read-only team**: Teammates advise only — they MUST NOT edit files or write code. Use `mode: "plan"` when spawning.
- **Token-intensive**: This spawns multiple full agent sessions. Reserve for significant features, not trivial changes.
- **Two to three discussion rounds**: After initial reviews, spark two to three rounds of cross-discussion, then drive to conclusion. Don't let it loop.
- **User decides**: Present tensions honestly. Don't resolve design conflicts unilaterally.
- **Feeds into Specify**: The output of this discussion is appended to `requirements.md` so Phase 3 (Specify) can reference it when writing `spec.md`.
