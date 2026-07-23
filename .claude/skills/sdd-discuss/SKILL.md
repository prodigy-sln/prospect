---
name: sdd-discuss
description: "Challenge the feature plan with stakeholder personas — parallel reviews (xhigh) or a negotiating agent team (max)"
argument-hint: "[spec folder name]"
allowed-tools: Read, Glob, Grep, Bash, Agent, SendMessage
---

# Discuss the Feature Plan

Stakeholder personas challenge the plan and answer open questions between
shaping and specification. Findings feed the spec.

## Step 1: Brief

Compose a self-contained brief (≤500 words) from
`specs/active/[folder]/requirements.md`: feature goal, core workflow,
decisions already made, open questions, exclusions, relevant codebase
context. Personas must be able to judge the plan from the brief alone.

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

Spawn each persona as a subagent with the brief. Each returns concerns with
severity, answers to the open questions, and one "what's missing". Then
synthesize. **Every inter-persona tension goes to the user unresolved** — no
silent dropping, no resolving conflicts yourself.

## Step 4b: Negotiating Team (max)

Spawn the personas as teammates. Each spawn prompt contains the brief, the
names of the other personas, and this protocol:

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

Append to `requirements.md` under `## Discussion Findings`:

- Resolved questions (answer + which persona settled it)
- New requirements or constraints that surfaced
- Every contested point labeled: **agreed** / **deferred** (by whom, why) /
  **deadlocked** (user decides)
- Team mode: a short discussion log — who challenged whom, what moved

Present the same summary in the conversation. The user rules on every
deadlock before specification proceeds.
