## Phase: Validate (gate only)

Run `scripts/sdd-gate.*`. Non-zero exit = validation FAILED: report the
script output verbatim, fix exactly what it reports, re-run to green.

On green: append `## Validation — YYYY-MM-DD` to `spec.md`, then the gate
result and test count; commit `docs(spec): record validation`, then run
`bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
