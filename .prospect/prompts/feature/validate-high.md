## Phase: Validate (feature · high+)

1. **Gate**: run `scripts/sdd-gate.*`. Red = FAILED; report verbatim, stop.
2. **Manifest**: files named in `tasks.md` plus feature files from
   `git diff --name-only $(git merge-base HEAD main)..HEAD`, excluding
   unrelated tool-touched files. All reviewers receive the same manifest.
3. **Review**: invoke the saved workflow —
   `Workflow({name: "sdd-validate", args: {specFolder, manifest, calibration, passNumber}})`
   with calibration = verbatim `standards/global/validation-calibration.md`.
   It fans out the three specialists, adversarially verifies each candidate
   finding, and merges deterministically: **only confirmed findings block**;
   plausible findings and abstentions are reported for you and the user.
   WHEN the Workflow tool is unavailable: spawn `sdd-review-correctness`,
   `sdd-review-coverage`, `sdd-review-quality` in parallel with the same
   inputs and apply the same merge rules manually.
4. **Verdict**: PASS = gate green AND zero confirmed Blockers, Majors, and
   Minors. Write `${FOLDER}/validation-report.md` (≤120 lines): counts,
   scenario verdicts and abstentions, findings with citations, gate output,
   metrics summary from `metrics.md`, verdict.
5. **Pass 2 is targeted.** Fix pass-1 findings (test ownership and
   arbitration apply), re-run the gate, then re-verify **the fixes only** —
   a fresh three-reviewer sweep runs solely when the fixes changed files
   beyond the original findings' scope. When every pass-1 finding was
   documentation-severity, skip the sweep entirely. Findings remaining after
   pass 2: stop and escalate to the user — never start pass 3 unprompted.
6. **Sign-off**: after PASS the user signs off before completion.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}`.
