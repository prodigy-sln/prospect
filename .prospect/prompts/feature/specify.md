## Phase: Specify (feature)

1. **Recall**: read the docs `docs/INDEX.md` routes for this topic. Delegate
   codebase discovery to an Explore subagent only for what docs don't answer;
   request a compact report (components, patterns, integration points, reuse).
2. **Clarify from the ledger**: `requirements.md` `## Clarifications` holds
   questions with status `resolved | open | assumed`. Ask the user only
   `open` questions plus new decision-shaped ones the codebase cannot answer;
   record every answer in the ledger. UI surface detected → also ask look &
   feel (key screens; empty/loading/error states; density, tone; responsive
   targets; references; existing components) and apply
   `standards/global/ui-design.md`.
3. **Specify**: write `spec.md` from `.prospect/templates/spec.template.md`.
   Scenarios follow `standards/global/scenario-guidelines.md` — each is the
   floor of at least one test. Fill `## Architecture Delta`: new external
   dependencies, boundaries, data models, or public contracts this feature
   introduces — or `none`. Out of Scope must be non-empty.
   **Scenario budget**: ${SCENARIO_BUDGET} at this spec's rigor. Past it,
   present the count and a proposed merge/cut list; the user confirms
   before you keep more. Under budget, never merge scenarios that need
   separate falsifiers.
4. **Audit**: spawn `sdd-scenario-auditor` (spec path + guidelines path +
   scenario budget ${SCENARIO_BUDGET}). It reports gaps AND
   over-specification (mergeable near-duplicates).
5. **One approval**: present spec summary, audit gaps and prunes
   (accept/reject each), and design variants if any. After approval set
   `approved: [today]` in the frontmatter and commit
   `docs(spec): add [feature] specification`.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue without a
further stop — the task breakdown needs no separate approval.
