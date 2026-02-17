# Testing Standards (Constitution)

> **This document is IMMUTABLE.** All generated code and AI-assisted development MUST comply with these standards. Violations require explicit justification and user approval.

## Article I: Test-Driven Development (TDD)

### Section 1.1: The TDD Cycle

All feature implementation MUST follow Red-Green-Refactor:

1. **RED** — Write a failing test first
   - Test defines expected behavior
   - Test MUST fail before any implementation
   - Commit: `test: add failing test for [behavior]`

2. **GREEN** — Write minimal code to pass the test
   - Only implement what's needed to pass
   - No premature optimization
   - No gold-plating or "while I'm here" additions
   - Commit: `feat: implement [behavior] to pass test`

3. **REFACTOR** — Improve code while keeping tests green
   - Clean up duplication
   - Improve naming and structure
   - Extract methods/classes as needed
   - Tests MUST still pass after refactoring
   - Commit: `refactor: improve [component] structure`

### Section 1.2: Test-First Mandate

```
:x: PROHIBITED: Writing implementation before tests
:x: PROHIBITED: Writing tests after implementation "to get coverage"
:x: PROHIBITED: Skipping tests for "simple" code
:white_check_mark: REQUIRED: Tests exist and fail before implementation begins
```

### Section 1.3: Exceptions

Test-first MAY be relaxed ONLY for:
- Exploratory spikes (must be thrown away or test-covered before merge)
- Pure configuration files (no logic)
- Generated code (generators must be tested)

All exceptions MUST be documented in the spec.

---

## Article II: Test Quality

### Section 2.1: Test Independence

Each test MUST be:
- **Independent**: Can run in any order
- **Repeatable**: Same result every time
- **Self-contained**: No shared mutable state between tests
- **Fast**: Unit tests < 100ms, integration tests < 1s

### Section 2.2: Test Naming

Tests MUST have descriptive names following pattern:

```
// Pattern: [unit]_[scenario]_[expected]

// Examples:
test_user_login_with_valid_credentials_returns_token()
test_user_login_with_invalid_password_returns_401()
test_order_total_with_discount_calculates_correctly()

// Or BDD style:
describe('UserService.login')
  it('returns token when credentials are valid')
  it('returns 401 when password is invalid')
  it('locks account after 5 failed attempts')
```

### Section 2.3: Assertion Guidelines

- **One logical assertion per test** (multiple asserts OK if testing one concept)
- **Assert behavior, not implementation**
- **Use specific assertions** (assertEquals, not assertTrue(a == b))
- **Include failure messages** for complex assertions

```
// :x: BAD: Testing implementation
expect(user._passwordHash).toBeDefined()

// :white_check_mark: GOOD: Testing behavior
expect(user.verifyPassword('correct')).toBe(true)
expect(user.verifyPassword('wrong')).toBe(false)
```

### Section 2.4: Test Organization

```
tests/
├── unit/           # Isolated component tests
│   ├── models/
│   ├── services/
│   └── utils/
├── integration/    # Component interaction tests
│   ├── api/
│   └── db/
└── e2e/           # Full user journey tests
```

---

## Article III: Test Coverage

### Section 3.1: Coverage Requirements

| Category | Minimum Coverage |
|----------|-----------------|
| Business logic (services) | 90% |
| API endpoints | 80% |
| UI components | 70% |
| Utilities | 80% |
| Overall project | 80% |

### Section 3.2: Critical Path Coverage

The following MUST have 100% coverage:
- Authentication/authorization logic
- Payment/financial calculations
- Data validation rules
- Security-sensitive operations

### Section 3.3: Coverage Exceptions

Coverage MAY be reduced ONLY for:
- Third-party library wrappers (test the wrapper behavior, not the library)
- Framework boilerplate
- Logging statements

Exceptions MUST be explicitly configured in coverage tool, not ignored.

---

## Article IV: Mocking & Test Doubles

### Section 4.1: Prefer Real Dependencies

```
:white_check_mark: PREFER: Real database (test container or in-memory)
:white_check_mark: PREFER: Real file system (temp directory)
:white_check_mark: PREFER: Real HTTP calls (to test server or recorded responses)

:x: AVOID: Mocking everything
:x: AVOID: Mocks that replicate implementation details
```

