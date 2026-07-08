# EPIC 07 — Screen 2 — Tax, Tip & Totals

> Compose the payoff screen: enter tax/tip, watch per-person totals recompute and reconcile with a SETTLED stamp, round up, copy, and clear.

## What this epic is for

This epic assembles Screen 2 — the settle-up screen — from the store and the component library built in EPICs 03–05. Tax and tip flow through `BillMath.compute` so that every division of money is closed by the single `allocate()` primitive, guaranteeing the per-person totals sum to the grand total to the exact cent. The screen is where the app keeps its central promise ("you're charged right"): the reconciliation banner stamps SETTLED on the exact reconciled integer-cent value, the display-only round-up shows an honest surplus without ever becoming the source of truth, and Copy/Share/Clear close the loop. Everything is live — no "Calculate" button anywhere.

## Where we are before starting (starting state)

- Screen 1 (`Features/Bill/BillScreen.swift`) works: a diner roster, assigned item rows, a live subtotal, the unassigned hazard-tape guard, and a `NavigationLink` that pushes to Screen 2 only when everything is assigned.
- `BillStore` (`SplitFair/App/BillStore.swift`) is a `@MainActor @Observable` object injected at the App root, exposing `bill` (`private(set)`), a computed `totals: BillResult`, and intents including `setTax(_:)`, `setTip(_:)`, and `clear()`.
- `BillCore` is complete and tested: `Money`, `allocate()`, `BillMath.compute`, `Summary`, and the `$97.20` acceptance bill are green via `swift test`.
- The component library exists with light/dark `#Previews`: the tip controls, `PersonTotalCard`, the `ReconciliationBar`/banner, the three buttons, and the status treatments.
- The design system exists: color tokens (`Color.ink`, `Color.acidLime`, `Color.tangerine`, success green), the Fraunces + SF Mono type scale (`Font.money(_:)`), the hard offset shadow modifier and `.card()`, `PerforationEdge`, and the diner palette.

## What we will have after finishing (definition of done)

- A working `TotalsScreen` reachable from Screen 1 with a back control, reading `store.totals` live.
- A tax dollar field (default `$`, with a `$`/`%` toggle) that feeds `store.setTax(_:)` using the exact printed amount, never a recomputed percent.
- Tip preset chips `[15][18][20][25][Custom]` wired to `store.setTip(_:)`, a custom inline field, a live Acid-Lime readout pill bound to `store.totals` tip cents rolling via `.numericText()`, and a pre-tax/total base toggle defaulting to pre-tax.
- Per-person `PersonTotalCard`s in bento order (biggest ower first, slightly larger), ink totals, tapping to expand a receipt-style itemized + prorated tax/tip ledger tinted in each person's hue.
- A reconciliation banner showing the grand total, a SETTLED ✓ rubber-stamp that thunks in and re-fires on tip change, the word "SETTLED", a count-up capped by one `.success` haptic, and a VoiceOver announcement.
- A display-only round-up toggle layered on the reconciled totals showing the honest surplus ("Adds $X across the table → tip"), never the source of truth.
- A `ShareLink(item: summaryText)` built from the pure `Summary`, an optional pasteboard Copy with a "Copied ✓" toast, and a Clear bill button that opens the single confirm dialog wired to `store.clear()`.
- `Σ perPerson.total == assignedSubtotal + taxCents + tipCents == grandTotal` holds for every input, including when the tip changes.

## Dependencies

- Depends on: EPIC 06 (Screen 1 works and navigates here) and the EPIC 05 component library (tip controls, cards, reconciliation banner).
- Enables: EPIC 08 (Motion, Haptics & Accessibility) — which does the dedicated motion/haptics/a11y pass over both now-functional screens.

---

## Tasks

### Task 7.1 — Scaffold TotalsScreen and back navigation
**Skills to load:** `splitfair-app-architecture`

**Why this matters:** Screen 2 is the second and final screen of a deliberately two-screen app. The architecture rule is Model-View with `@Observable` and exactly one shared `BillStore` — both screens read the same store so there is a single source of truth. If you fracture this into a per-screen ViewModel or introduce a `NavigationPath`/route enum, you split the one bill into competing sources of truth and drift becomes possible. Get the scaffold's ownership and layout right and every later task simply reads `store.totals`.

