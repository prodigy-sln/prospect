# Validation Calibration

These rules govern severity, evidence, volume, and skip decisions for this
repository. Apply them exactly.

## Severity

- **Blocker**: breaks a primary user path, loses or corrupts data, or opens
  an auth-bypass, injection, or credential-exposure vulnerability.
- **Major**: produces wrong results, violates an acceptance scenario, fails
  silently, or omits spec-mandated behavior.
- **Minor**: unhandled spec edge case off the primary path, or a misleading
  error message — objectively verifiable defects two developers would agree
  on.
- **Info**: everything subjective. Style preferences are Info, never Minor.

## Evidence bar

Every finding MUST include a `file:line` citation and a concrete failure
scenario (inputs/state → wrong observable outcome). Findings missing either
are discarded. Cite code you read, never infer behavior from names.

## Volume

Report at most 5 Minors; summarize the remainder as a count. When nothing
blocks, lead the summary with "no blocking issues".

## Skip

- Generated code, lockfiles, vendored dependencies
- Anything CI already enforces (formatting, lint rules, type errors)

## Re-review

On a second validation pass, report only NEW findings of severity Major or
higher.