### Section 4.2: When to Mock

Mock ONLY when:
- External service is unavailable/unreliable in tests
- Testing specific failure scenarios
- Isolating unit under test from slow dependencies
- Third-party APIs with rate limits or costs

### Section 4.3: Mock Quality

When mocking is necessary:
- Mock at the boundary (interface), not internals
- Verify mock interactions when behavior depends on calls
- Keep mocks simple — complex mocks indicate design problems

---

## Article V: Test Types

### Section 5.1: Unit Tests

**Purpose**: Verify individual components in isolation

```
Characteristics:
- No I/O (database, network, file system)
- No external dependencies
- Milliseconds to run
- Test one unit of behavior

When to write:
- Business logic
- Data transformations
- Validation rules
- Utility functions
```

### Section 5.2: Integration Tests

**Purpose**: Verify components work together

```
Characteristics:
- May include database, file system
- Test component boundaries
- Seconds to run
- Test realistic scenarios

When to write:
- API endpoint behavior
- Database operations
- Service-to-service communication
- Authentication flows
```

### Section 5.3: End-to-End Tests

**Purpose**: Verify complete user journeys

```
Characteristics:
- Full system running
- Test user-visible behavior
- May take 10+ seconds
- Test critical paths only

When to write:
- Primary user journeys
- Critical business flows
- Regression prevention for bugs

Limit:
- 5-10 E2E tests per feature maximum
- E2E tests are expensive; prefer unit/integration
```

---

## Article VI: Test Data

### Section 6.1: Test Data Principles

- **Minimal**: Use only data needed for the test
- **Obvious**: Data values should make test intent clear
- **Independent**: Each test sets up its own data

### Section 6.2: Test Data Patterns

```
// :white_check_mark: GOOD: Clear intent
const validUser = { email: 'valid@example.com', password: 'ValidPass123!' }
const invalidEmail = { email: 'not-an-email', password: 'ValidPass123!' }

// :x: BAD: Magic values
const user = { email: 'test@test.com', password: 'abc123' }
```

### Section 6.3: Factories & Builders

For complex objects, use factories:

```
// Factory with sensible defaults
const userFactory = (overrides = {}) => ({
  id: generateId(),
  email: 'user@example.com',
  name: 'Test User',
  role: 'member',
  ...overrides
})

// Usage
const admin = userFactory({ role: 'admin' })
const customUser = userFactory({ email: 'custom@example.com' })
```

---

## Article VII: Continuous Integration

### Section 7.1: CI Requirements

Every pull request MUST:
- [ ] Pass all existing tests
- [ ] Include tests for new functionality
- [ ] Meet coverage thresholds
- [ ] Pass linting checks

### Section 7.2: Test Failure Policy

```
:x: PROHIBITED: Merging with failing tests
:x: PROHIBITED: Disabling tests to make CI pass
:x: PROHIBITED: @skip/@ignore without linked issue

:white_check_mark: REQUIRED: Fix the test or fix the code
:white_check_mark: REQUIRED: Skipped tests have tracking issue with deadline
```

### Section 7.3: Flaky Test Policy

Tests that fail intermittently:
1. Immediately quarantine (move to separate suite)
2. Create tracking issue
3. Fix within 1 sprint or delete
4. Never ignore flakiness

---

## Article VIII: Documentation

### Section 8.1: Test as Documentation

Tests serve as living documentation:
- Test names describe expected behavior
- Test setup shows valid inputs
- Test assertions show expected outputs

### Section 8.2: Complex Test Documentation

For complex test scenarios, add comments:

```
/**
 * Verifies that order total applies:
 * 1. Item discounts first (per-item)
 * 2. Order-level discount second (on subtotal)
 * 3. Tax last (on discounted total)
 *
 * Regression test for BUG-123
 */
test_order_total_applies_discounts_in_correct_order()
```

---

## Amendment Log

| Date | Section | Change | Rationale |
|------|---------|--------|-----------|
| [Initial] | All | Initial version | Establish TDD baseline |

---

> **Compliance Verification**: Run `/sdd.validate` to verify implementation matches these standards.
