# EPIC 10 — Bills Library & Running Balances

> Turn SplitFair from a single-bill splitter into an offline ledger: a persistent roster of friends (one marked "you"), a saved library of past bills, a "who paid" step on each bill, and a running who-owes-whom balance netted across every bill — all still on-device, no account, no sync.

## ⚠️ This epic deliberately amends the contract

This is the one feature that changes SplitFair's identity, chosen with eyes open. It rewrites two of the four non-negotiables in `CLAUDE.md`:

- **#2 Offline & private** — the clause *"persist only the single current bill… nothing stored beyond the current bill"* becomes *"persist a local library of bills plus a friends roster."* The **philosophy is unchanged**: still offline, no account, no network, still **"Data Not Collected"** — nothing ever leaves the device; we simply store more *locally*.
- **#3 Right-sized** — *"two screens, complexity 2/5"* becomes *"three screens, complexity ~4/5."* The architecture rules that survive: still **one `@MainActor @Observable` store**, still **no SwiftData / ViewModels / TCA**, still exact-cent reconciliation through the single `allocate()` primitive.

Non-negotiables **#1 (exact-cent reconciliation)** and **#4 (bold-but-legible, money is ink-on-paper)** are untouched and still gate every task. Amending the contract is **Task 10.1** — it is done explicitly and first, never worked around silently.

## What this epic is for

Today SplitFair holds exactly one ephemeral bill; clearing it forgets everything. Users split with the same friends again and again and want the app to remember: what each outing cost, and — netted across all of them — who currently owes whom. This epic introduces three durable concepts the app has never had: a **persistent friend identity** (so "Ben" on Monday is the same Ben on Friday), a **"you"** the balances are relative to, and a record of **who fronted each bill**. On top of those it adds a **Bills home screen** (the new launch screen) listing every saved bill with a balances summary at the top, and it teaches the money engine to compute pairwise net balances from the same reconciled per-person totals. When this epic lands, SplitFair is a private, offline settle-up ledger: split a meal, record who paid, and see "Ben owes you $23.40 · You owe Cy $8.10" accumulate over time — with settle-up (marking a balance paid) arriving next in EPIC 11.

## Where we are before starting (starting state)

- The app is feature-complete for a **single** bill: `BillCore` (`Money`, `allocate`, `Person`, `Item`, `Bill`, `BillMath.compute → BillResult`, `MoneyEdge`, `Summary`) is green via `swift test`, including the `$97.20` acceptance bill and the reconciliation fuzz.
- One `@MainActor @Observable BillStore` owns a single `Bill`; `BillDraftStore` persists exactly that one bill to `current-bill.json` in Application Support (atomic, default protection, ~600 ms debounce + `scenePhase` flush).
- Two screens: **BillScreen** (roster + items + assign + footer, with tap-to-rename diners and tap-to-edit items) and **TotalsScreen** (tax/tip, per-person bento cards, SETTLED ✓ reconciliation banner, round-up, copy/share, clear).
- `Person` identity is a stored `let id = UUID()` created fresh per bill — there is **no** identity that outlives a bill, **no** concept of "me", and **no** record of who paid.
- Motion/haptics/accessibility are wired and the accessibility audit passes (EPIC 08). Release prep (EPIC 09) has not run yet and must re-run after this epic because the privacy footprint and screen count change.

## What we will have after finishing (definition of done)

