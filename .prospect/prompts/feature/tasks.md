## Phase: Tasks (feature)

Write `${FOLDER}/tasks.md` from `.prospect/templates/tasks.template.md`,
without a user stop — the spec approval covered this breakdown.

- One task = one coherent scenario group in one area, with file hints.
- Every scenario appears in exactly one task; verify before writing.
- Phases split only at real dependency boundaries; `[P]` marks tasks
  independent of other `[P]` tasks in the same phase.
- **Budget: 60 lines.** Task entries are one line plus a scenario line —
  design rationale lives in the spec, lessons go to `docs/` at completion,
  status is appended as ` — done` markers, never as prose.

Commit `docs(spec): add task breakdown for [feature]`. Report phases, task
count, and scenario assignment confirmation, then state: safe to `/clear`;
next run `bash .prospect/scripts/sdd-next.sh ${NAME}`.
