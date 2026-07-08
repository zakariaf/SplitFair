# EPIC 06 — Screen 1 — The Bill

> Compose the first screen: add people and items, tap to assign who ordered what, live split-rings, the unassigned guard, and the footer that gates Next.

## What this epic is for
This epic assembles the first real screen of SplitFair out of the parts we already built: the `DesignSystem` component library (EPIC 05) and the live `BillStore` (EPIC 03) sitting over the tested `BillCore` engine (EPIC 02). The goal is a fully working "build the bill" surface — a diner roster, item rows with tap-to-assign chips and live split-rings, inline add-item entry, a live subtotal odometer, and the unassigned hazard-tape guard that refuses to let anyone navigate forward while money is still unattributed. Nothing here recomputes anything by hand: every number on screen is derived live from `store.totals` (`BillMath.compute`), and every mutation goes through a `BillStore` intent. When this epic is done, a user can enter a whole party's worth of items and assign every one, and the app is ready to hand off to Screen 2.

## Where we are before starting (starting state)
- `BillCore` is complete and green via `swift test`: `Money`/`Cents`, the single `allocate(amountCents:weights:)` largest-remainder primitive, `Person`/`Item`/`TipMode`/`Bill`, `BillMath.compute → BillResult`, `MoneyEdge` (parse/format) and `Summary`. The `$97.20` acceptance bill passes.
- `BillStore` exists as the one `@MainActor @Observable final class`, constructed once at the App root and injected via `.environment(store)`. It exposes `private(set) var bill`, a computed `var totals: BillResult`, and intent methods (`addPerson`, `addItem`, `toggleAssignment`, `assignToEveryone`, `deleteItem`, `deletePerson`, `setTax`, `setTip`, `clear`). Auto-save/restore already works.
- The `DesignSystem` foundation and component library are built with light/dark `#Preview`s: `DinerChip`, `SplitRing`, the three buttons (`PrimaryButton`, secondary, destructive), `ItemRow` / `PersonTotalCard`, `TipControls`, `ReconciliationBanner`, and the status treatments (hazard-tape flag, empty states, footer rail). Color/font tokens, shapes (`PerforationEdge`, `CornerNotch`, `SplitRing`, drifting blobs), `BrutalShadow`, and the fixed `DinerPalette` all exist.
- No screens are composed yet. `Features/Bill/` and `Features/Totals/` are empty (or hold only stubs). The app still launches to a placeholder.

## What we will have after finishing (definition of done)
- A working `BillScreen` at the `NavigationStack` root: a **sticky diner roster** at the top, a **scrolling item list** in the middle, and a **sticky glass footer rail** at the bottom.
- **Fast add-person entry:** a horizontal `DinerBar` with a dashed add chip; tapping it drops a new solid sticker in and auto-focuses a pre-filled "Person N" name field; Return chains straight to the next person. Colors/notch/texture are assigned by **stable roster index**.
- **Item rows** rendered from the store: an SF-Mono price wrapped in a live `SplitRing`, a horizontally-scrollable chip strip that toggles assignment on tap (2+ people ⇒ even split), and an inline **"Shared by all"** pill. The ring's arcs always equal `item.assigneeIDs.count`.
- **Inline add-item entry:** a dashed add-item card that expands in place with a `.decimalPad` + toolbar Done, a cents-accumulator parser, and an optional label defaulting to "Item N".
- **Live recompute:** every assignment/add/delete mutates the store and the subtotal + rings update immediately with the signature assign spring, `.selection` haptic, and the matched-geometry arc flying into the ring. There is no Calculate button.
- **Footer rail:** the one glass surface, with a `.numericText()` subtotal odometer on an opaque cream pill (left) and the Tangerine "Next: Tax & Tip →" CTA (right).
- **The unassigned guard:** while any item has zero assignees, the footer shows a running count, the offending rows carry the three-signal hazard-tape flag, and tapping Next does **not** navigate — the ⚠ symbols wiggle, a `.warning` haptic fires, and the first offender scrolls into view. Once everything is assigned, Next is enabled and a plain `NavigationLink` pushes Screen 2.

