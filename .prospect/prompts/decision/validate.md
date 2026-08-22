## Phase: Validate (decision)

1. **Gate**: run `scripts/sdd-gate.*` — red = FAILED, report verbatim, stop.
2. **Decision review**: spawn `sdd-reviewer` with the spec path, the
   decision record, and the verbatim content of
   `standards/global/validation-calibration.md`. Its charge here: every
   decision question from the spec has a recorded BINDING or DEFERRED
   answer; every enforcement-check scenario has a passing check (via
   `test-map.md` when checks were built); no decision contradicts the
   discussion's agreed findings or the standing architecture doc; every
   deadlock carries a user ruling.
3. **Verdict**: PASS = gate green AND zero Blockers and Majors. Write
   `${FOLDER}/validation-report.md` (≤120 lines): per-question verdicts,
   findings with citations, gate output, metrics summary, verdict. Fix
   Blockers/Majors; re-run the gate and re-verify the fixes only.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
