---
name: sdd-discuss
description: "Challenge the spec and architecture with stakeholder personas — parallel reviews (xhigh) or a negotiating agent team (max)"
argument-hint: "[spec folder name]"
allowed-tools: Read, Glob, Grep, Bash, Agent, SendMessage
---

# Discuss the Spec and Architecture

Stakeholder personas challenge the approved spec and, at `high+`, the
drafted architecture — after `/sdd-architect`, before task breakdown.
Findings amend the documents they target.

## Step 0: Target

Check `specs/active/[folder]/` for `architecture.md`.

- Present → this is the primary review target (Mode B for
  `persona-architect`). `spec.md` is background context.
- Absent (discuss invoked on demand at `medium` or below, before any
  architecture step) → `spec.md` is the review target (Mode A).

## Step 1: Brief

Compose a self-contained brief (≤500 words): feature goal, key scenarios,
and — when `architecture.md` exists — its drivers, boundaries table,
binding decisions, and assumptions. Include any prior `## Discussion
Findings` so a second round doesn't re-litigate settled points. Give
every persona the direct paths to `spec.md` and `architecture.md` (if
present) alongside the brief — `persona-architect` reads the full
architecture draft itself in Mode B rather than working from the summary
alone.

## Step 2: Personas

`persona-architect` always participates. Add 1–2 personas whose perspective
creates productive tension with it — `persona-product-owner`,
`persona-compliance`, or project-specific ones. User-specified personas win.

## Step 3: Mode

- `rigor: xhigh` → parallel review
- `rigor: max` → negotiating team. Requires
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`; when unset, run the parallel
  review instead and say so in the output.
- Manual invocation → ask which mode; default parallel review.

## Step 4a: Parallel Review (xhigh)

Spawn each persona as a subagent with the brief and document paths. Each
returns concerns with severity, answers to the open questions, and one
"what's missing". Then synthesize. **Every inter-persona tension goes to
the user unresolved** — no silent dropping, no resolving conflicts
yourself.

## Step 4b: Negotiating Team (max)

Spawn the personas as teammates. Each spawn prompt contains the brief, the
document paths, the names of the other personas, and this protocol:

1. Send your initial review to the lead AND to each other persona.
2. When a peer's review arrives, reply directly to that persona on your
   strongest disagreement — or state the compromise you would accept.
3. When the lead asks you to wrap up, send your final position: top
   takeaways and what changed your mind.

You are the lead and moderate only: **do not synthesize until every persona
has sent an initial review and at least one peer reply** — message
stragglers individually. Let the negotiation run 2–3 rounds, then request
final positions. Afterwards ask each teammate to shut down.

## Step 5: Synthesis

Append `## Discussion Findings` to the Step 0 target file
(`architecture.md` when present, else `spec.md`):

- Resolved questions (answer + which persona settled it)
- New requirements, constraints, or risks that surfaced
- Every contested point labeled: **agreed** / **deferred** (by whom, why) /
  **deadlocked** (user decides)
- Team mode: a short discussion log — who challenged whom, what moved

For every **agreed** finding that changes a binding decision or the
boundaries table, amend that section directly (don't leave a contradicted
decision standing next to the note that overrode it) and mark it "amended
per discussion". A finding that requires a new or changed spec scenario
gets applied to `spec.md` directly, with a one-line cross-reference from
the architecture's Discussion Findings entry.

Present the same summary in the conversation. The user rules on every
deadlock before task breakdown proceeds. Commit:
`docs(spec): incorporate discussion findings for [feature]`.

End with:

```
Discussion findings committed. Safe to /clear.
Next: /sdd-tasks
```