## Dependencies
- Depends on: EPIC 05 (Reusable UI Components), EPIC 03 (App State & Local Persistence), EPIC 02 (The Money Engine).
- Enables: EPIC 07 (Screen 2 — Tax, Tip & Totals), which this screen navigates to via a single `NavigationLink`.

---

## Tasks

### Task 6.1 — Scaffold BillScreen and its layout
**Skills to load:** `splitfair-app-architecture`, `splitfair-status-flags`

**Why this matters:** This is the structural spine every later task hangs off. Get the three-zone layout (sticky roster / scrolling items / sticky footer) and the store wiring right once, and 6.2–6.6 slot in cleanly. Get it wrong — e.g. constructing the store inside the screen, or scrolling the footer with the content — and you either fracture the single source of truth or lose the "check tears off" footer that the whole subtotal/guard interaction depends on. The architecture skill is explicit that this app is **Model-View with `@Observable`** and exactly one store; do not invent a ViewModel or a `NavigationPath`.

**What to do:**
1. Create `SplitFair/Features/Bill/BillScreen.swift` with `struct BillScreen: View`. Read the injected store with `@Environment(BillStore.self) private var store` — never construct a `BillStore` here (a `@State` in a rebuilt child re-runs its initializer and would spawn a second bill).
2. Confirm the App root already wraps this screen: `WindowGroup { NavigationStack { BillScreen() }.environment(store) }` in `SplitFair/App/SplitFairApp.swift`. Do **not** add a second `NavigationStack` inside `BillScreen`; the root owns it, and Screen 2 is reached with one plain `NavigationLink` (Task 6.6).
3. Lay out three vertical zones inside a `ZStack` over the drifting-blob cream canvas background:
   - **Top (sticky):** the `DinerBar` roster (Task 6.2), pinned above the scroll.
   - **Middle (scrolling):** a `ScrollView` of item rows (Task 6.3) + the inline add-item card (Task 6.4), wrapped in a `ScrollViewReader` so the guard can scroll to an offender (Task 6.6).
   - **Bottom (sticky):** the glass footer rail (Task 6.6), floating over the content, not inside the scroll.
4. Add the empty-state branch per `splitfair-status-flags`: when `store.bill.people.isEmpty`, show the first-run "WHO'S SPLITTING?" state (giant Fraunces, one ghost/dashed sticker, name field auto-focused) instead of the item list. When there are diners but no items, the middle zone is just the dashed "+ Add item" sticker-card.
5. Keep all transient UI state (focus, which add-row is expanded, the pending-name text) as view-local `@State`/`@FocusState`, not on the store.

**Technical details & suggestions:**
- Skeleton:
  ```swift
  struct BillScreen: View {
      @Environment(BillStore.self) private var store
      @Namespace private var assignArc          // shared for matched-geometry (Task 6.5)
      var body: some View {
          ZStack(alignment: .bottom) {
              CanvasBackground()                 // drifting blobs, DesignSystem
              VStack(spacing: 0) {
                  DinerBar()                     // sticky roster (6.2)
                  ScrollViewReader { proxy in
                      ScrollView {
                          LazyVStack(spacing: 14) {
                              ForEach(store.bill.items) { item in
                                  ItemRow(item: item).id(item.id)
                              }
                              AddItemRow()        // inline entry (6.4)
                          }
                          .padding(.horizontal, 20)
                          .padding(.bottom, 120)  // clearance for the floating footer
                      }
                  }
              }
              FooterRail()                        // sticky glass rail (6.6)
          }
      }
  }
  ```
- The footer must **float** over the scroll (that is why it lives in the `ZStack`, not the `VStack`) so the content scrolls under its `PerforationEdge` and the total reads like a torn-off check stub (`splitfair-status-flags`). Give the scroll `.padding(.bottom, ~120)` so the last row clears the rail.
- Route the empty-state decision on `store.bill.people` / `store.bill.items`, both read-only. The cleared-bill case returns to "WHO'S SPLITTING?" automatically because `clear()` empties `people` — no special-casing.
- Do not add `NavigationPath` or route enums; the architecture skill rejects them as over-engineering for one push.

**Done when:**
- `BillScreen` builds, reads the injected store, and renders three zones: a pinned roster, a scrolling item list, and a floating glass footer that content scrolls beneath.
- With an empty bill the screen shows "WHO'S SPLITTING?"; with diners but no items it shows the dashed add-item card; with items it shows the list.
- There is exactly one `NavigationStack` (at the App root) and exactly one `BillStore` instance in the app; `BillScreen` constructs neither.

