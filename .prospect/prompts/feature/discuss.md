## Phase: Discuss (feature)

Personas challenge the design. Target: `architecture.md` when present
(the spec is background), else `spec.md`.

1. Brief (≤500 words): goal, key scenarios, the architecture's drivers,
   boundaries, binding decisions, assumptions; include prior
   `## Discussion Findings` so settled points aren't re-litigated. Give each
   persona the brief plus direct paths to `spec.md` and `architecture.md`.
2. Personas: `persona-architect` always; add 1–2 that create productive
   tension (`persona-product-owner`, `persona-compliance`, project-specific).
   User-specified personas win.
3. Run the mode described below, then synthesize.
4. Synthesis → append `## Discussion Findings` to `architecture.md`:
   resolved questions, new constraints, every contested point labeled
   **agreed** / **deferred** (by whom) / **deadlocked** (user decides).
   Apply agreed changes to the affected sections directly; scenario changes
   go into `spec.md`. **Every deadlock goes to the user before tasks.**

Commit `docs(spec): incorporate discussion findings for [feature]`, then run
`bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
