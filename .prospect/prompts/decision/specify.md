## Phase: Specify (decision)

The deliverable of this spec is decisions — ADRs, contracts, conventions —
plus any enforcement checks that make them verifiable. There is no
scenario→test contract for the decisions themselves.

1. Read the docs `docs/INDEX.md` routes for this topic and the standing
   architecture doc. Delegate codebase discovery to an Explore subagent only
   for what they don't answer.
2. Resolve `open` entries in the `requirements.md` clarifications ledger with
   the user; skip anything `resolved` or `assumed`.
3. Write `spec.md` from `.prospect/templates/decision.template.md`: the
   decision questions to settle (each with why it blocks later work), the
   option space per question, drivers and constraints, stakeholders
   affected, `## Enforcement Checks` (deterministic checks that would make
   each decision verifiable — or `none`), and Out of Scope (non-empty).
   Scenarios appear ONLY under Enforcement Checks, following
   `standards/global/scenario-guidelines.md`.
4. Present the spec; after approval set `approved: [today]` in the
   frontmatter and commit `docs(spec): add [topic] decision spec`.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
