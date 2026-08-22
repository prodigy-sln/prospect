## Phase: Discuss (decision · panel)

Compose a self-contained brief (≤500 words): the decision questions, option
space, drivers, constraints; include prior `## Discussion Findings` so
settled points aren't re-litigated. Personas: `persona-architect` always;
add 1–2 creating productive tension (`persona-product-owner`,
`persona-compliance`, project-specific). User-specified personas win. Give
each the brief plus the spec path.

Run the mode described below, then synthesize: append
`## Discussion Findings` to `spec.md` — resolved questions, new
constraints, every contested point labeled **agreed** / **deferred** (by
whom) / **deadlocked** (user decides). **Every deadlock goes to the user
before the decide phase.** Commit
`docs(spec): incorporate discussion findings`, then run
`bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
