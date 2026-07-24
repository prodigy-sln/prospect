# Testing Standards (Constitution)

> Immutable. All generated code MUST comply. Violations require explicit
> justification and user approval.

## 1. Test-Driven Development

Every feature follows Red-Green-Refactor:

1. **RED** — a failing test derived from exactly one spec scenario. The
   scenario↔test mapping is recorded in the spec folder's `test-map.md`,
   never in test names or code. The failing output MUST be displayed
   before any implementation is written.
   Commit: `test: add failing tests for [behavior]`.
2. **GREEN** — minimal code to pass: no premature optimization, no
   "while I'm here" additions. Commit: `feat: implement [behavior]`.
3. **REFACTOR** — improve the task's own diff while tests stay green.
   Issues outside the diff are recorded as deferred observations, never
   fixed in passing. Commit only when something changed:
   `refactor: improve [component]`.

Test-first mandate: tests exist and fail before implementation begins.
Never write implementation before tests, write tests afterwards "for
coverage", or skip tests for "simple" code.

**Ownership and arbitration (rigor medium+):** a phase's tests are
authored by a test author that has not seen any implementation and owns
them for the whole phase. The implementation context never edits test
files. Disputed failures go to the test author, judged against the spec
scenario, with exactly one verdict: `test-correct` (implementation
conforms), `test-wrong` (author fixes and commits), or
`scenario-ambiguous` (user decides). At rigor `low`, tests and
implementation share one context; the displayed failing output is the
discipline gate.

Exceptions — test-first may be relaxed only for exploratory spikes (thrown
away or covered before merge), pure configuration, and generated code (the
generator is tested). Document every exception in the spec.

## 2. Test Quality

- Tests are independent (run in any order), repeatable, self-contained,
  and fast (unit <100ms, integration <1s).
- Names describe behavior — `[unit]_[scenario]_[expected]` or BDD
  `it('...')` — and never contain spec or scenario IDs.
- One logical assertion per test. Assert behavior, not implementation.
  Use specific assertions with failure messages where complex.
- Tests are living documentation: names state expected behavior, setup
  shows valid inputs, assertions show expected outputs.
- Organization: `tests/unit`, `tests/integration`, `tests/e2e`.

## 3. Coverage

- Minimums: business logic 90%, API endpoints 80%, UI components 70%,
  utilities 80%, overall 80%.
- 100% required: auth, payment and financial calculations, validation
  rules, security-sensitive operations.
- Exceptions only for third-party wrappers, framework boilerplate, and
  logging — configured in the coverage tool, never silently ignored.

## 4. Mocking

- Prefer real dependencies: test containers or in-memory DB, temp
  filesystem, test servers. Mock only unavailable or unreliable externals,
  specific failure scenarios, slow dependencies, and rate-limited APIs.
- Mock at boundaries and keep mocks simple — a complex mock signals a
  design problem.

## 5. Test Types

- **Unit**: no I/O, milliseconds — business logic, transformations,
  validation rules.
- **Integration**: component boundaries, database, API endpoints, auth
  flows — seconds.
- **E2E**: full system, critical user journeys only, 5–10 per feature
  maximum.

## 6. Test Data

- Minimal, obvious, set up per test. Values make intent clear
  (`invalidEmail = 'not-an-email'`) — no magic values. Use factories with
  sensible defaults for complex objects.

## 7. Continuous Integration

- Every PR: all tests pass, new functionality is tested, coverage
  thresholds met, lint clean. Never merge failing tests, disable tests to
  make CI pass, or skip a test without a tracked issue and deadline.
- Flaky tests are quarantined immediately and fixed within one sprint or
  deleted.
