# MUST-follow rules for agents (language-agnostic)

These rules apply to every change in every codebase, regardless of language or framework.

- Choose the simplest implementation that fully meets the current requirements. Do not build beyond what is asked.
- Prefer established, well-maintained libraries over custom implementations.
- Avoid premature abstraction: prefer simple, concrete solutions until real patterns emerge.
- Prefer composition over centralization: prefer small, focused modules with explicit interfaces over centralized systems.
- Keep responsibilities clear: keep modules focused and do not mix unrelated concerns (transport, orchestration, state, persistence, infrastructure).
- Keep dependencies pointing inward: higher layers may depend on lower ones, never the reverse.
- Propagate errors with context; preserve the original error so callers can still identify and handle it.
- Never skip verification: never bypass required checks, tests, or quality gates.
- Make architectural decisions for the long term, not as a stopgap that only works now and gets replaced later.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Study how established products solve the problem before designing a solution. Adopt their proven patterns and conventions rather than inventing an approach from scratch.
- Follow the existing code style, naming conventions, and directory layout of the current repository.

# Agent Instructions: Domain-Driven Design (DDD)

## Core Principles

1. **The Domain is Pure:** The domain/core layer MUST NOT import frameworks, ORMs, HTTP libraries, or third-party drivers — only the domain's own types and zero-dep utilities.
2. **Accept Interfaces, Return Structs:** Depend on abstractions where consumed, but return concrete types from constructor/factory functions.
3. **Ubiquitous Language:** Module names, type names, and errors must map 1:1 to real-world business concepts.
4. **Boundary Violations are Fatal:** Never import infrastructure or presentation code into the domain or application layers.

## Repository Directory Structure

```text
src/ or internal/
├── domain/            # PURE DOMAIN: entities, value objects, aggregates,
│                      # domain events, services, sentinel errors, repository interfaces
├── application/       # USE CASES: command/query handlers, DTOs, application interfaces
├── infrastructure/    # ADAPTERS: persistence, messaging, third-party APIs
└── interface/         # PRESENTATION: HTTP/gRPC handlers, CLI commands
```

## Architectural Layering

### 1. Domain Layer

Contains: Entities, Value Objects, Aggregates, Domain Events, Domain Services, Sentinel Errors, Repository Interfaces.

Rules:
- Encapsulate internal state; expose mutations only through explicit domain methods.
- Constructors validate invariants and return explicit domain errors.
- Return domain sentinel errors (e.g., `ErrInsufficientFunds`), never database or framework errors.
- Domain Services hold logic that spans multiple aggregates or fits no single entity. Application handlers orchestrate; they never contain business rules.

### 2. Application Layer

Contains: Use Case Handlers (Commands/Queries), DTOs, Application Interfaces (e.g., UnitOfWork).

Rules:
- Accept and return primitives or primitive-based DTOs. Never leak domain entities to the presentation layer.
- Handle cross-cutting concerns: transactions, logging, metrics, dispatching domain events.
- Each use case loads and mutates exactly one aggregate root; a transaction commits one aggregate.

### 3. Infrastructure Layer

Contains: Repositories, Third-Party API Adapters, Message Brokers.

Rules:
- Implement the repository interfaces defined by the consumer (application or domain); never define new abstractions here.
- Use dedicated persistence models distinct from domain entities, mapped explicitly (never persistence annotations on domain types).

### 4. Interface / Presentation Layer

Contains: HTTP, gRPC, or CLI handlers.

Rules:
- Validate inputs and convert them into application commands/DTOs.
- Map domain/application errors to appropriate protocol status codes (e.g., `NotFound` → HTTP 404).

## Anti-Patterns (Refuse to generate these)

- **Leaky Domain Types:** Public mutable fields on domain types that allow state changes without invariant checks.
- **Persistence Annotations on Domain Types:** ORM/column annotations (e.g., `gorm:"primaryKey"`, `db:"account_id"`) applied directly to domain entities.
- **Global State & Singletons:** Storing connections or configuration in module-level state or `init()` routines instead of passing them via constructors.
- **Dropped Context:** Omitting context/request parameters from repository or application service signatures (where the language provides them).
- **Mutable Pointers to Value Objects:** Passing immutable value objects as pointers where value semantics are expected.

## Testing Instructions

- Unit-test domain logic directly — no mocks; call domain methods and assert on returned state or errors.
- Test use cases with simple in-memory fakes implementing the interfaces.
- Prefer table-driven tests for invariant edges and factory functions.

Language-specific conventions (e.g., Go `internal/` layout, constructor idioms) are documented per project, not here.
