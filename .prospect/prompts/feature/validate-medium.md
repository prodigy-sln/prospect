## Phase: Validate (feature · medium)

1. **Gate**: run `scripts/sdd-gate.*`, then
   `bash .prospect/scripts/sdd-artifact-lint.sh ${FOLDER}`. Either red =
   FAILED — report verbatim, fix, re-run; no review on a red gate.
2. **Review pack**: build the manifest once — files named in `tasks.md` plus
   feature files from `git diff --name-only $(git merge-base HEAD main)..HEAD`,
   excluding unrelated tool-touched files. Write manifest + latest test and
   coverage output to `${FOLDER}/review-pack.md`.
3. **Review**: spawn `sdd-reviewer` with spec/tasks/architecture paths, the
   review pack, and the verbatim content of
   `standards/global/validation-calibration.md`. One pass.
4. **Verdict**: PASS = gate green AND zero Blockers and Majors. Minors and
   Info never block at medium — record them; they become tracked issues at
   complete. Write `${FOLDER}/validation-report.md` (≤120 lines): counts,
   scenario verdicts, findings with citations, gate output, metrics summary
   from `metrics.md`, verdict.
5. **Findings**: fix Blockers/Majors (implement rules apply — test ownership,
   arbitration). Re-run the gate, then re-verify **each fixed finding only**
   — no fresh review sweep. Update the report.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
