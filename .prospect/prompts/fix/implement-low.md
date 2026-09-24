## Phase: Implement (fix · low — inline TDD)

1. **RED**: write one failing regression test per regression scenario,
   record the mapping in `test-map.md`, run them and **display the failing
   output** — the failure must reproduce the defect, not merely fail.
   Commit `test: add failing regression tests for [defect]`.
2. **GREEN**: change the narrowest layer that owns the incorrect behavior.
   Preserve unrelated behavior; no cleanup, renaming, or abstraction beyond
   the fix. Run the regression tests to green.
   Commit `fix: [defect]`.
3. **Gate**: run `scripts/sdd-gate.*` to exit 0 — the full suite proves no
   collateral breakage. Fix exactly what it reports.
4. Append to `spec.md`: `## Validation` with the date and gate result.
   That stamp is this path's verdict — there is no separate validate phase.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