**What to do:**
1. Create `SplitFair/Features/Totals/TotalsScreen.swift` with `struct TotalsScreen: View`.
2. Read the shared store with `@Environment(BillStore.self) private var store`. Do **not** construct a `BillStore` here — it is created once at the App root (`@State private var store = BillStore()`) and injected via `.environment(store)`.
3. Confirm the navigation entry: Screen 1 pushes here with a single plain `NavigationLink { TotalsScreen() } label: { PrimaryButton(...) }` inside the existing `NavigationStack`. No `NavigationPath`, no route enum — one `NavigationLink` is enough.
4. Lay out the screen as loud-frame / calm-center: a scrolling reading column (tax/tip controls → per-person cards) with a calm warm Canvas background, and a bottom glass footer rail carrying the reconciliation banner and the action buttons.
5. Add the back affordance. The system back button from the `NavigationStack` push is sufficient; give it a clear title ("Tax & Tip" or "Settle up") via `.navigationTitle(...)`. Do not add a custom back button that bypasses the stack.
6. Wire the layout to read `store.totals` (a `BillResult`) so subtotal/tax/tip/grand-total surfaces recompute live — never add a "Calculate" button.

**Technical details & suggestions:**
- File path: `SplitFair/Features/Totals/TotalsScreen.swift` (the `Features/Totals/` folder also holds `TaxTipControls`, `PersonTotalCard`, `ReconciliationBar`).
- Sketch:
  ```swift
  struct TotalsScreen: View {
      @Environment(BillStore.self) private var store
      var body: some View {
          ScrollView {
              VStack(spacing: 20) {
                  TaxTipControls()          // Task 7.2
                  PersonTotalCards()        // Task 7.3
              }
              .padding()
          }
          .background(Color.canvas)         // warm cream / aubergine, never white/gray
          .safeAreaInset(edge: .bottom) {
              VStack(spacing: 12) {
                  ReconciliationBar()       // Task 7.4 + 7.5
                  TotalsActions()           // Task 7.6
              }
              .padding()
              // the ONE glass rail; opaque cream fallback under Reduce Transparency (EPIC 08)
          }
          .navigationTitle("Settle up")
      }
  }
  ```
- Keep transient UI state (expanded card ids, custom-tip focus, toast visibility) as view-local `@State`/`@FocusState`, never on the store.
- Reject as over-engineering: a `TotalsViewModel`, a DI container, a coordinator. If you feel the pull toward one, the task is simpler than the pattern.

**Done when:** Navigating from Screen 1 pushes `TotalsScreen`; it reads the shared `store` via `@Environment(BillStore.self)`; the system back button returns to Screen 1 with the bill intact; the screen renders the loud-frame/calm-center layout with a bottom rail and compiles with no separate ViewModel or navigation-path machinery.

---

### Task 7.2 — Wire the Tax and Tip controls to the store
**Skills to load:** `splitfair-tip-controls`, `splitfair-money-math`

**Why this matters:** This is the entry zone that drives every per-person number. Two money rules are non-negotiable here. First, tax is the **exact printed amount off the receipt** — never recomputed from a percentage — because sales tax is not a clean percent of your subtotal (exemptions, rounding on the register). Second, a tip percentage must be converted to cents **exactly once** (`tipCents = Int((assignedSubtotal * pct).rounded())`) before it is fed to `allocate()`; a naive `Double` percent creates a second rounding site and a classic off-by-a-cent bug that `allocate()`'s own coverage will never catch. Presets over typing keeps entry fast; the live lime pill is the single "money in motion" moment.

