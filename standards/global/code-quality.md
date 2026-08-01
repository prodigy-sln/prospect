# Code Quality Standards (Constitution)

> Immutable. All generated code MUST comply. Violations require explicit
> justification and user approval.
>
> **Scope and precedence:** This document governs implementation, meaning
> the code that gets written. Design-time decisions (boundaries, ports,
> dependency structure, technology selection) are governed by
> `standards/global/architecture-principles.md`. Where the two appear to
> conflict, architecture-principles wins at design time and this document
> wins inside generated code. Never apply implementation rules (size
> limits, DRY heuristics, YAGNI) to invalidate a decision the
> architecture document has made.

## 1. Simplicity

- YAGNI governs **features and reuse-driven generalization**: implement
  only what the spec requires, delete speculative feature code, add
  flexibility when a real need exists.
- YAGNI does **NOT** govern boundary isolation. Isolating volatile
  external dependencies behind ports (architecture-principles, Boundary
  Isolation) is dependency-direction enforcement and risk management. It
  is never a YAGNI violation, regardless of how many providers exist or
  how many call sites use the dependency.
- No abstraction before 3 concrete uses. This rule targets DRY-driven
  generalization: generic repositories, custom base classes, "flexible"
  wrappers around your own code. It does not apply to ports at external
  boundaries, which are mandatory at first use.
- Tolerate harmless duplication; wait for abstractions to prove stable.
- Use the **application framework** (HTTP router, DI container, ORM entry
  points, frontend framework) idiomatically and directly. Never wrap it
  "for flexibility" or build custom base classes over it.
- **Third-party service SDKs are not frameworks.** Vendor SDKs (payment
  providers, LLM APIs, transcription services, mail services) fall under
  Boundary Isolation in architecture-principles and are accessed through
  ports, never imported directly outside their adapter.

```
// Premature: IRepository<T> -> GenericRepository<T> -> UserRepository
// Right:     class UserRepository { findById(id) {...}  save(user) {...} }

// Wrong:  import { ElevenLabsClient } from 'elevenlabs'  // in a service
// Right:  constructor(private transcription: TranscriptionPort) {}
//         // ElevenLabs SDK appears only inside adapters/elevenlabs/
```

## 2. Organization

- Single responsibility: one reason to change per module, class, and
  function. Email sending does not belong in UserService.
- Hard size limits (split by responsibility when exceeded): components
  400 lines, services 500, utilities 200, test files 600.
- Functions: one thing, max 30 lines, max 4 parameters (use an object
  beyond that), max 2 nesting levels.
- Size limits apply to code inside a design. They never justify changing
  the design itself (e.g. merging an adapter into a service to save a
  file).

## 3. Naming

- Names reveal intent and are searchable. Class: PascalCase noun.
  Function: camelCase verb. Variable: camelCase noun. Constant:
  UPPER_SNAKE. Boolean: is/has/can prefix. File: kebab-case.
- Ports are named after the **capability**, not the vendor:
  `TranscriptionPort`, not `ElevenLabsPort`. Adapters are named after
  vendor plus capability: `ElevenLabsTranscriptionAdapter`.
- Banned: generic names (data, info, temp, result, item), abbreviations
  (usr, cnt, msg), type-in-name (userObject, nameString).

## 4. Errors

- Never swallow errors, catch broad exceptions without re-throwing, or use
  errors for control flow.
- Handle at the right boundary: API layer transforms to HTTP responses,
  services raise business errors, repositories raise data errors,
  **adapters translate vendor errors into the port's error contract**.
  Vendor exception types never cross the adapter boundary.
- Messages are specific and actionable:
  `ValidationError('Email must be a valid email address', {field, value})`,
  never `Error('Invalid input')`.

## 5. Dependencies

- Direction flows inward: UI -> services -> domain -> nothing. No circular
  dependencies; domain never depends on infrastructure.
- The **mechanism** for keeping infrastructure out of the domain is the
  port-and-adapter rule in architecture-principles. "It is just a
  library" is not an exemption; the classification test there decides.
- Before adding a package: actively maintained? widely used? could 20
  lines replace it? known vulnerabilities?
- Inject dependencies via constructor; never instantiate services inside
  consuming classes. Ports are wired to adapters in the composition root
  only.

## 6. Comments

- Code self-documents WHAT. Comments exist only for WHY: non-obvious
  choices, gotchas, links to external docs, public API documentation.
- Never: comments restating the code, changelogs in code, commented-out
  code (delete it).

## 7. Security

- Validate all external input; sanitize before storage; encode output.
  Never trust client-side validation alone, concatenate SQL, or eval user
  input.
- Secrets live in env vars or a secret manager, never in code, logs, or
  error messages. Different secrets per environment. Vendor API keys are
  configured in the adapter's wiring only.
- Authenticate at the edge, authorize every endpoint, use established
  crypto libraries only, audit security-sensitive operations.

## 8. Performance

- Make it work, make it right, make it fast, in that order. Measure
  before optimizing.
- Defaults: index frequently queried columns, paginate large results,
  cache expensive computations, no N+1 queries, async where blocking is
  avoidable.

## 9. Observability

- Structured logs (JSON) with correlation IDs. Levels: ERROR needs
  attention, WARN unexpected-but-handled, INFO business events, DEBUG off
  in production. No sensitive data in logs.
- Services expose request count and latency, error rates, and resource
  utilization. Adapters additionally log vendor latency and vendor error
  rates so provider degradation is attributable.
