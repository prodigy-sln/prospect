## Phase: Architect (feature — delta only)

The spec's `## Architecture Delta` names new binding decisions. Spawn the
`sdd-architect` agent with: spec and requirements paths, the standing
architecture doc (`docs/architecture.md` or the location `docs/INDEX.md`
routes for architecture), and the standards paths it names.

Its charge: design ONLY the delta. Project constants (stack, gate flags,
module map, existing boundaries, composition root) come from the standing
doc and are not re-derived. Output `architecture.md` in the spec folder:
drivers for the delta, boundaries table for new dependencies, each decision
BINDING or DEFERRED with options and trade-offs, interfaces, integration
points, assumptions, risks. Halt-and-ask applies when a material driver is
unknown (one batched round, `open-questions.md`).

Commit `docs(spec): add architecture delta for [feature]`, then run
`bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