- `CLAUDE.md` non-negotiables **#2** and **#3** are rewritten to match the library/balances reality (Task 10.1), and every skill/doc that asserted "single current bill" or "two screens" is corrected.
- `BillCore` gains, additively and without disturbing the `allocate`/`compute` math: `Bill.title: String`, `Bill.createdAt: Date`, `Bill.payerID: Person.ID?`, and a pure, tested `Balances` engine computing **net pairwise balance per friend relative to `me`** from the existing reconciled per-person totals.
- A persistent **roster** of `Person` (stable ids, stable `colorIndex` per friend) and a `meID` are stored on device; bills reference friends by those stable ids so balances accumulate correctly.
- Persistence moves from one file to a **local library**: one JSON per bill under `Application Support/Bills/`, plus `roster.json`; writes stay atomic with default protection; the old `current-bill.json` is **migrated** into the library on first launch. Still no network, no account, no sync.
- The single `BillStore` is expanded (not fragmented) to own `roster`, `meID`, the `bills` library, and the selected bill, exposing intents for new/open/duplicate/delete/rename bill, pick-participants, set-payer, add-friend, and set-me — still one `@Observable`, still no SwiftData.
- A new **BillsHomeScreen** is the launch screen: a **Balances** summary ("Ben owes you $X" / "You owe Cy $Y", direction shown by words + arrow, money always ink-on-paper — never red/green), and a list of saved bills (title, date, grand total, diner stickers) with new/duplicate/rename/swipe-delete and an empty state. Navigation is Home → Bill → Totals.
- BillScreen gains a **"Who paid?"** control and participant selection from the roster (adding a new name also joins the roster); Totals is unchanged except it reads participants from the selected bill.
- The `$97.20` acceptance bill still reconciles to the exact cent; new balance and persistence tests are green via `swift test`; the accessibility audit still passes on all three screens.

## Dependencies

- Depends on: EPIC 02 (money engine — balances reuse `BillMath` per-person totals), EPIC 03 (store & persistence — extended here), EPIC 05–07 (components & screens — reused and extended).
- Enables: **EPIC 11 — Settle Up** (recording repayments against these balances) and a re-run of **EPIC 09** (release prep) against the new privacy footprint and third screen.

---

## Tasks

### Task 10.1 — Amend the contract (CLAUDE.md) for the library + balances

**Skills to load:** `splitfair-overview`, `splitfair-app-architecture`

**Why this matters:** The contract is the source of truth every future session obeys. Building the library while `CLAUDE.md` still says "persist only the single current bill" and "two screens" would put the code in permanent, silent violation of its own contract — exactly what the contract forbids. Amending it first, deliberately, keeps the document honest and makes the new boundaries (library yes, sync no; three screens yes, SwiftData no) explicit for everyone who comes after.

**What to do:**

1. Rewrite non-negotiable **#2**: keep "offline, no network, no analytics, no accounts, Data Not Collected," but change the persistence clause to *"persist a local library of bills plus a friends roster on device — never synced, never uploaded."*
2. Rewrite non-negotiable **#3**: "three screens (Bills, The Bill, Totals), complexity ~4/5. Still one `@Observable` store, still NO ViewModels / SwiftData / TCA / Coordinators."
3. Leave **#1** (exact-cent reconciliation, single `allocate()`, no stored totals) and **#4** (bold-but-legible, money is ink-on-paper) verbatim — they still gate everything, including the new balances UI.
4. Update the "Hard gotchas" and repo-map lines that reference the single-file draft or two screens; add a one-line pointer to EPIC 10/11.
5. Do **not** change the ritual, the commit protocol, or the skills-first rule.

**Done when:**

- `CLAUDE.md` #2 and #3 read as above; #1 and #4 are unchanged; the offline/no-account/no-sync and one-store/no-SwiftData boundaries are explicit.
- No other doc still claims "nothing stored beyond the current bill" or "two screens" (grep for both).
- Committed as its own task commit before any code lands.

---

### Task 10.2 — Extend the domain: bill metadata, payer, and a persistent roster identity

**Skills to load:** `splitfair-domain-model`, `splitfair-money-math`

**Why this matters:** Balances live or die on identity. For "Ben owes you" to accumulate, the same `Person.ID` must recur across bills, so the roster — not each bill — becomes the origin of a friend's identity and color. This task makes the additive model changes (title, date, payer) and pins down the rule that bills reference roster people by stable id, all without touching the `allocate`/`compute` math the `$97.20` gate depends on.

**What to do:**

