# Scenario Guidelines

Acceptance scenarios are the test contract: each is the floor of at least
one test — more when distinct code paths or boundaries need their own
falsifier. Write scenarios so tests derive from them mechanically.
Scenarios are a budget, not a score: merge variants exercising the same
behavior path into one parameterized scenario; past ~40 the user confirms
every addition.

Tests carry no spec references: test names describe behavior ("rejects an
expired token with 410"), and the scenario↔test mapping lives in the spec
folder's `test-map.md`, written and maintained by the test author.
Long-term provenance runs through consolidated docs and git history, never
through IDs in code.

## Format

**EARS for FR-level scenarios** — the one-line form resists vague outcomes
and multi-behavior drift. **Given/When/Then for E2E journeys** — multi-step
flows with rich preconditions; each THEN asserts one observable outcome.

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
