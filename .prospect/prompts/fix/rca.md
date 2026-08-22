## Root cause analysis (append to spec.md as `## RCA`)

- **Causal chain**: symptom → failing mechanism → origin (the change or
  assumption that introduced it), each link cited (`file:line` or commit).
- **Detection gap**: why the gate and existing tests did not catch this.
  Name the instrument hole precisely — a missing test, a coverage
  exclusion, an assertion too weak to bite.
- **Sibling sweep**: search the codebase for the same defect pattern.
  In-scope siblings join this fix's regression scenarios; out-of-scope ones
  become tracked issues, never drive-by fixes.
- **Prevention**: the test or deterministic check that would have caught
  this class. A per-defect check becomes a regression test here; a
  project-wide check is proposed to the user under the gate policy — never
  added to the gate by this spec.
