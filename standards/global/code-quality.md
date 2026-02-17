# Code Quality Standards (Constitution)

> **This document is IMMUTABLE.** All generated code and AI-assisted development MUST comply with these standards. Violations require explicit justification and user approval.

## Article I: Simplicity First

### Section 1.1: YAGNI (You Aren't Gonna Need It)

```
:x: PROHIBITED: Implementing features "for later"
:x: PROHIBITED: Building abstractions before you have 3 concrete uses
:x: PROHIBITED: Adding configuration for hypothetical scenarios

:white_check_mark: REQUIRED: Implement only what the spec requires
:white_check_mark: REQUIRED: Add flexibility when a real need emerges
:white_check_mark: REQUIRED: Delete speculative code
```

### Section 1.2: Minimal Abstractions

Before creating an abstraction, ask:
1. Do I have at least 3 concrete uses? If no → don't abstract
2. Is the duplication actually harmful? If no → tolerate it
3. Will this abstraction be stable? If no → wait

```
// :x: BAD: Premature abstraction
interface IRepository<T> { ... }
class GenericRepository<T> implements IRepository<T> { ... }
class UserRepository extends GenericRepository<User> { ... }

// :white_check_mark: GOOD: Direct implementation (abstract when needed)
class UserRepository {
  findById(id: string): User { ... }
  save(user: User): void { ... }
}
```

### Section 1.3: Framework Trust

Use framework features directly:
```
:x: PROHIBITED: Wrapping framework APIs "for flexibility"
:x: PROHIBITED: Creating custom base classes for framework classes
:x: PROHIBITED: Abstracting away framework conventions

:white_check_mark: REQUIRED: Use framework idiomatically
:white_check_mark: REQUIRED: Trust framework stability
:white_check_mark: REQUIRED: Only wrap when you have a proven need
```

---

## Article II: Code Organization

### Section 2.1: Single Responsibility

Each module/class/function should have ONE reason to change.

```
// :x: BAD: Multiple responsibilities
class UserService {
  createUser(data) { ... }
  sendWelcomeEmail(user) { ... }  // Email is separate concern
  generateReport(users) { ... }   // Reporting is separate concern
}

// :white_check_mark: GOOD: Focused responsibilities
class UserService {
  createUser(data) { ... }
}
class EmailService {
  sendWelcomeEmail(user) { ... }
}
class UserReportService {
  generate(users) { ... }
}
```

### Section 2.2: File Size Limits

| File Type | Recommended Max | Hard Limit |
|-----------|----------------|------------|
| Component | 200 lines | 400 lines |
| Service | 300 lines | 500 lines |
| Utility | 100 lines | 200 lines |
| Test file | 400 lines | 600 lines |

When limits exceeded → split by responsibility

### Section 2.3: Function Size

```
Guidelines:
- Functions should do ONE thing
- Maximum 20-30 lines (excluding setup)
- Maximum 3-4 parameters (use object for more)
- Maximum 2 levels of nesting

When exceeded → extract helper functions
```

---

## Article III: Naming

### Section 3.1: Naming Principles

```
:white_check_mark: Names reveal intent
:white_check_mark: Names are pronounceable
:white_check_mark: Names are searchable
:white_check_mark: Names avoid encodings (no Hungarian notation)
```

### Section 3.2: Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Class | PascalCase, noun | `UserService`, `OrderRepository` |
| Function | camelCase, verb | `createUser()`, `calculateTotal()` |
| Variable | camelCase, noun | `userCount`, `isValid` |
| Constant | UPPER_SNAKE | `MAX_RETRIES`, `API_BASE_URL` |
| Boolean | is/has/can prefix | `isActive`, `hasPermission` |
| File | kebab-case | `user-service.ts`, `order-utils.ts` |

### Section 3.3: Naming Anti-Patterns

```
:x: BAD: Generic names
data, info, temp, result, value, item, element

:x: BAD: Abbreviations
usr, cnt, btn, msg, calc

:x: BAD: Type-in-name
userObject, nameString, itemList

:white_check_mark: GOOD: Specific, meaningful names
userData → user, customerProfile
itemCount → orderLineCount
processData → calculateOrderTotal
```

---

## Article IV: Error Handling

### Section 4.1: Explicit Error Handling

```
:x: PROHIBITED: Swallowing errors silently
:x: PROHIBITED: Catching generic Exception without re-throwing
:x: PROHIBITED: Using errors for control flow

:white_check_mark: REQUIRED: Handle errors at appropriate boundaries
:white_check_mark: REQUIRED: Log errors with context
:white_check_mark: REQUIRED: Propagate errors users need to know about
```

### Section 4.2: Error Messages

```
// :x: BAD: Generic messages
throw new Error('Invalid input')
throw new Error('Something went wrong')

// :white_check_mark: GOOD: Specific, actionable messages
throw new ValidationError('Email must be a valid email address', { field: 'email', value: input.email })
throw new NotFoundError(`User with ID ${userId} not found`)
```

### Section 4.3: Error Boundaries

