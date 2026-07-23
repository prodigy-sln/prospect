# Code Quality Standards (Constitution)

> Immutable. All generated code MUST comply. Violations require explicit
> justification and user approval.

## 1. Simplicity

- YAGNI: implement only what the spec requires. Delete speculative code.
  Add flexibility when a real need exists, never for hypotheticals.
- No abstraction before 3 concrete uses. Tolerate harmless duplication;
  wait for abstractions to prove stable.
- Use frameworks idiomatically and directly. Never wrap framework APIs
  "for flexibility" or build custom base classes over them.

```
// Premature: IRepository<T> → GenericRepository<T> → UserRepository
// Right:     class UserRepository { findById(id) {...}  save(user) {...} }
```

## 2. Organization

- Single responsibility: one reason to change per module, class, and
  function. Email sending does not belong in UserService.
- Hard size limits (split by responsibility when exceeded): components
  400 lines, services 500, utilities 200, test files 600.
- Functions: one thing, max 30 lines, max 4 parameters (use an object
  beyond that), max 2 nesting levels.

## 3. Naming

- Names reveal intent and are searchable. Class: PascalCase noun.
  Function: camelCase verb. Variable: camelCase noun. Constant:
  UPPER_SNAKE. Boolean: is/has/can prefix. File: kebab-case.
- Banned: generic names (data, info, temp, result, item), abbreviations
  (usr, cnt, msg), type-in-name (userObject, nameString).

## 4. Errors

- Never swallow errors, catch broad exceptions without re-throwing, or use
  errors for control flow.
- Handle at the right boundary: API layer transforms to HTTP responses,
  services raise business errors, repositories raise data errors.
- Messages are specific and actionable:
  `ValidationError('Email must be a valid email address', {field, value})`
  — never `Error('Invalid input')`.

## 5. Dependencies

- Direction flows inward: UI → services → domain → nothing. No circular
  dependencies; domain never depends on infrastructure.
- Before adding a package: actively maintained? widely used? could 20
  lines replace it? known vulnerabilities?
- Inject dependencies via constructor; never instantiate services inside
  consuming classes.

## 6. Comments

- Code self-documents WHAT. Comments exist only for WHY: non-obvious
  choices, gotchas, links to external docs, public API documentation.
- Never: comments restating the code, changelogs in code, commented-out
  code (delete it).

## 7. Security

- Validate all external input; sanitize before storage; encode output.
  Never trust client-side validation alone, concatenate SQL, or eval user
  input.
- Secrets live in env vars or a secret manager — never in code, logs, or
  error messages. Different secrets per environment.
- Authenticate at the edge, authorize every endpoint, use established
  crypto libraries only, audit security-sensitive operations.

## 8. Performance

- Make it work, make it right, make it fast — in that order. Measure
  before optimizing.
- Defaults: index frequently queried columns, paginate large results,
  cache expensive computations, no N+1 queries, async where blocking is
  avoidable.

## 9. Observability

- Structured logs (JSON) with correlation IDs. Levels: ERROR needs
  attention, WARN unexpected-but-handled, INFO business events, DEBUG off
  in production. No sensitive data in logs.
- Services expose request count and latency, error rates, and resource
  utilization.
