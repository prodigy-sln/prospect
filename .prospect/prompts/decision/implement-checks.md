## Phase: Implement (decision — enforcement checks)

`spec.md` `## Enforcement Checks` names deterministic checks; the decision
record says what they verify. This is tested code — TDD applies.

Write `tasks.md` (≤60 lines) grouping the check scenarios, then per phase:
spawn `sdd-test-author` (spec path, the check scenarios' IDs, testing and
scenario-guidelines paths); implement inline to green task by task with
`feat:` commits and scoped test runs via `test-map.md`; one refactor pass
per phase. Test ownership and arbitration apply. Wire each check where the
decision record places it (project checks into the gate only via the
project-level gate policy). Run `scripts/sdd-gate.*` to exit 0.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
