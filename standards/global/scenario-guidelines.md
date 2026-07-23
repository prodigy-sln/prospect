# Scenario Guidelines

Acceptance scenarios are the test contract: each scenario becomes exactly
one test, named with the scenario ID (e.g. `FR-2.1-S1`). Write scenarios so
a test can be derived from them mechanically.

## Format

Prefer EARS; Given/When/Then is acceptable.

| Pattern | Form | Use for |
|---------|------|---------|
| Event | WHEN [trigger] THE SYSTEM SHALL [outcome] | responses to actions and events |
| Unwanted | IF [error condition] THEN THE SYSTEM SHALL [outcome] | failures, invalid input, limits |
| State | WHILE [state] THE SYSTEM SHALL [outcome] | state-dependent behavior |
| Optional | WHERE [feature is enabled] THE SYSTEM SHALL [outcome] | configurable behavior |
| Ubiquitous | THE SYSTEM SHALL [outcome] | invariants |

## Rules

1. One behavior per scenario. Two SHALL clauses = two scenarios.
2. Outcomes must be observable by the caller or user. "Works correctly" and
   "handles gracefully" are not outcomes.
3. Use concrete values, especially at boundaries ("0 items", "31 characters",
   "expired token") — never placeholders.
4. Every requirement has at least one unwanted-behavior scenario. A
   requirement with only happy paths is incomplete.
5. State the trigger precisely: who or what initiates, with which input, in
   which starting state.
6. No UI mechanics unless the requirement is about UI ("submits the form",
   not "clicks the blue button").
7. Features with UI surface: empty, loading, and error states each get a
   scenario.
8. Stay implementation-free: name behavior and contracts, never classes,
   functions, or storage details.

## Examples

Good: `WHEN a user submits a registration with an already-registered email
THE SYSTEM SHALL reject it and name the conflicting field in the response`

Bad: `WHEN registration fails THE SYSTEM SHALL handle the error`
(vague trigger, unobservable outcome)
