# Architecture Principles (Constitution)

> Immutable. Governs all design-time decisions: boundaries, dependency
> structure, technology selection, interface shape. At design time this
> document takes precedence over `code-quality.md`; implementation rules
> (size limits, DRY, YAGNI) must never be used to argue a boundary or
> port out of existence.

## 1. Decisions follow drivers, not habits

Every significant design decision must be traceable to an architectural
driver: a quality attribute, a constraint, or a risk that is real for
this system. General coding heuristics are not drivers.

- Quality attributes: latency, availability, cost, compliance,
  evolvability, operability. Name the ones that matter and the evidence.
- Constraints: regulatory (GDPR, sector rules), data sensitivity, team
  skills, budget, deadlines, contractual terms.
- Risks: vendor risk, irreversibility, integration fragility.

A decision justified only by "the guidelines say so" is unjustified.

## 2. Volatility classification

Every external dependency in a design must be classified before it is
integrated. Rate each on:

- **Vendor risk**: can pricing, terms, rate limits, or the vendor's
  existence change under us? Startups and single-product companies score
  high. **A sole provider is a risk amplifier, not an exemption**: no
  competition means no fallback and no negotiating position, which
  argues for MORE isolation, never less.
- **Regulatory exposure**: does data crossing this boundary carry
  compliance weight (personal data, voice, financial records, data
  residency)? Non-EU processors handling personal data score high.
- **API stability**: pre-1.0 SDKs, fast-moving AI vendors, and
  streaming/websocket protocols score high.
- **Substitutability**: how painful is a forced migration today?

High volatility on any axis mandates isolation per Section 3.

## 3. Boundary isolation (ports and adapters)

A dependency MUST be accessed through a port (an interface owned by the
domain or application layer, implemented by an adapter) when ANY of the
following holds:

- it crosses a process or network boundary (HTTP APIs, databases,
  queues, mail, external websockets)
- it is a third-party vendor that can change pricing, terms, behavior,
  or existence (payment, LLM, transcription, voice, mail providers)
- it is a source of nondeterminism (clock, random, environment)

A port is NOT required for:

- in-process pure libraries (validation, date math, lodash-class
  utilities) and the standard library
- the application framework itself (router, DI container, ORM entry
  points); repositories ARE the port for persistence, do not wrap the
  repository layer in a second port

Rules:

- Vendor SDK types never appear outside the adapter's directory. For
  very large vendor payloads (e.g. webhook events), a mapped DTO at the
  adapter edge is required; passing the raw vendor type through requires
  explicit user approval.
- Define the port when the FIRST adapter is built, not before. Never
  scaffold empty ports for dependencies the spec does not include.
- Shape the port around what the **domain needs**, not around the
  vendor's API. If the port's methods and events mirror the vendor SDK
  one-to-one, it is isolation theater and must be redesigned. For
  streaming integrations this means modeling session lifecycle, partial
  and final results, timing, language, error semantics, and backpressure
  in domain terms.
- Adapters translate vendor errors into the port's error contract.
- Litmus test, mechanically checkable: "If this vendor disappeared
  tomorrow, how many files change?" The answer must be one adapter
  directory plus composition-root wiring. Grep for the SDK's import path
  to verify.

## 4. Dependency direction

UI -> application -> domain -> nothing. Domain and application layers
depend on ports they own; adapters depend on ports and vendors; the
composition root wires them. No circular dependencies.

## 5. Binding vs. deferred decisions

- A decision is **binding** when reversing it later is expensive: it
  touches multiple modules, involves an external dependency, a data
  model, or a public contract. Binding decisions require documented
  options and trade-offs.
- A decision is **deferred** when it can be made later at similar cost.
  Defer it explicitly ("revisit when X is known") instead of guessing.
- Two-way doors get one line. One-way doors get analysis. Never spend
  the same effort on both.

## 6. Standing architecture, per-spec deltas

The project's architecture lives in one standing document
(`docs/architecture.md`, routed by `docs/INDEX.md`): module map, dependency
directions, ports registry, volatility table, project constants (stack,
gate flags, composition root). Specs declare only their **delta** — new
boundaries, dependencies, data models, public contracts. Design work
consumes the standing doc and never re-derives it; completed deltas merge
back at consolidation. An empty delta means no architecture phase runs.

## 7. Gate amendments are a project decision

`scripts/sdd-gate.*` changes only by an explicit project-level decision
with the user, inside a stated runtime budget — never as the deliverable of
a single spec. An invariant a spec introduces becomes a test; a check that
pays rent on every future change may be proposed for the gate, and the user
rules on it.

## 8. Unknowns block, assumptions are declared

If a driver material to a binding decision is unknown (data residency
requirements, expected load, cost ceiling, retention rules), the design
must stop and ask rather than guess. Assumptions are permitted only for
low-impact decisions and must be listed explicitly in the architecture
document so a reviewer can veto them.