**What to do:**
1. Create `SplitFair/Features/Totals/TaxTipControls.swift`.
2. **Tax card (`taxcard`):** label "TAX" + a right-aligned SF Mono field showing the dollar amount, defaulting to `$`, with a small `$`/`%` segmented toggle. Use `.decimalPad` + a keyboard-toolbar Done button (decimalPad has no return key), and parse via the cents-accumulator / `MoneyEdge` path — do not build a `Money` from a raw `Double`. Feed the parsed value to `store.setTax(Money(cents))`. When the `%` mode is used, it is only an input convenience: resolve to the exact dollar cents once and store that; downstream code always consumes the printed cents, never a live percent.
3. **Tip preset chips:** a row `[15][18][20][25][Custom]` as clay-pressable stamps — `RoundedRectangle` r=16, 2pt ink keyline, pressable depth (shadow shrinks on press) + `.sensoryFeedback(.selection)`. Unselected = surface fill + ink label; selected = **Tangerine fill, white label**, spring pop, keyline kept. Each preset calls `store.setTip(.percent(pct))`; mark selected via `store.bill.tip == .percent(pct)`.
4. **Custom:** tapping Custom opens an **inline** numeric field (never a modal) that calls `store.setTip(.percent(n))` or `.fixed(Money(...))` as appropriate.
5. **Live readout pill (the one lime element):** beside the presets, a `= $11.79` pill in **Acid-Lime with ink text**, driven by `store.totals` tip cents, rolling via `.contentTransition(.numericText())`. Lime always carries ink text and appears nowhere else.
6. **Base toggle:** a tiny `pre-tax` / `total` segmented control, **default = pre-tax subtotal**. Show the chosen base in the UI so users trust the math; the choice feeds `BillMath.resolvedTip`. Changing it recomputes live.

**Technical details & suggestions:**
- Tip chip + pill sketch (grounded in the skill):
  ```swift
  HStack {
      ForEach([15,18,20,25], id: \.self) { pct in
          Button("\(pct)%") { store.setTip(.percent(pct)) }
              .buttonStyle(TipChip(selected: store.bill.tip == .percent(pct)))
      }
      Spacer()
      Text(Decimal(store.totals.tipCents) / 100, format: .currency(code: store.bill.currency.code))
          .font(.money(19)).foregroundStyle(Color.ink)
          .padding(8)
          .background(RoundedRectangle(cornerRadius: 14).fill(Color.acidLime))
          .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 2))
          .contentTransition(.numericText())
  }
  ```
  (Read the actual tip-cents accessor off `BillResult`/`BillMath`; the skill shows `store.totals.tipCents`.)
- Currency formatting: use `.currency(code: store.bill.currency.code)` + `.monospacedDigit()` — never hardcode `$` or 2 decimals, so JPY(0)/BHD(3) reconcile.
- `resolvedTip` in `BillCore` converts `.percent` → cents once, using the base the toggle selects (pre-tax subtotal by default, post-tax when toggled). Do not duplicate that math in the view.
- Every chip/toggle ≥ 44pt tap target.
- Pitfall: `Decimal.FormatStyle.parseStrategy` silently ignores trailing garbage (`"12.50xyz"` → `1250`); `.decimalPad` mostly prevents it, but keep the strict re-format-and-compare check from the edge parser.

**Done when:** Typing a tax dollar amount updates every per-person total via `store.setTax`; the `$`/`%` toggle stores exact printed cents (never a live percent); tapping a preset turns it Tangerine/white and updates the totals; Custom opens inline; the lime pill shows `store.totals` tip cents and rolls via numericText; the base toggle defaults to pre-tax and switching it recomputes live; all controls are ≥44pt.

---

### Task 7.3 — Render the per-person total cards
**Skills to load:** `splitfair-cards`

**Why this matters:** These cards are where each person sees exactly what they owe and — when expanded — proof of how it was computed (their items + their prorated share of tax and tip). The load-bearing rule is **the total is always ink**, never a diner hue or accent: color lives on the person's chip, not on the number, so the eye reads money as money. Bento ordering (biggest ower first, slightly larger) gives the screen an honest visual hierarchy. Get the expand breakdown right and the reconciliation banner in 7.4 is believable because the parts are visible.

**What to do:**
1. Create `SplitFair/Features/Totals/PersonTotalCard.swift` (if not already provided by EPIC 05) and a `PersonTotalCards` container in the Totals feature.
2. Build the collapsed card: `RoundedRectangle` r=26 + `.card()` (matte surface + hard offset shadow). Header = the person's `DinerChip` (color sticker + initials + notch + texture) + name 17pt semibold. Right = **SF Rounded Black 40pt total via `Font.money(40)`, `.monospacedDigit()`, `Color.ink`** + a ⌄ chevron. Collapsed height ≥ 64pt; the whole card is the tap target.
3. Source the data from `store.totals.perPerson[person.id]` (a `Breakdown` with `subtotal`, `tax`, `tip`, `total`). Map each `Person` (which carries `colorIndex`) to its diner color from the palette.
4. **Bento ordering:** sort the cards by `Breakdown.total` descending so the biggest ower sits first and render it slightly larger.
5. **Expand:** tapping toggles a view-local `expanded` binding with a spring; the chevron rotates 180°. When expanded, reveal that person's itemized lines (their personal items + their share of each shared item) plus prorated tax and tip, in **SF Mono 15pt**, each row faintly tinted (~8%) in that person's hue, with a dotted-leader label→value layout and tabular values.
6. Use a shared `@Namespace` + `matchedGeometryEffect` for the expand so it reads as the total growing into its breakdown. Respect Reduce Motion (EPIC 08 finalizes; here just gate the spring behind `@Environment(\.accessibilityReduceMotion)` with a crossfade fallback).

