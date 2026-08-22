## Phase: Validate (fix)

1. **Gate**: run `scripts/sdd-gate.*` — red = FAILED, report verbatim, stop.
2. **Review**: spawn `sdd-reviewer` with the spec path, the diff of the fix
   branch, and the verbatim content of
   `standards/global/validation-calibration.md`. Its charge: the fix
   addresses the recorded root cause (not the symptom); every regression
   scenario has a test that fails without the fix; the diff contains
   nothing beyond the fix and its tests.
3. **Verdict**: PASS = gate green AND zero Blockers and Majors. Write
   `${FOLDER}/validation-report.md` (≤60 lines). Fix findings; re-run the
   gate and re-verify the fixes only.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
