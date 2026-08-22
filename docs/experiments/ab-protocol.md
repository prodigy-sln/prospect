# A/B Protocol: Pipeline vs. Iterative Prompting

Bounds the ceremony premium on a real codebase. Not shipped to projects;
run it on a project with completed Prospect features and telemetry.

## Setup

- **Subject**: a completed feature with a clean issue description and a
  recorded per-phase cost (`metrics.md`, validation report).
- **Arm A (pipeline)**: the recorded run — tokens, wall-clock, phases.
- **Arm B (iterative)**: fresh worktree at the pre-feature commit, fresh
  session, the issue text only, plan mode allowed, same model, budget
  capped at Arm A's total. No spec machinery.

## Measures (same instruments for both arms)

1. Project gate (all stages) on the finished state.
2. Mutation sample over the arm's changed files — kill rate is the test
   quality metric.
3. Standing architecture checks + vendor-SDK confinement greps.
4. Blind review: fresh-context reviewer scores both diffs (correctness
   risks, maintainability) without knowing which arm is which.
5. Cost: output tokens, wall-clock, human interventions.

## Confounds — state them in every report

- Arm B free-rides on pipeline products: clean seams, test infrastructure,
  precise issue text. This biases toward Arm B.
- Judging Arm B against Arm A's own scenarios biases toward Arm A; use
  behavior probes derived from the issue text instead.
- n is small; results bound the premium for THIS codebase, nothing more.
