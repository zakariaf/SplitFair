# EPIC 11 — Settle Up

> Close the loop on balances: let a user record a repayment (full or partial) against a friend's running balance so it drops toward zero — stored locally, no account, no sync.

## What this epic is for

After EPIC 10, SplitFair shows running balances ("Ben owes you $23.40") but they only ever grow — there is no way to say "Ben paid me back." This epic adds **settlements**: a recorded payment between you and a friend that nets against their balance. It is deliberately small and split out from EPIC 10 so balances ship first and settle-up lands as a focused follow-up. Settlements are just another kind of ledger entry — computed into the same `netBalances`, never a stored balance — so the exact-cent, no-drift contract holds.

## Where we are before starting (starting state)

- EPIC 10 is complete: a persistent roster with a "me", a local library of bills, a recorded payer per bill, and a computed `netBalances(bills:me:)` shown read-only on the Bills home screen.
- There is an obvious "settle up" affordance/placeholder on a balance row, but tapping it does nothing yet.
- Money is still integer cents through `allocate`; balances are computed, never stored; everything is offline, no account, no sync.

## What we will have after finishing (definition of done)

- `BillCore` gains a `Settlement` value (`id`, `from: Person.ID`, `to: Person.ID`, `amount: Money`, `date: Date`) and `netBalances` accepts settlements, subtracting them in the correct direction. Still pure, still integer cents, still tested.
- Settlements persist locally alongside bills/roster (e.g. `settlements.json` in Application Support), atomic, default protection — no new privacy surface, still "Data Not Collected."
- The single `BillStore` owns `settlements` and exposes `settle(with:amount:)` and `deleteSettlement(_:)`; `balances` folds them in as a computed value.
- A balance row's **Settle up** action records a full or partial repayment (defaulting to the outstanding amount), the balance updates live toward zero, and an all-square friend drops out of the summary.
- Money stays ink-on-paper; direction stays words+arrow (never red/green); the accessibility audit passes.

## Dependencies

- Depends on: **EPIC 10 — Bills Library & Running Balances** (the roster, "me", and `netBalances` it settles against).
- Enables: a clean re-run of **EPIC 09 — Release Prep** with the full ledger feature set.

---

## Tasks

### Task 11.1 — Add the Settlement model and fold it into netBalances

**Skills to load:** `splitfair-domain-model`, `splitfair-money-math`, `splitfair-testing`

**Why this matters:** A settlement is money, so it obeys non-negotiable #1 — integer cents, computed into the same balance function, never a separately stored balance that could drift. Extending `netBalances` (rather than adding a parallel calculation) keeps one source of truth.

**What to do:**

1. Add `Settlement { let id: UUID; let from: Person.ID; let to: Person.ID; var amount: Money; var date: Date }` to `BillCore`, `Codable`/`Equatable`.
2. Extend the balances engine: `netBalances(bills:settlements:me:)`. A settlement where `from == me, to == F` **reduces what I owe F / increases what F owes me** by `amount` (and vice-versa). Apply in integer cents, in the correct sign.
3. Tests: a full settlement zeroes a balance; a partial settlement reduces it by exactly the amount; an over-payment flips direction correctly; settlements with no matching balance are handled sanely.

**Done when:**

- `Settlement` exists; `netBalances(bills:settlements:me:)` nets them in the right direction using integer cents; the EPIC 10 tests still pass and new settlement tests are green via `swift test`.

---

### Task 11.2 — Persist settlements and expose store intents

**Skills to load:** `splitfair-persistence`, `splitfair-state-store`

**Why this matters:** Settlements are durable ledger facts; losing them silently resurrects a debt the user already cleared. They persist with the same atomic, default-protection, Application-Support discipline as bills and roster.

**What to do:**

1. Persist `settlements` (e.g. `Application Support/settlements.json`), injectable URL, atomic write, corrupt/missing → empty.
2. Expand `BillStore`: `private(set) var settlements: [Settlement]`, `settle(with friend: Person.ID, amount: Money)` (creates a `from: meID` settlement), and `deleteSettlement(_:)`; make `balances` compute over bills **and** settlements.
3. Route through the existing debounced-save model; still one `@Observable`, no SwiftData.

**Done when:**

- Settlements persist and reload via an injected temp URL in tests; `BillStore.balances` folds them in live; recording then relaunching keeps the balance settled.

---

### Task 11.3 — Wire the "Settle up" UI

**Skills to load:** `splitfair-design-system`, `splitfair-buttons`, `splitfair-accessibility`

**Why this matters:** This is the satisfying "paid back" moment. It must be one clear action with an honest default (the outstanding amount) and stay within the HARD COPY language — money ink-on-paper, direction by words, no red/green.

**What to do:**

1. On a balance row, wire **Settle up** to a small sheet/alert: amount field defaulting to the outstanding balance, with a clear "Ben paid you $X" / "You paid Ben $X" direction.
2. On confirm, call `settle(with:amount:)`; the balance animates toward zero and an all-square friend leaves the summary (reuse the SETTLED ✓ celebration language where it fits).
3. Allow viewing/removing a recorded settlement (undo a mistake).
4. Money uses `MoneyDisplay` tabular digits; nothing composites over glass/chip; passes the accessibility audit.

**Done when:**

- Tapping Settle up records a full or partial repayment, the balance updates live toward zero, and a settled friend drops out; a settlement can be undone; the audit passes and no red/green encodes direction.