**Technical details & suggestions:**
- Sketch (from the skill):
  ```swift
  struct PersonTotalCard: View {
      let name: String; let total: Money; let color: Color; @Binding var expanded: Bool
      var body: some View {
          VStack(alignment: .leading, spacing: 12) {
              HStack(spacing: 13) {
                  DinerChip(/* color, initials, notch, texture */)
                  Text(name).font(.system(size: 17, weight: .semibold)); Spacer()
                  Text(Decimal(total.minorUnits) / 100, format: .currency(code: "USD"))
                      .font(.money(40)).monospacedDigit().foregroundStyle(Color.ink)   // ink, never colored
                  Image(systemName: "chevron.down").rotationEffect(.degrees(expanded ? 180 : 0))
              }
              if expanded { /* item shares + prorated tax + tip, SF Mono 15, ~8% hue tint, dotted leaders */ }
          }
          .card()
          .onTapGesture { withAnimation(.spring) { expanded.toggle() } }
      }
  }
  ```
- Use `store.bill.currency.code` in the `.currency(code:)` format, not a literal.
- The per-person breakdown values come straight from `BillResult`; do not recompute item shares in the view (that would re-introduce a second rounding path). Read the item-share/tax/tip lines from the `Breakdown` (and, if the ledger needs per-item detail, from a `BillMath` accessor) rather than dividing money in SwiftUI.
- Track expanded state as `@State private var expandedIDs: Set<UUID>` on the container, not on the store.

**Done when:** One card renders per person from `store.totals.perPerson`; totals are SF Rounded Black 40pt ink with `.monospacedDigit()`; cards are bento-ordered biggest-first with the top card slightly larger; tapping expands into an SF Mono 15pt itemized + prorated tax/tip ledger tinted ~8% in the person's hue with dotted leaders; collapsed height ≥64pt; the whole card is tappable; the total is never a diner hue.

---

### Task 7.4 — Wire the reconciliation banner live
**Skills to load:** `splitfair-reconciliation-banner`, `splitfair-motion-and-haptics`

**Why this matters:** This is the emotional climax and the app's core proof: the parts equal the whole. The banner must animate the **exact reconciled integer-cent value** the math produces — never a rounded or faked number — because the entire trust premise ("you're charged right") collapses if the stamp ever shows a number that doesn't match the sum of the cards. Green is **reserved** for this settled state and must never be reused for "owed." And because tax/tip changes recompute everything, the stamp must re-fire whenever the tip changes and still reconcile — this is the visible guarantee of the structural invariant.

**What to do:**
1. Create `SplitFair/Features/Totals/ReconciliationBar.swift` (or finish the EPIC 05 component) and place it in the bottom rail above the actions.
2. Render the stub as a **perforated tear-edge** (`PerforationEdge` shape) in **success green** (`#1FB25A` light / `#34D07A` dark).
3. Text: "Totals add up to $97.20" — the grand total in SF Rounded Black, `.monospacedDigit()` — bound to `store.totals.grandTotal`. Carry the word **"SETTLED / adds up"** so green is never the only signal.
4. Stamp: a `checkmark.seal.fill` ✓ rubber-stamp rotated ~−9° that **thunks in** via `PhaseAnimator` (scale 1.4 → 0.95 → 1.0 + slight rotation).
5. Count-up: the grand total counts up on entry, capped by a **single** `.sensoryFeedback(.success)` — not one per digit.
6. **Re-fire on tip change:** drive the stamp/count-up off a trigger value that changes when the reconciled total changes (e.g. `store.totals.grandTotal.minorUnits` and the current tip), so selecting a new preset re-runs the thunk and count-up. It always reconciles again.
7. Failure path: if totals ever fail to reconcile, flip to amber + ⚠ and name the gap. With correct `allocate()`-based math this never fires, but wire it so the code is honest rather than assuming success.
8. Post a VoiceOver announcement "Totals add up, settled." on entry/re-fire (finalized in EPIC 08).

