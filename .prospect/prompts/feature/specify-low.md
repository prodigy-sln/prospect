## Phase: Specify (feature · low)

1. Read the docs `docs/INDEX.md` routes for this topic; explore code only
   for what they don't answer.
2. Resolve `open` entries in the `requirements.md` clarifications ledger with
   the user; skip anything already `resolved` or `assumed`.
3. Write `spec.md` from `.prospect/templates/spec-mini.template.md`: goal,
   flat scenario list (per `standards/global/scenario-guidelines.md`),
   non-empty Out of Scope. The scenario list is also the task list.
4. Apply the audit rubric inline: every behavior has an unwanted-behavior
   scenario; outcomes observable; boundaries concrete; no contradictions.
5. Present the spec; after approval set `approved: [today]` in the
   frontmatter and commit `docs(spec): add [feature] mini-spec`.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
