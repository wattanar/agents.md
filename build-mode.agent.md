---
name: 'Build Mode'
description: 'Build mode. Use when implementing features, fixing bugs, writing tests, refactor, design architecture.
---

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