**Technical details & suggestions:**
- Trigger wiring:
  ```swift
  .sensoryFeedback(.success, trigger: store.totals.grandTotal.minorUnits)
  .contentTransition(.numericText())   // count-up rolls, tabular so nothing reflows
  ```
- The reconciliation check is structural: assert/verify `Σ perPerson.total == assignedSubtotal + taxCents + tipCents == grandTotal`. Read these off `BillResult` (`assignedSubtotal`, `grandTotal`, per-person `Breakdown.total`); the amber failure branch should compute the gap only for display, never to "correct" the math.
- Under Reduce Motion: the stamp just fades in with the haptic and the number sets instantly (`@Environment(\.accessibilityReduceMotion)`); finalize in EPIC 08 but gate it here.
- Do not reuse success green anywhere else on the screen (owed totals stay ink).
- Anchor: with the acceptance bill the banner reads "$97.20" and the three cards sum to it exactly (Ana 20.39 / Ben 51.93 / Cy 24.88).

**Done when:** The banner shows the live `store.totals.grandTotal` with the word "SETTLED" and a ✓ stamp; the stamp thunks in via PhaseAnimator and the total counts up capped by one `.success` haptic; changing a tip preset re-fires the stamp and the totals still reconcile exactly; green appears only here; the acceptance bill reads $97.20 matching the card sum.

---

### Task 7.5 — Implement round-up (display-only)
**Skills to load:** `splitfair-money-math`, `splitfair-reconciliation-banner`

**Why this matters:** Round-up is a convenience for people who like to hand over whole dollars, but it is a trap if done wrong: the moment a rounded number becomes the source of truth, the parts stop summing to the whole and the SETTLED stamp lies. The rule is absolute — round-up is **display-only, layered on the exact reconciled integer-cent totals**, and it must show the **honest surplus** (the extra dollars go to tip) rather than pretending the bill changed. Done right it adds trust; done wrong it destroys the one invariant the whole app exists to protect.

**What to do:**
1. Add a single toggle "Round each person up to $1." adjacent to the reconciliation banner, backed by a view-local `@State private var roundUp = false`.
2. When on, compute each person's rounded-up display total as the nearest dollar **≥** their exact total: `roundedCents = ((exactCents + 99) / 100) * 100` (integer math on `Money.minorUnits`), applied over `store.totals.perPerson`. This is a **display transform only** — never write it back to the store or to `bill`.
3. Compute the honest surplus = `Σ(roundedCents − exactCents)` and show it as the self-healing note: "Adds $X across the table → tip" (SF Mono 13pt). This mirrors the banner's rounding note "rounding balanced · +$0.02 → tip".
4. Fire `.sensoryFeedback(.impact(.soft))` on the toggle (the round-up haptic from the map).
5. Keep the reconciliation banner's underlying math on the exact reconciled totals; the round-up surplus is presented as going to tip, so the displayed grand total + surplus still tells a coherent, honest story. The parts never silently disagree with the whole.
6. When the toggle is off, the cards and banner show the exact reconciled cents unchanged.

**Technical details & suggestions:**
- Integer round-up helper (no float, ever):
  ```swift
  func roundedUp(_ cents: Cents) -> Cents { ((cents + 99) / 100) * 100 }   // nearest dollar, never below
  let surplus = store.totals.perPerson.values.reduce(0) { $0 + (roundedUp($1.total.minorUnits) - $1.total.minorUnits) }
  ```
- The per-person card total displayed while round-up is on uses `roundedUp(breakdown.total.minorUnits)`; the exact value is still what the store holds and what Copy/Share export by default (decide and document: export exact reconciled totals; the round-up is an on-screen aid).
- Surplus display uses the same currency `FormatStyle`; format `Decimal(surplus)/100`.
- Pitfall: do **not** run the rounded numbers back through `allocate()` or store them — that would make round-up the source of truth and break `Σ parts == whole`. The reconciled integer-cent totals from `BillMath.compute` remain the single truth.
- Respect the reconciliation-banner rule: the surplus is framed as "→ tip", consistent with the self-healing note.

