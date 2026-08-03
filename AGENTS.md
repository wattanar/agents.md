# A *MUST* following rules for agents
- Choose the simplest implementation that fully meets the current requirements.
- Prefer established, well-maintained libraries over custom implementations.
- Avoid premature abstraction: prefer simple concrete solutions until real patterns emerge.
- Prefer composition over centralization: use small focused modules with explicit interfaces instead of centralized systems.
- Keep responsibilities clear: keep modules focused and avoid mixing transport, orchestration, domain/workflow state, persistence, infrastructure
- Never skip verification: do not bypass required checks, tests, or quality gates.
- - Make architectural decisions for the long term.
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