---

### Task 6.2 — Build the roster bar and add-person flow
**Skills to load:** `splitfair-diner-chip`, `splitfair-ios-platform`, `splitfair-state-store`

**Why this matters:** The roster is the identity backbone of the whole screen: every chip in every item row, every split-ring arc, and every per-person card downstream is keyed to a person's **stable roster index** for color/notch/texture. If the color assignment drifts (e.g. keyed to a dictionary or shuffled `Set` order), a diner's sticker changes hue mid-session and the four redundant identity channels stop being trustworthy — a serious accessibility failure since color is only one of four signals and they must agree. Fast entry matters too: real use is standing at a table typing four names quickly, so "Return adds the next person" is the difference between usable and annoying.

**What to do:**
1. Create `SplitFair/Features/Bill/DinerBar.swift`. Render a horizontal `ScrollView(.horizontal)` (or a wrapping `HStack`) of **solid, shadowed** `DinerChip`s in roster order — the header state is always `assigned = true` with `BrutalShadow` (`splitfair-diner-chip`).
2. After the chips, render the **add-person control**: a dashed-outline capsule with a `plus.circle` symbol. On tap, insert a new person and immediately enter name-entry.
3. Pre-fill the new person's name as "Person N" (N = next roster index + 1) so a user can just hit Return to accept it, or type over it.
4. Wire fast entry with `@FocusState` + `.submitLabel(.next)` + `.onSubmit`: on submit, commit the current name via `store.addPerson(name)`, clear the field, insert the next "Person N", and re-focus — implementing "Enter chains the next person" (`splitfair-ios-platform`).
5. Assign color/notch/texture strictly by **roster index** from the fixed `DinerPalette` so identity is stable all session (`splitfair-diner-chip`, `splitfair-color-system`).

**Technical details & suggestions:**
- Name field config per `splitfair-ios-platform`: `.default` keyboard, `.textInputAutocapitalization(.words)`, `.autocorrectionDisabled()`, `.submitLabel(.next)`. Keep the in-progress text and focus in view-local `@State`/`@FocusState` — not on the store.
  ```swift
  @Environment(BillStore.self) private var store
  @State private var draftName = ""
  @FocusState private var nameFocused: Bool

  private func commit() {
      let name = draftName.trimmingCharacters(in: .whitespaces)
      store.addPerson(name.isEmpty ? "Person \(store.bill.people.count + 1)" : name)
      draftName = "Person \(store.bill.people.count + 1)"   // pre-fill next
      nameFocused = true                                    // chain
  }
  // TextField("Name", text: $draftName).focused($nameFocused)
  //   .submitLabel(.next).onSubmit(commit)
  //   .textInputAutocapitalization(.words).autocorrectionDisabled()
  ```
- **Stable color by index:** derive the `DinerStyle` (color, `CornerNotch`, `ChipTexture`, paired ink) from the person's position in `store.bill.people`, e.g. `DinerPalette.style(for: index)`. Never key styling off a hashed `Person.ID` into a dictionary and never off `Set` iteration order — both can reorder. Roster order is also what the split-ring and `allocate([1]*N)` assume (`splitfair-split-ring`, `splitfair-money-math`), so keeping one order everywhere keeps arcs, colors, and cent-shares in agreement.
- The add-person tap should visually **bounce a new solid chip in** with a spring overshoot and a `symbolEffect` on the plus (`splitfair-motion-and-haptics`); the name field auto-focuses on insert.
- The first-run empty state (Task 6.1) is the same machinery with the field already focused and `draftName` pre-filled to "Person 1".
- Each chip is ≥44×44 and carries all four identity channels (fill, keyline, initials, notch, texture) — do not drop the notch/texture just because it is the header.

**Done when:**
- Tapping add-person inserts a diner via `store.addPerson`, drops a solid shadowed chip into the bar, pre-fills "Person N", and auto-focuses the name field.
- Pressing Return commits the current name and immediately starts the next "Person N" with focus retained (chained entry works with the keyboard never dismissing).
- Each diner's color, notch, and texture are fixed by roster index and never change during the session; deleting and re-adding assigns by the new index without corrupting existing diners.

