# A *MUST* following rules for agents

- Choose the simplest implementation that fully meets the current requirements.
- Prefer established, well-maintained libraries over custom implementations.
- Avoid premature abstraction: prefer simple concrete solutions until real patterns emerge.
- Prefer composition over centralization: use small focused modules with explicit interfaces instead of centralized systems.
- Keep responsibilities clear: keep modules focused and avoid mixing transport, orchestration, domain/workflow state, persistence, and infrastructure.
- Keep module dependencies pointing inward: interface → application → domain. Never let a lower layer depend on a higher one.
- Error propagation: wrap errors with `fmt.Errorf("context: %w", err)` and only return sentinel errors unwrapped at the domain boundary.
- Never skip verification: do not bypass required checks, tests, or quality gates.
- Make architectural decisions for the long term.
  Do not accept a stopgap that only works for now
  and is meant to be replaced later.
- Lean on the dependencies already in the project before
  writing your own implementation or adding packages. Do
  not assume a library lacks a capability without
  checking its documentation and types.
- Study how established products solve the problem
  before designing a solution. Adopt their proven
  patterns and conventions rather than inventing
  an approach from scratch.

# Agent Instructions: Domain-Driven Design (DDD) for Go

## Core Principles & Philosophy
This repository strictly adheres to **Domain-Driven Design (DDD)** and **Clean / Hexagonal Architecture** in idiomatic Go. 
All code generated or modified must preserve explicit boundaries between the Domain, Application, Infrastructure, and Interface (Presentation) layers.

1. **The Domain is Pure Go:** The `domain` package MUST NOT import external frameworks, ORMs, HTTP libraries, or third-party drivers (standard library only, except for zero-dep utilities like `google/uuid` if required).
2. **Accept Interfaces, Return Structs:** Depend on abstractions (interfaces) where consumed, but return concrete structs from constructor/factory functions.
3. **Ubiquitous Language:** Package names, type names, exported methods, and domain errors must map 1:1 to real-world business domain concepts.
4. **Explicit Boundary Violations are Fatal:** Never import `infrastructure` or `interface` code into `domain` or `application`.

---

## Repository Directory Structure

```text
pkg/ or internal/
├── domain/                      # PURE DOMAIN LAYER
│   ├── account/                 # Bounded Context / Aggregate
│   │   ├── account.go           # Aggregate Root struct & invariants
│   │   ├── id.go                # Strongly typed ID (Value Object)
│   │   ├── money.go             # Value Object
│   │   ├── events.go            # Domain Events
│   │   ├── errors.go            # Domain Sentinel Errors
│   │   └── repository.go        # Repository Interface (defined where used/needed)
├── application/                 # APPLICATION / USE CASE LAYER
│   ├── account/
│   │   ├── transfer_money.go    # Command / Use Case handler
│   │   ├── dtos.go              # Input/Output Data Transfer Objects
│   │   └── services.go          # Application Services
├── infrastructure/              # INFRASTRUCTURE LAYER
│   ├── persistence/
│   │   ├── postgres/            # Database implementations
│   │   │   ├── account_repo.go  # Implements domain.AccountRepository
│   │   │   └── mapper.go        # Maps DB models <-> Domain Entities
│   └── messaging/               # Event bus implementations (Kafka, RabbitMQ)
└── interface/                   # PRESENTATION / ADAPTER LAYER
    ├── http/                    # Gin, Echo, or net/http handlers
    └── grpc/                    # gRPC handlers/protos
```

## Architectural Layering Rules

1. **Domain Layer** *(internal/domain/...)*

Contains: Entities, Value Objects, Aggregates, Domain Events, Domain Services, Sentinel Errors, and Repository Interfaces.

*Rules:*

Encapsulate internal state: Keep fields unexported (lowercase) to enforce aggregate boundaries. Expose mutations only through explicit domain methods.
Factories/Constructors (NewAccount(...)) must validate invariants and return explicit domain errors.
Return Domain Sentinel Errors (e.g., ErrInsufficientFunds), not database or framework errors.

2. **Application Layer** *(internal/application/...)*

Contains: Use Case Handlers (Commands/Queries), DTOs, Application Interfaces (e.g., UnitOfWork).

*Rules:*

Accepts and returns primitive values or primitive-based DTO structs. Never leak domain entities to the HTTP/gRPC interface layer.
Handles cross-cutting concerns: Transaction boundaries, logging, metrics, dispatching domain events.

3. **Infrastructure Layer** *(internal/infrastructure/...)*

Contains: Database Repositories (pgx, gorm, sqlx), Third-Party API Adapters, Message Brokers.

*Rules:*

Implements the repository interfaces defined by the Domain or Application layers.
Must use dedicated Database Data Models (SQL structs) distinct from Domain Entities, mapped explicitly using mapper functions.

4. **Interface / Presentation Layer** *(internal/interface/...)*

Contains: HTTP Handlers (Gin, Echo, Standard Library), gRPC Handlers, CLI Commands.

*Rules:*

Validates request payloads (JSON binding/struct validation) and converts primitives into Application Commands/DTOs.
Maps domain/application errors into appropriate protocol status codes (e.g., ErrNotFound -> HTTP 404).

## Code Generation Guidelines for Go

1. **Value Objects in Go**

Value Objects must be immutable, validate their parameters upon creation, and compare by value:

