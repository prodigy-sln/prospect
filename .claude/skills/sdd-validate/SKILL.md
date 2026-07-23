---
name: sdd-validate
description: "Verify the implementation against the specification — deterministic gate plus tier-scaled review"
argument-hint: "[spec folder name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, Workflow
---

# Validate

## Step 1: Gate (every tier)

Run `scripts/sdd-gate.*`. Non-zero exit = validation FAILED: report the
script output verbatim and stop — no review runs on a red gate.

**Low tier**: a green gate is the whole validation. Append a dated
validation note to `spec.md` and finish.

## Step 2: Manifest

Build the file manifest once; all reviewers receive the same one:

- Files named in `tasks.md`
- Plus feature-related files from `git diff --name-only $(git merge-base HEAD main)..HEAD`
- Exclude unrelated tool-touched files (lockfiles, generated code) unless
  tasks.md names them

## Step 3: Review

**Medium**: spawn `sdd-reviewer` with: spec/tasks/architecture paths, the
manifest, the verbatim content of
`standards/global/validation-calibration.md`, and the latest test and
coverage output. One pass.

**High+**: invoke the saved workflow —
`Workflow({name: "sdd-validate", args: {specFolder, manifest, calibration, passNumber}})`.
It runs the three specialist reviewers in parallel, verifies each candidate
finding against the code, and merges deterministically.

WHEN the Workflow tool is unavailable: spawn `sdd-review-correctness`,
`sdd-review-coverage`, and `sdd-review-quality` in parallel yourself with
the same inputs, then apply the same merge rules (evidence bar, severity
definitions, Minor cap) manually.

## Step 4: Verdict

**PASS** = gate green AND zero Blockers, Majors, and Minors across all
reviewers. Info findings never block; record them.

Write `specs/active/[folder]/validation-report.md`: summary table
(reviewer × severity counts), scenario verdicts, findings with citations,
gate output, overall verdict.

## Step 5: Findings

**Pass 1 with findings**: fix them — implementation fixes follow the
implement rules (test ownership and arbitration still apply; coverage gaps
go to the phase's test author). Then re-run from Step 1 as Pass 2.

**Pass 2**: accepts only NEW findings of severity Major or higher. If
findings remain after Pass 2 fixes, stop and escalate to the user with a
table of unresolved issues — never start Pass 3 unprompted.

**High+ after PASS**: user sign-off is required before `/sdd-complete`.

## Output

```
Validation [PASS/FAILED/ESCALATED] — pass [N]
Gate: [green/red] · Findings: B[x] M[x] m[x] Info[x]
Report: specs/active/[folder]/validation-report.md
Next: /sdd-complete  (high+: after your sign-off)
```