---

### Task 6.3 — Wire item rows with price, split-ring and chip strip
**Skills to load:** `splitfair-cards`, `splitfair-split-ring`, `splitfair-diner-chip`

**Why this matters:** The item row is where "who ordered what" becomes visible, and it must never lie about the split. The `SplitRing`'s arc count is a redundant, grayscale-legible signal of how many people share an item; if it drifts from `item.assigneeIDs.count`, the UI is silently misrepresenting money. The row also renders the price as **ink SF-Mono tabular** digits so the price column aligns like a printed receipt — color rings the number, it never touches it. This is the loud-frame/calm-center rule: stickers and rings are loud, the numeral stays calm ink.

**What to do:**
1. Create `SplitFair/Features/Bill/ItemRow.swift` (and `PersonChip.swift` if the row-level chip differs from the header `DinerChip`). Drive the row from a single `Item` passed in; read the roster from the store for the chip strip.
2. Build the card per `splitfair-cards`: `RoundedRectangle` r=22, Receipt White surface, `BrutalShadow` hard offset shadow, 20pt padding. Top row = optional label (17pt; placeholder "Item" italic secondary) on the left, and a **right-aligned SF Mono Heavy 24pt price wrapped in the `SplitRing`** on the right.
3. Feed the `SplitRing` the assignees **in roster order**: map `item.assigneeIDs` to `DinerStyle`s ordered by each person's roster index, so arcs match `allocate([1]*N)` order (`splitfair-split-ring`, `splitfair-money-math`). Empty ⇒ the hollow dashed unassigned ring.
4. Build the bottom **chip strip**: a horizontal `ScrollView` of one chip per diner, each in hollow (unassigned) or filled (assigned) state depending on whether that person is in `item.assigneeIDs`. Tapping a chip toggles assignment (wired in Task 6.5). Add an inline **"Shared by all"** pill that assigns everyone at once.
5. Render the **left edge** as a 4pt ink rule that becomes amber hazard-tape when the item is unassigned (Task 6.6 owns the guard visuals; here just expose the state to the row).

**Technical details & suggestions:**
- Price uses the currency `FormatStyle` from the edge, tabular so the column never jitters (`splitfair-ios-platform`, `splitfair-cards`):
  ```swift
  Text(Decimal(item.amount.minorUnits) / 100, format: .currency(code: store.bill.currency.code))
      .font(.money(24)).monospacedDigit().foregroundStyle(Color.ink)   // ink, never a hue
  ```
- Ring assignees in roster order:
  ```swift
  let styles = store.bill.people.enumerated()
      .filter { item.assigneeIDs.contains($0.element.id) }
      .map { DinerPalette.style(for: $0.offset) }
  SplitRing(assignees: styles)        // empty ⇒ hollow dashed
  ```
- Chip states come straight from `splitfair-diner-chip`: assigned ⇒ fill + keyline + scale 1.08 + ring arc + `.selection` haptic; unassigned ⇒ clear fill, ink outline, no shadow, scale 1.0. Use one chip per diner in the strip, `assigned = item.assigneeIDs.contains(person.id)`.
- Keep the price **inside** the ring but not using the ring as its background — the ring is decoration + a "shared N ways" signal, the number is centered ink (`splitfair-split-ring`).
- Single-tap chips only: no modes, no steppers, no long-press. "Shared by all" cascade-fills every chip (staggered ~0.03s, one `.selection` haptic) — the visual is owned here, the mutation call in Task 6.5.
- Whole-card and each chip must be ≥44pt tap targets.

**Done when:**
- Every item in `store.bill.items` renders as a card with an ink SF-Mono tabular price wrapped in a `SplitRing`, a chip strip, and a "Shared by all" pill.
- The ring shows exactly `item.assigneeIDs.count` equal arcs (hollow dashed when zero), tinted by each assignee's diner hue in roster order.
- A chip reads assigned when its person is in `item.assigneeIDs` and hollow otherwise; the price stays pure ink in all states.

---

### Task 6.4 — Build inline Add-item entry
**Skills to load:** `splitfair-ios-platform`, `splitfair-cards`