**Done when:** Toggling round-up on shows each per-person card rounded up to the nearest whole dollar (never below the exact amount) and a note "Adds $X across the table → tip" with `X` = the exact summed surplus; a `.impact(.soft)` haptic fires; the store's `bill` and `totals` are unchanged (verify the reconciled cents are untouched); toggling off restores exact cents; no rounded value is ever fed back into the math.

---

### Task 7.6 — Add Copy/Share summary and Clear bill
**Skills to load:** `splitfair-ios-platform`, `splitfair-buttons`, `splitfair-persistence`

**Why this matters:** These are the exit actions. Sharing must produce a summary that matches the on-screen math exactly, so it is built from the **pure `Summary` builder** in `BillCore` (the same currency `FormatStyle`), not re-serialized in the view — otherwise the shared text could disagree with the screen and re-introduce a rounding path. Clear bill is destructive and irreversible for an app that keeps only the current bill; it is the **only** control that opens a confirm dialog, and it must correctly cancel the pending debounced save before deleting the file (the `bill = .empty` assignment itself schedules a save that would otherwise resurrect the data).

**What to do:**
1. Create `SplitFair/Sharing/ShareSummary.swift` (view-side glue) that gets the plain-text summary from `BillCore`'s pure `Summary.swift` builder, passing the current `bill`/`totals` and the currency code.
2. Add a `ShareLink(item: summaryText)` as the primary share action (this surfaces Copy + Messages + the share sheet). Style it as the outlined **secondary** button ("Copy summary" / share) — surface fill, 2pt ink keyline, ink label, small/no offset shadow. Reserve the deep offset shadow for the one loud primary CTA.
3. Add an optional one-tap pasteboard Copy using `UIPasteboard.general.string = summaryText` (the only non-view UIKit touchpoint) with a "Copied ✓" toast. The label says exactly what happens.
4. Add the **Clear bill** destructive button: ink keyline + **danger-red label** (`#E5453C` light / `#FF5A50` dark) + trash SF Symbol, low emphasis. It is the only control that opens a `.confirmationDialog`. Never use danger-red anywhere else.
5. Wire the dialog's confirm action to `store.clear()` — which sets `bill = .empty`, **cancels the pending debounced save**, and deletes the JSON file (`current-bill.json` in Application Support). Fire `.sensoryFeedback(.success)` on Clear (per the haptics map).
6. After clearing, navigation should return to an empty Screen 1 (the store is now `.empty`); the back stack + observation handle this since both screens read the same store.

**Technical details & suggestions:**
- Summary is pure: build the text through the same currency `FormatStyle` used on screen (`Decimal(cents)/100, format: .currency(code: bill.currency.code)`), so the export matches the cards to the cent. Do not format money by hand in the view.
- Buttons sketch (danger token from the skill):
  ```swift
  Button(role: .destructive) { showClearDialog = true } label: {
      Label("Clear bill", systemImage: "trash").foregroundStyle(Color.danger)   // #E5453C / #FF5A50
  }
  .confirmationDialog("Clear this bill?", isPresented: $showClearDialog, titleVisibility: .visible) {
      Button("Clear bill", role: .destructive) { store.clear() }
      Button("Cancel", role: .cancel) { }
  }
  .sensoryFeedback(.success, trigger: /* cleared */)
  ```
- Persistence rule to honor: `clear()` must cancel the pending debounced save first, because assigning `bill = .empty` triggers `didSet → scheduleSave()`; without the cancel a stale save can race the file delete. This lives in `BillStore`/`BillDraftStore` — the view just calls `store.clear()`.
- Toast: a simple view-local `@State private var showToast` with an auto-dismiss after ~1.5s; keep it as transient view state.
- Haptics via `.sensoryFeedback` only (no CoreHaptics); it respects system settings automatically.
- Privacy posture unchanged: no network, no ATT, `ITSAppUsesNonExemptEncryption = NO` — sharing is fully local via the OS share sheet.

**Done when:** A `ShareLink(item:)` shares a plain-text summary built from the pure `Summary` builder that matches the on-screen totals to the cent; an optional Copy writes to the pasteboard and shows a "Copied ✓" toast; the Clear bill button is danger-red with a trash icon and is the only control with a confirm dialog; confirming calls `store.clear()`, which empties the bill, cancels the pending save, and deletes `current-bill.json`, firing a `.success` haptic; after clearing, Screen 1 shows an empty bill.