1. In `BillCore`, add to `Bill`: `var title: String = ""`, `var createdAt: Date`, and `var payerID: Person.ID?` (nil = "not recorded yet"). Keep everything `Codable`/`Equatable`. Provide sane defaults so existing decode still works (see migration in 10.4).
2. Do **not** add a new `Friend` type — reuse `Person` as the stable identity (it already has a stored `let id = UUID()`). The *roster* (persisted `[Person]` + `meID`) lives at the app layer (Task 10.4/10.5); `BillCore` only needs to know a bill's `people` are those same ids.
3. Establish the rule (documented in the domain-model skill): a friend's `colorIndex` is assigned **once when they join the roster** and stays stable across every bill, so a diner keeps their color everywhere.
4. Confirm `BillMath.compute` is untouched and still ignores `title`/`createdAt`/`payerID` — payer affects *balances*, never the per-person split of a single bill.
5. Add/extend tests: a bill round-trips with the new fields; an old-shape JSON (no title/payer) still decodes with defaults; the `$97.20` bill still computes identically.

**Technical details & suggestions:**

```swift
public struct Bill: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String            // "" ⇒ UI shows an auto-title (date / first item)
    public var createdAt: Date
    public var currency: Currency
    public var people: [Person]         // participants, ids drawn from the roster
    public var items: [Item]
    public var tax: Money
    public var tip: TipMode
    public var payerID: Person.ID?      // who fronted the money; nil ⇒ excluded from balances
    // …existing init, with new params defaulted so call sites & old JSON survive…
}
```

**Done when:**

- `Bill` has `title`, `createdAt`, `payerID`; all `Codable`/`Equatable`; the package builds.
- Decoding a pre-EPIC-10 `Bill` JSON succeeds with defaulted new fields (no migration code in `BillCore`).
- `swift test` green, including the unchanged `$97.20` acceptance bill and a new round-trip test covering the new fields.

---

### Task 10.3 — Build the Balances engine (pure, tested)

**Skills to load:** `splitfair-money-math`, `splitfair-testing`

**Why this matters:** Balances are money, so they obey non-negotiable #1: computed, never stored, exact to the cent, and derived from the **same** reconciled per-person totals as the on-screen split — never a parallel calculation that could disagree. Keeping this a pure function in `BillCore` (no store, no UI) means it is fuzz-testable in milliseconds and can't drift from `BillMath`.

**What to do:**

1. Add `BillCore/Balances.swift` with a pure function that takes the bills and `me` and returns the net balance per other person:
   `func netBalances(bills: [Bill], me: Person.ID) -> [Person.ID: Money]`.
