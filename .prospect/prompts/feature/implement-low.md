## Phase: Implement (feature · low — inline TDD)

Work scenario by scenario from `spec.md`:

1. Write the failing test yourself; run it and **display the failing
   output** — implementation before displayed failing output is prohibited.
   Record the mapping in `test-map.md` (one line per scenario → test).
   More than one test per scenario is right when distinct code paths or
   boundaries need their own falsifier.
2. Implement the minimum to pass; run that scenario's tests to green.
3. Commit `test: add failing test for [behavior]` → `feat: implement
   [behavior]` per scenario.
4. After the last scenario: one refactor pass over the whole diff
   (checklist: naming, duplication, dead code, error messages, nesting,
   standards fit); commit `refactor: improve [component]` only if changed.
5. Run `scripts/sdd-gate.*` to exit 0; fix exactly what it reports.
6. Append to `spec.md`: `## Validation` with the date and gate result.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
