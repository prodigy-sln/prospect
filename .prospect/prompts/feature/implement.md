## Phase: Implement (feature · test-author engine)

Read `spec.md`, `tasks.md`, `architecture.md` (if present),
`standards/global/testing.md`, `standards/global/code-quality.md`. Resume
from the first unchecked task. Per tasks-phase:

**RED — delegate.** Spawn `sdd-test-author` as a named agent
(`test-author-phase-N`) with only: spec path, this phase's scenario IDs, and
the paths to `testing.md`, `scenario-guidelines.md`, `architecture.md` (if
present). Receive its Test Contract (binding interface decisions,
`test-map.md` path, failing count, test command). Surface already-satisfied
scenarios or architecture conflicts to the user before continuing.

**GREEN — inline, task by task.** Find the task's tests via `test-map.md`,
read them, implement the minimum to pass. Run **only that task's tests**
(the map names them). Commit `feat: implement [task]`; mark the task
` — done` (append; never rewrite task text).

Test files belong to the test author. A failing test that looks wrong goes
to the named author with facts only (test name, assertion diff, scenario ID,
minimal excerpt); apply the verdict: `test-correct` → conform ·
`test-wrong` → author fixes and commits · `scenario-ambiguous` → user.

**REFACTOR — once per phase.** Apply the checklist (naming, duplication,
dead code, error messages, nesting, standards fit) to the phase's whole
diff; commit `refactor: improve [component]` only when something changed.
Out-of-diff issues → `## Notes`, never fixed in passing.

**Gate.** At phase end run `scripts/sdd-gate.*` — exit 0 before the next
phase; fix exactly what it reports. Then run
`bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