**Why this matters:** Price entry is the one place a locale/parse bug can corrupt the money before it ever reaches the exact-cent engine. The skill is explicit: `.decimalPad` has no return key (so it needs a toolbar Done) and `Decimal.FormatStyle.parseStrategy` silently ignores trailing garbage — so you must parse with a **cents-accumulator** and add a strict re-format-and-compare check rather than trusting a naive `Double(text)`. Doing this inline (a card that expands in place) keeps the "no modal, no modes" feel of the screen and lets a user add several items in a row without leaving context.

**What to do:**
1. Create `SplitFair/Features/Bill/AddItemRow.swift`: a dashed "+ Add item" sticker-card (matching the item-row surface language) that, on tap, **expands inline** into an entry form — do not push a sheet or a new screen.
2. The expanded form has an optional **label** field (default placeholder auto "Item N", where N = `store.bill.items.count + 1`) and a **price** field configured `.keyboardType(.decimalPad)` with a **keyboard-toolbar Done** button (`.decimalPad` has no return key).
3. Parse the price with a **cents-accumulator** into `Cents` (Int minor units) — never `Double`. Route the parsed value through `MoneyEdge` (`Sources/BillCore/MoneyEdge.swift`) so the exponent is locale/currency-correct, and add the strict re-format-and-compare guard from the skill.
4. On Done (toolbar or a confirm control): call `store.addItem(Money(minorUnits: cents), label: label)` (auto "Item N" if the label is blank), then reset the field and keep the add-card ready so the next item can be entered immediately.
5. The keypad should already be presented when the card expands (`splitfair-status-flags` "Diners, no items" state), so entering the first item is one tap away.

**Technical details & suggestions:**
- Cents-accumulator (sidesteps the decimal-separator locale bug — each digit shifts and adds, so the OS decimal separator never matters):
  ```swift
  // strip to digits, fold into minor units by the currency exponent
  var cents = 0
  for ch in raw where ch.isNumber { cents = cents * 10 + Int(String(ch))! }
  // for a 2-exponent currency the accumulator already yields minor units
  ```
  Prefer the shared `MoneyEdge` parser so JPY (exponent 0) / BHD (exponent 3) behave; do not hardcode `× 100` or two decimals (`splitfair-ios-platform`, `splitfair-domain-model`).
- Strict guard: re-format the parsed `Cents` back to a string with the currency `FormatStyle` and compare, rejecting inputs whose parse dropped trailing garbage (`"12.50xyz"`), so a slip past `.decimalPad` can't inject a wrong amount.
- Toolbar Done:
  ```swift
  .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { commitItem() } } }
  ```
