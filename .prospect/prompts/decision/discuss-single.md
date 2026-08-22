## Phase: Discuss (decision · single review)

Compose a self-contained brief (≤500 words): the decision questions, option
space, drivers, constraints. Spawn `persona-architect` with the brief and
the spec path; it returns concerns with severity, answers to the open
questions, and one "what's missing".

Append `## Discussion Findings` to `spec.md`: resolved questions, new
constraints, contested points labeled **agreed** / **deferred** /
**deadlocked** (user decides). Every deadlock goes to the user before the
decide phase. Commit `docs(spec): incorporate discussion findings`, then run
`bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