2. For each bill, get per-person owed totals from the existing `BillMath.compute(bill).perPerson` (each person's share of items + tax + tip — already reconciled). Skip bills where `payerID == nil` or the payer isn't a participant.
3. Net pairwise, from `me`'s perspective, using integer cents only:
   - If `me` is the payer: every other participant `p` **owes me** `perPerson[p].total` → `balance[p] += that`.
   - If a friend `F` is the payer: **I owe F** `perPerson[me].total` → `balance[F] -= that`.
   - If a third party is the payer: contributes **0** to my balance with anyone (I owe the payer, others owe the payer — not each other).
4. A positive result means "they owe you", negative means "you owe them". Return only non-zero entries.
5. Tests: (a) single bill I paid → others owe me exactly their shares, summing to the reconciled non-payer total; (b) a bill a friend paid → I owe exactly my share; (c) two bills in opposite directions net correctly; (d) a `payerID == nil` bill is ignored; (e) a fuzz test over random bills asserting no rounding leak (every cent is attributable, `allocate` is the only splitter).

**Technical details & suggestions:**

```swift
public func netBalances(bills: [Bill], me: Person.ID) -> [Person.ID: Money] {
    var net: [Person.ID: Int] = [:]           // minor units; NEVER Double
    for bill in bills {
        guard let payer = bill.payerID,
              bill.people.contains(where: { $0.id == payer }) else { continue }
        let per = BillMath.compute(bill).perPerson   // reconciled shares, exact cents
        if payer == me {
            for p in bill.people where p.id != me {
                net[p.id, default: 0] += (per[p.id]?.total.minorUnits ?? 0)
            }
        } else if bill.people.contains(where: { $0.id == me }) {
            net[payer, default: 0] -= (per[me]?.total.minorUnits ?? 0)
        }
    }
    return net.compactMapValues { $0 == 0 ? nil : Money($0) }
}
```

**Done when:**

- `netBalances` exists in `BillCore`, uses only integer cents and `BillMath` per-person totals, and returns net pairwise balances relative to `me`.
- The five test cases above are green via `swift test`; the fuzz test finds no unattributed cent.
- Bills with no recorded payer are provably excluded; a bill nets in the correct direction and magnitude.

---

### Task 10.4 — Multi-bill persistence + roster + migration

**Skills to load:** `splitfair-persistence`

**Why this matters:** This is where "Data Not Collected" stays physically honest at a larger scale. A library means many files, and the migration from the old single `current-bill.json` is the one moment a user's existing in-progress bill could be lost if done carelessly. Per-bill files (not one giant array) keep writes atomic and deletes trivial, and everything stays in Application Support — never Documents, never iCloud.

**What to do:**

1. Add a `LibraryStore` in `SplitFair/Persistence/` that owns `Application Support/Bills/<uuid>.json` (one file per bill) and `Application Support/roster.json` (`{ people: [Person], meID: UUID? }`). Keep the URL/directory **injectable** for tests.
2. Reuse the EPIC 03 discipline: atomic writes (`options: [.atomic]`), **default** file protection (never `.completeFileProtection`), create directories with `withIntermediateDirectories: true`, corrupt/missing → skip that file (never crash).
3. `load()` reads all bill files into `[Bill]` (sorted by `createdAt` desc) and the roster; `save(bill:)` writes one file; `delete(billID:)` removes one file; `saveRoster(...)` writes `roster.json`.
4. **Migration (once):** on first launch, if the legacy `current-bill.json` exists, decode it, give it a `createdAt`/`title`, write it into `Bills/`, seed the roster from its people (stable `colorIndex`), leave `meID` nil (the first-run "which one is you?" picker in Task 10.8 sets it), then delete the legacy file. If decode fails, discard quietly (matches the old corrupt→empty rule).
5. Keep the debounced-write model from EPIC 03 but scoped per bill (only the edited bill's file rewrites).

**Done when:**

- Bills persist as individual files under `Application Support/Bills/`; the roster persists as `roster.json`; both round-trip via an injected temp directory in tests.
- A pre-existing `current-bill.json` migrates into the library exactly once and is then removed; a corrupt legacy file is discarded without crashing.
- No Documents path, no `.completeFileProtection`, no network — verified by test and by grep.

---

### Task 10.5 — Expand BillStore to own the library, roster, and selection

**Skills to load:** `splitfair-state-store`, `splitfair-app-architecture`

**Why this matters:** The temptation here is to shatter state into a LibraryViewModel + BillViewModel + BalancesViewModel. That is exactly the enterprise fragmentation the contract still forbids. One `@Observable` store keeps a single source of truth: the library, the roster, "me", and which bill is open — with balances and totals both **computed**, never stored, so they can never drift from the bills that produced them.

**What to do:**

1. Expand `BillStore` to own: `private(set) var roster: [Person]`, `private(set) var meID: Person.ID?`, `private(set) var bills: [Bill]`, and `selectedBillID: Bill.ID?`. Expose the open bill via a computed `var currentBill: Bill?` (or an index) — the two screens edit it through intents exactly as before.
2. Add computed, never-stored derivations: `var balances: [Person.ID: Money] { netBalances(bills: bills, me: meID) }` (empty until `meID` is set) and keep the existing computed per-bill `totals`.
3. Add library intents: `newBill()`, `openBill(_:)`, `duplicateBill(_:)` (copies items + participants, **fresh `createdAt`**, clears `payerID` or keeps it — pick and document), `deleteBill(_:)`, `renameBill(_:to:)`.
4. Add roster/participant intents: `addFriend(named:)` (assigns stable `colorIndex`, returns the id), `setMe(_:)`, `setParticipants(_:for:)` or reuse add/remove person to also register the friend in the roster, and `setPayer(_:for:)`.
5. Route every mutation through the per-bill debounced save from Task 10.4; saving the roster on roster/me changes.
6. Keep transient UI state (text being typed, expanded cards, which sheet is open) **out** of the store — view-local `@State` as before.

**Technical details & suggestions:**

```swift
@MainActor @Observable
final class BillStore {
    private(set) var roster: [Person] = []
    private(set) var meID: Person.ID?
    private(set) var bills: [Bill] = []
    var selectedBillID: Bill.ID?

    var currentBill: Bill? { bills.first { $0.id == selectedBillID } }
    var balances: [Person.ID: Money] {                 // computed ⇒ zero drift
        guard let me = meID else { return [:] }
        return netBalances(bills: bills, me: me)
    }
    // …library + roster + participant + payer intents, each persisting via LibraryStore…
}
```

**Done when:**

- One `BillStore` owns roster + meID + bills + selection; `balances` and `totals` are computed, never stored; no ViewModels, no SwiftData, no Combine.
- Creating, opening, duplicating, renaming, and deleting bills works and persists; adding a participant registers a stable friend; setting the payer and "me" persists.
- Building two bills through the intents (one I paid, one a friend paid) yields the correct `balances` map live.

---

### Task 10.6 — Add "Who paid?" and roster-based participants to the Bill screen

**Skills to load:** `splitfair-diner-chip`, `splitfair-buttons`, `splitfair-design-system`

**Why this matters:** Recording the payer is what makes balances possible, and it must feel like one tap, not a form. Reusing the existing diner-chip identity for both "who's on this bill" and "who paid" keeps the HARD COPY language intact — the payer is a state on a chip you already understand, not a new widget.

**What to do:**

1. Add a **"Who paid?"** control near the footer/roster: the participant chips, single-select, with the payer chip carrying a distinct grayscale-legible mark (e.g. a "PAID" stamp/notch + fill) — never color alone (non-negotiable #4 / accessibility).
2. When adding a person, register them in the roster (stable id + color) and add them as a participant; when picking existing friends for a new bill, select from the roster.
3. Keep the existing assign-by-item, tap-to-rename, tap-to-edit, and unassigned-guard behavior unchanged.
4. Reflect payer changes through `setPayer(_:for:)`; a bill with no payer shows a gentle "Add who paid to track balances" hint (non-blocking — Totals still works without it).
5. Respect the margins fixed earlier (20pt content insets) and the one-glass-rail rule.

**Done when:**

- The Bill screen lets you pick who paid from the participants, with a non-color payer indicator that survives grayscale and the accessibility audit.
- Adding a name registers a persistent friend; the payer persists on the bill.
- Existing assign/rename/edit/guard behavior is unchanged; no second glass element was introduced.

---

### Task 10.7 — Build the Bills home screen (the new launch screen)

**Skills to load:** `splitfair-cards`, `splitfair-buttons`, `splitfair-design-system`

**Why this matters:** This screen is the app's new front door and the reason people reopen SplitFair. It must read instantly at a glance across a table — each saved bill legible as a receipt card, money ink-on-paper — and make "new bill" and "same friends again" (duplicate) one tap.

**What to do:**

1. Create `SplitFair/Features/Bills/BillsHomeScreen.swift` as the root screen. List saved bills (newest first) as HARD COPY cards: auto-title (or user title), date, grand total (computed, ink-on-paper), and a small stack of diner stickers for participants.
2. Add a prominent **"+ New bill"** primary action; per-row context/swipe actions for **duplicate**, **rename**, and **delete** (delete behind the app's confirm pattern).
3. Empty state: a warm first-run hero inviting the first bill (mirrors the existing "WHO'S SPLITTING?" voice).
4. Tapping a card `openBill(_:)` and navigates to the Bill screen; "+ New" creates and opens a fresh bill.
5. Reserve the top region for the Balances summary (Task 10.8) — build the layout so it slots in above the list.

**Done when:**

- The home screen lists saved bills as legible receipt cards with ink-on-paper totals and participant stickers, newest first.
- New / duplicate / rename / delete all work and persist; the empty state renders on a fresh install.
- Tapping a bill opens it; the screen is the app's launch destination.

---

### Task 10.8 — Balances summary + "which one is you?" first-run

**Skills to load:** `splitfair-design-system`, `splitfair-color-system`, `splitfair-typography`

**Why this matters:** Balances are the payoff of the whole epic, and they are the sharpest test of non-negotiable #4: an owed amount is a **neutral ink number**, and direction ("owes you" vs "you owe") must be carried by **words and an arrow, never red/green**. Getting this right is what keeps the app "bold but legible" instead of turning into a traffic-light debt tracker.

**What to do:**

1. Add a **Balances** section at the top of the home screen: one row per friend with a non-zero net — friend sticker, name, "owes you"/"you owe" wording + directional arrow, and the amount as an ink-on-paper money figure. No red/green; direction is textual + shape.
2. Show a single clear zero-state ("You're all square") when every balance is zero.
3. First-run **"Which one is you?"** picker: when `meID` is nil but a roster exists (e.g. right after migration), prompt the user to tap the sticker that's them; persist via `setMe(_:)`. Balances stay hidden until "me" is set.
4. Keep it read-only this epic — tapping a balance may preview the bills behind it, but **settling up is EPIC 11** (leave an obvious affordance/placeholder, don't implement it).
5. Money uses the same `MoneyDisplay` formatting and tabular digits as everywhere else; nothing composites over glass or a chip.

**Done when:**

- The Balances summary shows correct net amounts with direction by words+arrow and ink-on-paper money — passes a grayscale check and the accessibility audit.
- The "which one is you?" picker sets and persists `meID`; balances appear only once "me" is set; an all-square state shows cleanly.
- No red/green encodes owed-vs-owing; no settle-up action is wired yet.

---

### Task 10.9 — Wire navigation, tests, accessibility, and doc cleanup

**Skills to load:** `splitfair-ios-platform`, `splitfair-testing`, `splitfair-accessibility`

**Why this matters:** Three screens and a new data model are only "done" when the flow is coherent, the money still reconciles, the balances are tested, and every doc that lied about "single bill / two screens" is corrected. This task closes the epic and hands EPIC 11 (settle-up) and a re-run of EPIC 09 (release) a clean, honest baseline.

**What to do:**

1. Wire navigation Home → Bill → Totals (plain `NavigationStack` push; no route enums/Coordinators). Home is the launch screen; back returns to the library.
2. Add store-level tests: create/duplicate/delete bill persists; roster identity is stable across bills; `balances` matches `netBalances` for a two-bill scenario; migration imports the legacy bill exactly once.
3. Re-run the accessibility audit on all **three** screens (structural strict; contrast tolerated per the existing documented rationale); add the Bills home + balances to the audited set.
4. Take simulator screenshots of the three screens with `--seed-sample` (extend the sample to include a payer + a second bill so balances render) and confirm the `$97.20` bill still reconciles.
5. Update every skill/doc that still says "single current bill" or "two screens" (e.g. `splitfair-persistence`, `splitfair-state-store`, `splitfair-app-architecture`, `splitfair-overview`); note that release prep (EPIC 09) must re-run against the new footprint.

**Done when:**

- Home → Bill → Totals flows and returns cleanly; Home is the launch screen with no route-enum/Coordinator machinery.
- New store/balance/migration tests and the `$97.20` gate are green via `swift test`; the accessibility audit passes on all three screens.
- Three-screen screenshots exist; no skill/doc still claims "single current bill" or "two screens"; EPIC 09 is flagged for a re-run.