Handle errors at the right level:
```
┌─────────────────────────────────────────────┐
│ API Layer: Transform to HTTP responses      │
│   └── Service Layer: Business logic errors  │
│       └── Repository: Data access errors    │
│           └── External: Third-party errors  │
└─────────────────────────────────────────────┘
```

---

## Article V: Dependencies

### Section 5.1: Dependency Direction

```
Dependencies flow inward:
  UI → Services → Domain → (nothing)

:x: PROHIBITED: Domain depending on infrastructure
:x: PROHIBITED: Services depending on UI
:x: PROHIBITED: Circular dependencies
```

### Section 5.2: External Dependencies

Before adding a dependency:
1. Is it actively maintained? (commits in last 6 months)
2. Is it widely used? (community validation)
3. Is it necessary? (can we write 20 lines instead?)
4. What's the security posture? (known vulnerabilities)

### Section 5.3: Dependency Injection

```
// :x: BAD: Hard-coded dependencies
class OrderService {
  private userRepo = new UserRepository()
  private emailService = new EmailService()
}

// :white_check_mark: GOOD: Injected dependencies
class OrderService {
  constructor(
    private userRepo: UserRepository,
    private emailService: EmailService
  ) {}
}
```

---

## Article VI: Code Comments

### Section 6.1: Comment Philosophy

```
Code should be self-documenting.
Comments explain WHY, not WHAT.
```

### Section 6.2: When to Comment

```
:white_check_mark: COMMENT: Why a non-obvious approach was chosen
:white_check_mark: COMMENT: Warnings about edge cases or gotchas
:white_check_mark: COMMENT: References to external documentation/issues
:white_check_mark: COMMENT: Public API documentation

:x: DON'T COMMENT: What the code does (it should be obvious)
:x: DON'T COMMENT: Changelog in code (use git)
:x: DON'T COMMENT: Commented-out code (delete it)
```

### Section 6.3: Examples

```
// :x: BAD: Obvious comment
// Increment counter by 1
counter++

// :x: BAD: Commented-out code
// function oldImplementation() { ... }

// :white_check_mark: GOOD: Explains why
// Using insertion sort for small arrays (<10 items) because
// it outperforms quicksort due to lower overhead. See benchmark: #123
if (items.length < 10) {
  return insertionSort(items)
}

// :white_check_mark: GOOD: Warning
// CAUTION: This function is not thread-safe.
// Caller must hold lock when modifying shared state.
```

---

## Article VII: Security

### Section 7.1: Input Validation

```
:white_check_mark: REQUIRED: Validate all external input
:white_check_mark: REQUIRED: Sanitize data before storage
:white_check_mark: REQUIRED: Encode output appropriately

:x: PROHIBITED: Trusting client-side validation alone
:x: PROHIBITED: SQL string concatenation
:x: PROHIBITED: Eval() with user input
```

### Section 7.2: Secrets Management

```
:x: PROHIBITED: Secrets in source code
:x: PROHIBITED: Secrets in logs
:x: PROHIBITED: Secrets in error messages

:white_check_mark: REQUIRED: Use environment variables or secret manager
:white_check_mark: REQUIRED: Rotate secrets regularly
:white_check_mark: REQUIRED: Different secrets per environment
```

### Section 7.3: Authentication & Authorization

```
:white_check_mark: REQUIRED: Authenticate at the edge
:white_check_mark: REQUIRED: Authorize at every endpoint
:white_check_mark: REQUIRED: Use established libraries (no custom crypto)
:white_check_mark: REQUIRED: Audit security-sensitive operations
```

---

## Article VIII: Performance

### Section 8.1: Performance Philosophy

```
1. Make it work
2. Make it right
3. Make it fast (only if needed)

:x: PROHIBITED: Premature optimization
:white_check_mark: REQUIRED: Measure before optimizing
:white_check_mark: REQUIRED: Document performance requirements in spec
```

### Section 8.2: Known Performance Patterns

```
:white_check_mark: DO: Use indexes for frequently queried columns
:white_check_mark: DO: Paginate large result sets
:white_check_mark: DO: Cache expensive computations
:white_check_mark: DO: Use appropriate data structures

:x: DON'T: N+1 queries
:x: DON'T: Loading unnecessary data
:x: DON'T: Synchronous operations that can be async
```

---

## Article IX: Observability

### Section 9.1: Logging Standards

```
Log Levels:
- ERROR: Something failed, needs attention
- WARN: Something unexpected, but handled
- INFO: Significant business events
- DEBUG: Detailed diagnostic info (off in production)

:white_check_mark: REQUIRED: Structured logging (JSON)
:white_check_mark: REQUIRED: Correlation IDs for request tracing
:white_check_mark: REQUIRED: No sensitive data in logs
```

### Section 9.2: Metrics

```
Every service should expose:
- Request count and latency
- Error rates
- Resource utilization
- Business-relevant metrics
```

---

## Amendment Log

| Date | Section | Change | Rationale |
|------|---------|--------|-----------|
| [Initial] | All | Initial version | Establish quality baseline |

---

> **Compliance Verification**: Run `/sdd.validate` to verify implementation matches these standards.