- Keep the draft label/price and expanded flag in view-local `@State`; only the committed item goes to the store via `store.addItem`. Auto-label: `label.isEmpty ? "Item \(store.bill.items.count + 1)" : label`.
- Reject a zero/blank price silently (don't add an empty item); a freshly added item starts unassigned, which the guard (Task 6.6) will immediately flag — that is intended.

**Done when:**
- Tapping the dashed add-item card expands it inline with a `.decimalPad` price field, a toolbar Done, and an optional label defaulting to "Item N"; no sheet or navigation occurs.
- Entering a price and pressing Done calls `store.addItem` with the correct `Cents`, and the new item appears in the list (unassigned) with the field reset for the next entry.
- Trailing-garbage and locale-separator inputs cannot produce a wrong amount (cents-accumulator + strict re-format check both pass their cases).

---

### Task 6.5 — Implement the assignment interaction and live recompute
**Skills to load:** `splitfair-state-store`, `splitfair-money-math`, `splitfair-motion-and-haptics`

**Why this matters:** This is signature moment #1 and the heart of the product. Assignment must feel instant and physical, and it must drive the money live — there is no Calculate button because `totals` is a **computed** property over the store (`splitfair-state-store`). Every split flows through the one `allocate()` primitive, so parts always sum to the whole to the exact cent (`splitfair-money-math`). If you cache totals, or mutate `bill.assigneeIDs` from the view directly, you reintroduce drift and break the `private(set)` firewall. The motion (fill spring + arc into the ring + `.selection` haptic) is what makes tapping a name feel like sticking a sticker on a check.

**What to do:**
1. Wire chip taps to the store intents only: a single tap calls `store.toggleAssignment(item: item.id, person: person.id)`; the "Shared by all" pill calls `store.assignToEveryone(item: item.id)`. Views never touch `bill` directly (it is `private(set)`).
2. Confirm live recompute: because `store.totals` is computed via `BillMath.compute(bill)`, the subtotal odometer (Task 6.6) and every ring update automatically on each mutation. Do not add any manual "recalculate" call or cache the result.
3. Add signature-#1 motion to the chip: on assign, fill the hue with `.spring(response: 0.32, dampingFraction: 0.7)`, scale `1.0 → 1.08 → 1.0`, and drop a `matchedGeometryEffect` arc from the chip onto the row's split-ring using the shared `@Namespace` created in `BillScreen` (Task 6.1).
4. Fire `.sensoryFeedback(.selection)` on each assign/unassign, and one `.selection` on "Shared by all" (which cascade-fills every chip staggered ~0.03s) — per the haptics map (`splitfair-ios-platform`, `splitfair-motion-and-haptics`).
5. Honor Reduce Motion: collapse the spring/scale/arc to a simple crossfade and set values instantly while keeping the haptic (`@Environment(\.accessibilityReduceMotion)`).

**Technical details & suggestions:**
- The split math is already correct in the engine — a shared item is `allocate(itemCents, [1] * k)` across its `k` assignees in roster order (`splitfair-money-math`, three-passes section). The view's only job is to keep `item.assigneeIDs` accurate; the arc order and cent-shares both follow roster order, so keep the ring's assignee mapping (Task 6.3) and the store in one order.
- Trigger the `.selection` haptic off a changing count so it fires per assignment:
  ```swift
  .sensoryFeedback(.selection, trigger: item.assigneeIDs.count)
  ```
- Matched-geometry arc: give the chip and the corresponding ring arc a shared `matchedGeometryEffect(id:in:)` so the filled arc appears to fly from the tapped chip into the ring (`splitfair-split-ring`, `splitfair-motion-and-haptics`). The ring's spring is `.spring(response: 0.32, dampingFraction: 0.7)` keyed on `assignees.count`.
- Toggle semantics: tapping an assigned chip removes that person; emptying a shared item's sharers, or removing the last assignee, leaves the item **unassigned** (zero assignees), which the guard flags — never silently drop the item (`splitfair-status-flags`, `splitfair-state-store`).
- `deletePerson` (if reachable from this screen) must drop that person from every item's `assigneeIDs`; any item left empty becomes unassigned. That logic lives in the store, not the view.
- Never store `totals`; never sum independently-rounded parts to fake a subtotal. Read `store.totals` (`splitfair-money-math` invariant).

**Done when:**
- Tapping a chip toggles that person via `store.toggleAssignment`; "Shared by all" assigns everyone via `store.assignToEveryone`; no view mutates `bill` directly.
- The subtotal and every ring update live on each tap with no Calculate button, and per-person shares of shared items sum to the item's exact cents (via `allocate`).
- Assign shows the fill spring + 1.08 scale + arc-into-ring and a `.selection` haptic; under Reduce Motion these become an instant crossfade with the haptic retained.

---

### Task 6.6 — Build the footer rail, odometer and unassigned guard
**Skills to load:** `splitfair-status-flags`, `splitfair-buttons`

**Why this matters:** This is the screen's safety net and its handoff. The footer rail is the app's **single** Liquid-Glass surface — the whole rest of the UI is matte ink-on-paper, so this one glass element must be the only one, and the subtotal digits must sit on an **opaque cream pill** so no numeral composites over glass (which would hurt legibility and the ink-on-paper rule). The unassigned guard is the reason money never gets lost: if Next navigated while items were unassigned, those items would silently vanish from everyone's share. The guard blocks navigation for real (it does not fake it) and gives three simultaneous, non-color signals so it works in grayscale and for CVD users.

**What to do:**
1. Create the footer rail (e.g. `SplitFair/Features/Bill/FooterRail.swift`, or reuse the DesignSystem footer component): a floating bottom rail using `.glassEffect` with a `.regularMaterial` fallback and a `PerforationEdge` top so the total "tears off" like a check stub. Under Reduce Transparency, make it opaque cream (`splitfair-status-flags`, `splitfair-motion-and-haptics`).
2. **Left of the rail:** the live subtotal — "Subtotal $75.50" in SF Rounded Black with `.contentTransition(.numericText())` so digits roll on every change, tabular so nothing reflows — sitting on an **opaque cream pill** so no digit composites over the glass. Bind it to `store.totals` (the assigned subtotal), never a cached value.
3. **Right of the rail:** the Tangerine `PrimaryButton` labeled "Next: Tax & Tip →" (opaque even though it sits on glass), with its press physics (shadow collapse x+3 y+4 → x+1 y+1, 3pt nudge down, `.selection`).
4. Compute the **unassigned set** — the reusable guard covering all three cases at once: never-assigned items, a shared item emptied of sharers, and a deleted person's solo items (`splitfair-status-flags`, `splitfair-state-store`). Show a running count in the footer ("Nachos + 1 unassigned"), and flag each offending row with the **three simultaneous signals**: amber+ink hazard-tape left edge (replacing the 4pt ink rule), an amber `exclamationmark.triangle.fill`, and the text "tap a name". The offending rows' rings show the hollow dashed state.
5. Wire Next behavior on the count:
   - **Unassigned remain:** the button is disabled/desaturated with label "Assign all items first"; tapping it does **not** navigate — instead the ⚠ symbols `symbolEffect(.bounce)`, `.sensoryFeedback(.warning)` fires, and the `ScrollViewReader` (Task 6.1) scrolls the first offending row into view.
   - **All assigned:** Next is enabled and is a plain `NavigationLink { TotalsScreen() }` that pushes Screen 2.

**Technical details & suggestions:**
- Subtotal odometer:
  ```swift
  Text(Decimal(store.totals.assignedSubtotalCents) / 100,
       format: .currency(code: store.bill.currency.code))
      .font(.money(/* SF Rounded Black */)).monospacedDigit()
      .contentTransition(.numericText())
      .padding(.horizontal, 14).padding(.vertical, 8)
      .background(Capsule().fill(Color.cream))   // opaque pill — no digit over glass
  ```
  Wrap the value change in `withAnimation(.spring)` (or rely on the numericText transition) so digits roll like a receipt printer (`splitfair-motion-and-haptics`).
- Guard set (one reusable computation): `let unassigned = store.bill.items.filter { $0.assigneeIDs.isEmpty }`. This naturally covers all three cases because emptying sharers or deleting a person's solo owner both leave `assigneeIDs` empty — do not write three separate checks. Drive both the footer count and each row's flag off this one set.
- Blocked-Next (do not fake navigation — `splitfair-status-flags`, `splitfair-buttons`):
  ```swift
  if unassigned.isEmpty {
      NavigationLink { TotalsScreen() } label: { PrimaryButton(title: "Next: Tax & Tip →") }
  } else {
      Button { warnPulse.toggle(); proxy.scrollTo(unassigned.first!.id, anchor: .center) } label: {
          PrimaryButton(title: "Assign all items first", enabled: false)
      }
      .sensoryFeedback(.warning, trigger: warnPulse)
  }
  ```
  The ⚠ symbols in the flagged rows bounce via `.symbolEffect(.bounce, value: warnPulse)`.
- The rail is the **only** glass in the app — do not add glass to any card, chip, or button (the `PrimaryButton` stays opaque Tangerine). Reduce Transparency ⇒ opaque cream rail.
- Never use danger-red here; danger-red is reserved for Clear (Screen 2). The hazard-tape amber is the unassigned signal, distinct from destructive red.

**Done when:**
- The footer is a single floating glass rail with a `PerforationEdge` top, a `.numericText()` subtotal odometer on an opaque cream pill (left), and the opaque Tangerine "Next" CTA (right); Reduce Transparency makes it opaque cream.
- While any item has zero assignees, the footer shows a running unassigned count, each offending row carries the amber hazard-tape edge + ⚠ + "tap a name", and its ring is hollow dashed.
- Tapping Next with unassigned items does not navigate — the ⚠ bounces, a `.warning` haptic fires, and the first offender scrolls into view; once every item is assigned, Next enables and pushes `TotalsScreen` via a plain `NavigationLink`.