```go
package account

import (
	"errors"
	"fmt"
)

var ErrInvalidAmount = errors.New("amount must be non-negative")

// Money is an immutable Value Object.
type Money struct {
	amount   int64  // in cents/lowest denomination
	currency string
}

// NewMoney acts as the constructor and enforces invariants.
func NewMoney(amount int64, currency string) (Money, error) {
	if amount < 0 {
		return Money{}, ErrInvalidAmount
	}
	if currency == "" {
		return Money{}, errors.New("currency cannot be empty")
	}
	return Money{amount: amount, currency: currency}, nil
}

func (m Money) Amount() int64    { return m.amount }
func (m Money) Currency() string { return m.currency }

func (m Money) Add(other Money) (Money, error) {
	if m.currency != other.currency {
		return Money{}, fmt.Errorf("currency mismatch: %s vs %s", m.currency, other.currency)
	}
	return NewMoney(m.amount+other.amount, m.currency)
}
```

2. **Rich Aggregate Root in Go**

Keep struct fields unexported to force callers to use domain methods that enforce business invariants:

```go
package account

import (
	"errors"
	"time"
)

var (
	ErrAccountIsClosed   = errors.New("account is closed")
	ErrInsufficientBalance = errors.New("insufficient balance for transaction")
)

// Account is an Aggregate Root.
type Account struct {
	id        ID
	balance   Money
	isClosed  bool
	updatedAt time.Time
	events    []DomainEvent
}

// NewAccount initializes an Account aggregate ensuring initial invariants.
func NewAccount(id ID, initialDeposit Money) (*Account, error) {
	acc := &Account{
		id:        id,
		balance:   initialDeposit,
		isClosed:  false,
		updatedAt: time.Now().UTC(),
	}
	
	acc.recordEvent(AccountOpenedEvent{
		AccountID: id.String(),
		Deposit:   initialDeposit.Amount(),
	})

	return acc, nil
}

// Withdraw encapsulates logic, protects invariants, and emits events.
func (a *Account) Withdraw(amount Money) error {
	if a.isClosed {
		return ErrAccountIsClosed
	}

	if a.balance.Amount() < amount.Amount() {
		return ErrInsufficientBalance
	}

	newBalance, err := NewMoney(a.balance.Amount()-amount.Amount(), amount.Currency())
	if err != nil {
		return err
	}

	a.balance = newBalance
	a.updatedAt = time.Now().UTC()

	a.recordEvent(MoneyWithdrawnEvent{
		AccountID: a.id.String(),
		Amount:    amount.Amount(),
	})

	return nil
}

func (a *Account) recordEvent(e DomainEvent) {
	a.events = append(a.events, e)
}

func (a *Account) CollectEvents() []DomainEvent {
	events := a.events
	a.events = nil // clear after collecting
	return events
}
```

3. **Application Use Case & Repository Interface**

Define the repository interface inside the domain or application package based on usage, and orchestrate logic within application handlers:

```go
package application

import (
	"context"
	"fmt"

	"myproject/internal/domain/account"
)

// Repository interface defined where consumed.
type AccountRepository interface {
	FindByID(ctx context.Context, id account.ID) (*account.Account, error)
	Save(ctx context.Context, acc *account.Account) error
}

type WithdrawCommand struct {
	AccountID string
	Amount    int64
	Currency  string
}

type WithdrawUseCase struct {
	repo AccountRepository
}

func NewWithdrawUseCase(repo AccountRepository) *WithdrawUseCase {
	return &WithdrawUseCase{repo: repo}
}

func (uc *WithdrawUseCase) Execute(ctx context.Context, cmd WithdrawCommand) error {
	accID, err := account.ParseID(cmd.AccountID)
	if err != nil {
		return fmt.Errorf("invalid account ID: %w", err)
	}

	amount, err := account.NewMoney(cmd.Amount, cmd.Currency)
	if err != nil {
		return fmt.Errorf("invalid withdrawal amount: %w", err)
	}

	acc, err := uc.repo.FindByID(ctx, accID)
	if err != nil {
		return fmt.Errorf("failed to fetch account: %w", err)
	}

	// Domain logic call
	if err := acc.Withdraw(amount); err != nil {
		return err // Return raw domain sentinel error so HTTP layer can map status codes
	}

	if err := uc.repo.Save(ctx, acc); err != nil {
		return fmt.Errorf("failed to persist account: %w", err)
	}

	return nil
}
```

## Go-Specific Anti-Patterns (Refuse to generate these)

❌ Exported Aggregate Fields: Creating Aggregate structs with all public fields (e.g., type Account struct { Balance int64 }) allowing direct state manipulation without invariant checks.

❌ GORM/SQL Tags on Domain Structs: Adding struct tags like gorm:"primaryKey" or db:"account_id" directly on domain entities.

❌ Global State & Package Singletons: Storing DB connections or configurations in package init() functions or global variables instead of passing them via constructor functions.

❌ Ignoring Context: Omitting ctx context.Context from Repository or Application Service method signatures.

❌ Passing Pointers to Value Objects: Passing immutable Value Objects as pointers (*Money) rather than values (Money), which encourages unintended mutability.

## Go Testing Instructions for Agents

1. **Unit Testing Domain Logic (*_test.go):**

    - Write pure unit tests for Aggregates and Value Objects.

    - Do NOT use mocks for domain layer tests; execute aggregate methods directly and assert on returned state or errors.

2. **Application Layer Testing:**

    - Test Use Cases using simple in-memory mock/fake structs implementing domain interfaces (e.g., type memoryAccountRepo struct).

3. **Table-Driven Tests:**

    - Standardize on Go's table-driven test pattern for testing domain invariant edges and factory functions.
