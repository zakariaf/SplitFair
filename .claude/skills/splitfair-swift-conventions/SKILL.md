---
name: splitfair-swift-conventions
description: Swift language idioms, naming, and function-writing conventions for SplitFair — value types, enums for state, access control, and the money-representation rules. Use when writing or reviewing any Swift code in the app: naming types/functions/properties, choosing struct vs class, modeling state, or handling numbers and money.
---

# SplitFair — Swift conventions

Modern Swift 6.x, value-type-first, total functions for the math. Assume Swift fluency; this pins the choices specific to SplitFair.

## Types

- **Domain models are `struct`/`enum`, never `class`.** Value types are copied, thread-safe, trivially `Sendable`. Reach for a class only for reference identity or shared mutable state — the only one is `BillStore` (`splitfair-state-store`).
- **Identity via a stored `let id = UUID()`**, used for `Identifiable`/`ForEach`. Never derive identity from `Equatable`-on-all-fields, or two diners named "Sam" collapse into one.
- **Enums make illegal states unrepresentable.** Tip is `.percent(Int)` / `.fixed(Money)`; use exhaustive `switch` with **no `default`** so a new case is a compile error until handled.

## Naming

- Types `UpperCamelCase` (`BillResult`, `TipMode`); properties/functions `lowerCamelCase`.
- Intent methods on the store read as commands: `addPerson`, `toggleAssignment`, `setTip`, `clear`.
- Pure compute functions read as nouns/queries: `subtotals(people:items:)`, `compute(_:)`, `resolvedTip(_:)`.
- Booleans read as assertions: `isReconciled`, `hasUnassignedItems`.
- No Hungarian notation, no `m_`/`_` prefixes. Prefer clarity over brevity; avoid abbreviations except `id`, `URL`.

## Money (the rule that overrides taste)

- **All money is `Int` minor units.** `typealias Cents = Int`, or a thin `Money` value type wrapping it. See `splitfair-domain-model`.
- **A `Double`/`Float` NEVER touches money.** They can't represent `0.01` exactly.
- **`Decimal` + `FormatStyle` appear only at the edges** — parsing keypad input to cents, and formatting cents for display (`splitfair-ios-platform`). Never in arithmetic. Never `Decimal(someDouble)` (binary error) — init `Decimal` from a `String` or from integer cents.

## Functions

- **Keep domain functions pure and total** — no throwing from `compute`; validate/clamp inputs at entry instead. The only real error surface is persistence (`splitfair-persistence`); use a small typed error there (Swift 6 typed throws allows exactly one error type — no `throws(A | B)`).
- **Derive, don't store.** Totals are computed from items+assignments; never store a denormalized total (drift bug).
- Prefer immutability: `let` by default, `var` only where it truly mutates; expose store state as `private(set)` and mutate only through intent methods.

## Concurrency

- Enable Swift 6.2 Approachable Concurrency (default actor isolation = `@MainActor`). With value-type models you will essentially never hand-write `Sendable`/`@Sendable`/actors. If you feel you need one, reconsider.
