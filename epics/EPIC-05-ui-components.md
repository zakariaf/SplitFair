# EPIC 05 — Reusable UI Components

> Build the component library — chips, split-ring, buttons, cards, tip controls, the reconciliation banner, and status treatments — each previewed in isolation.

## What this epic is for
Turn the design tokens from EPIC 04 into a set of reusable, self-previewing SwiftUI components so that the two screens in EPIC 06 and EPIC 07 become pure composition rather than styling work. Each component encapsulates its own visual language (loud-frame/calm-center, ink-on-paper numbers, hard offset shadows, one glass rail) and its own state signals (≥3 grayscale-legible channels per meaning). Every component ships with a light and dark `#Preview` so it can be verified in isolation before any screen exists. No screen logic, navigation, or persistence is written here — only the presentational building blocks and their bindings/callbacks.

## Where we are before starting (starting state)
- EPIC 04 is done: `SplitFair/DesignSystem/` contains the token layer and the shape/depth layer.
- Asset-Catalog color tokens exist (light/dark) surfaced via `Color+Tokens.swift`: `.canvas`, `.surface`, `.ink`, `.inkSoft`, `.divider`, `.tangerine`, `.acidLime`, `.success`, `.warning`, `.danger`, plus per-diner hues.
- `Font+Tokens.swift` provides `.money(_)`, `.ledger(_)`, `.display(_)` and the bundled Fraunces font is registered.
- The fixed diner palette data exists (10 colors, each with a `NotchStyle`, `ChipTexture`, and pre-paired label ink), exposed as a `DinerStyle`/`DinerPalette` type.
- `Modifiers.swift` provides `BrutalShadow` (solid ink rect, offset x+3 y+4, 0 blur) and the `.card()` / `.sticker(_)` / `.perforatedTop()` helpers.
- `Shapes.swift` provides the custom `Shape`s: `PerforationEdge`, `CornerNotch`, `SplitRing` geometry, the dot-matrix `Canvas`, and drifting-blob background.
- A `Theme` and a `#Preview` token gallery exist.
- `BillCore` is a complete, tested pure-domain package (`Money`/`Cents`, `allocate`, `BillMath.compute`, `Summary`), and a `@MainActor @Observable BillStore` with a computed `totals` property and persistence is wired at the App root.
- No reusable UI components exist yet; the two screens are not composed.

## What we will have after finishing (definition of done)
- A `SplitFair/DesignSystem/` component library, each component with a working light **and** dark `#Preview`:
  - `DinerChip` — die-cut sticker capsule with hollow vs assigned states and the assign spring + `.selection` haptic.
  - `SplitRing` — ink-bordered ring dividing into N equal arcs in roster order, hollow-dashed when unassigned.
  - Three buttons: `PrimaryButton` (Tangerine CTA), `SecondaryButton` (outlined), `DangerButton` (Clear, with the sole confirm dialog).
  - `ItemRow` and `PersonTotalCard`.
  - `TipControls` (tax field, preset chips, Acid-Lime live readout pill, base toggle).
  - `ReconciliationBanner` (perforated success stub, SETTLED ✓ stamp, count-up, amber failure path).
  - Status treatments: the three-signal `UnassignedFlag` hazard-tape, the `EmptyState` views, and the one glass `FooterRail`.
- All components are pure presentation: they take value inputs plus `@Binding`/closures; none reach into persistence or `BillCore.compute` directly (they display `Money`/`Cents` values passed in).
- Every money value renders in `.money(_)`/`.ledger(_)` with `.monospacedDigit()`, ink-on-surface, never on a chip/gradient/glass.
- Every stateful component carries ≥3 grayscale-legible signals and is legible in a grayscale preview pass.
- The project builds; all `#Preview`s render in both appearances in the Xcode canvas.

## Dependencies
- Depends on: EPIC 04 — Design System Foundation (tokens, fonts, shapes, palette, theme, modifiers).
- Enables: EPIC 06 — Screen 1 — The Bill (which composes `DinerChip`, `ItemRow`, the footer rail and empty states) and EPIC 07 — Screen 2 — Tax, Tip & Totals (which composes `TipControls`, `PersonTotalCard`, `ReconciliationBanner`).

---

## Tasks

### Task 5.1 — Build the DinerChip component
**Skills to load:** `splitfair-diner-chip`, `splitfair-shapes-and-depth`, `splitfair-color-system`

**Why this matters:** The `DinerChip` is the app's core identity element and the whole tap-to-assign interaction. If identity rests on color alone it collapses in grayscale and for colorblind users; if the assigned/unassigned states aren't visually distinct across four channels, users can't tell who's on an item and money gets misassigned. Getting the four redundant channels (fill, keyline, initials, notch, texture) and the state distinction right here means every roster bar, item-row chip strip, and person avatar downstream just reuses this one view.

**What to do:**
1. Create `SplitFair/DesignSystem/DinerChip.swift`.
2. Model the input as a `DinerStyle` (from `DinerPalette`: `color`, `initials`, `notch: NotchStyle`, `texture: ChipTexture`, and the pre-paired label ink `color.pairedInk`) plus an `assigned: Bool` flag.
3. Render a `Capsule`, `minWidth: 44, minHeight: 44`, carrying all four redundant identity channels: (a) fill = the diner's hue, (b) 2pt ink/cream keyline, (c) centered initials in the pre-paired white/ink that clears 4.5:1, (d) a unique `CornerNotch` silhouette, plus a per-diner micro-texture overlay at ~12% opacity clipped to the capsule.
4. Implement the two in-row states plus the roster-header state:
   - **Roster header:** always solid fill + `BrutalShadow`.
   - **Unassigned (in a row):** clear fill, ink outline, ink initials, no shadow, `scaleEffect(1.0)`.
   - **Assigned (in a row):** hue fill, keyline visible, `scaleEffect(1.08)` via `.spring(response: 0.32, dampingFraction: 0.7)`, `BrutalShadow` present.
5. Wire the assign feedback: `.sensoryFeedback(.selection, trigger: assigned)` so a toggle emits the selection haptic.
6. Add the add-person affordance as a sibling view (`AddPersonChip`): a dashed-outline capsule with a `plus.circle` SF Symbol (bundled iconography only), sized ≥44×44, that the roster will use to bounce in a new solid chip.
7. Add light and dark `#Preview`s showing a hollow chip, an assigned chip, and the add-person chip side by side; include a grayscale check note.

**Technical details & suggestions:**
- Start from the skill's sketch:
  ```swift
  struct DinerChip: View {
      let style: DinerStyle          // color, initials, notch, texture, pairedInk
      var assigned = true
      var body: some View {
          Text(style.initials).font(.system(size: 15, weight: .semibold, design: .rounded))
              .foregroundStyle(assigned ? style.color.pairedInk : Color.ink)
              .padding(.horizontal, 15).frame(minWidth: 44, minHeight: 44)
              .background(Capsule().fill(assigned ? style.color : .clear))
              .overlay(TextureOverlay(style.texture).opacity(assigned ? 0.12 : 0).clipShape(Capsule()))
              .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
              .overlay(CornerNotch(style.notch))                       // die-cut silhouette
              .scaleEffect(assigned ? 1.08 : 1.0)
              .modifier(assigned ? AnyViewModifier(BrutalShadow()) : AnyViewModifier(EmptyModifier()))
              .animation(.spring(response: 0.32, dampingFraction: 0.7), value: assigned)
      }
  }
  ```
- Chip initials font is exactly `rounded semibold 15` per the type scale. Do not use `.money`/`.ledger` here — initials are not amounts.
- `CornerNotch` and the notch position come from the fixed palette (single vs double square per diner: e.g. Vermilion top-left, Cyan top-left ×2). Assign by roster index — stable all session; never randomize.
- Pitfall: don't rely on the fill color to distinguish assigned/unassigned. The four distinguishing signals are fill **and** keyline **and** scale **and** (in the row) the ring arc — the row wires the ring; the chip owns the first three.
- Pitfall: the `.selection` haptic must be `.sensoryFeedback` (not `UIFeedbackGenerator`) per platform rules.
- VoiceOver label pattern the screens will set: `"Ana, assigned to Nachos, double-tap to remove."` Expose an `accessibilityLabel`/`accessibilityHint` hook or leave label composition to the caller — but ensure the view is a single accessibility element.
- Keep the shadow shallow (0 blur, x+3 y+4) — deep/skeuomorphic reads dated.

**Done when:**
- `DinerChip.swift` builds; light and dark `#Preview`s render hollow, assigned, and add-person chips.
- Toggling `assigned` springs scale 1.0↔1.08, swaps fill/keyline/shadow, and fires `.selection`.
- In a grayscale/CVD pass, identity is still legible via initials + notch + texture (not color).
- Every chip variant is ≥44×44pt.

---

### Task 5.2 — Build the SplitRing component
**Skills to load:** `splitfair-split-ring`

**Why this matters:** The split-ring makes a shared item read **spatially** — arc length shows how many people split it — so a split is legible even in grayscale and never depends on hue. If the arc count ever drifts from `Item.assigneeIDs.count`, the ring lies about the split and users distrust the whole app. Because color rings the number but never touches it, this is also what keeps the price pure ink (calm center) while still signaling the split (loud frame).

**What to do:**
1. Create `SplitFair/DesignSystem/SplitRing.swift`.
2. Input: `assignees: [DinerStyle]` in **roster order**; empty means unassigned.
3. Draw a base `Circle().stroke(Color.divider, lineWidth: 3)`.
4. **Unassigned:** overlay a hollow dashed ink ring: `Circle().stroke(Color.inkSoft, style: .init(lineWidth: 3.5, dash: [4, 6]))` — this pairs with the amber hazard-tape row state from Task 5.7.
5. **Assigned to N:** divide into N equal arcs using `.trim(from:to:)`, each arc tinted the assignee's diner hue, with a ~1pt ink gap between arcs (subtract `0.02` from the segment end). Rotate `-90°` so arc 0 starts at the top; assignee order = roster order (deterministic, matches `allocate([1]*N)`).
6. Animate the division with `.spring(response: 0.32, dampingFraction: 0.7)` keyed on `assignees.count` so arcs grow/shrink on each assign/unassign.
7. Keep the ring purely decorative around a slot — the price `Text` is composed by the `ItemRow` (Task 5.4) inside the ring; the ring itself does not own the number.
8. Add light and dark `#Preview`s: unassigned (dashed), split 2-ways, split 3-ways, split 5-ways.

**Technical details & suggestions:**
- Use the skill's geometry directly:
  ```swift
  struct SplitRing: View {
      let assignees: [DinerStyle]      // roster order; empty = unassigned
      var body: some View {
          ZStack {
              Circle().stroke(Color.divider, lineWidth: 3)
              if assignees.isEmpty {
                  Circle().stroke(Color.inkSoft, style: .init(lineWidth: 3.5, dash: [4, 6]))
              } else {
                  let seg = 1.0 / Double(assignees.count)
                  ForEach(Array(assignees.enumerated()), id: \.offset) { i, d in
                      Circle()
                          .trim(from: Double(i)*seg, to: Double(i+1)*seg - 0.02)
                          .stroke(d.color, style: .init(lineWidth: 5, lineCap: .round))
                          .rotationEffect(.degrees(-90))
                          .animation(.spring(response: 0.32, dampingFraction: 0.7), value: assignees.count)
                  }
              }
          }
      }
  }
  ```
- The arc `lineWidth` (5) is intentionally heavier than the base ring (3) so the split reads at arm's length.
- Pitfall: `arc count == assignees.count` at all times — never cache a stale count. The row passes the live array so the ring can never disagree with the model.
- Pitfall: never fill the ring's interior or put the price on a tinted background — the ring is decoration around an ink number, not the number's background.
- VoiceOver phrasing the caller applies: `"split 3 ways"`.
- In EPIC 06/08 a `matchedGeometryEffect` arc will fly in from the tapped chip; leave the ring's arc rendering compatible with an incoming matched arc (stable `id` per arc index).

**Done when:**
- `SplitRing.swift` builds; previews show dashed-unassigned and 2/3/5-way splits with visible ink gaps.
- Changing the assignees array springs the arcs and keeps arc count equal to array count.
- The ring reads correctly in grayscale (arc lengths, not hues, carry the split).

---

### Task 5.3 — Build the Buttons (primary/secondary/danger)
**Skills to load:** `splitfair-buttons`

**Why this matters:** These three roles enforce "spend emphasis in one place." The one loud Tangerine CTA drives navigation; the outlined secondary handles low-stakes actions; danger-red appears exactly once, on Clear. Get the emphasis hierarchy or the press physics wrong and the screen either shouts everywhere or feels dead. The disabled-CTA behavior is also a money-safety gate: it must refuse to navigate while items are unassigned (wired fully in Task 5.7 + EPIC 06).

**What to do:**
1. Create `SplitFair/DesignSystem/Buttons.swift` with `PrimaryButton`, `SecondaryButton`, and `DangerButton`.
2. **PrimaryButton** — `RoundedRectangle` r=20, Tangerine fill, white SF Rounded Semibold 17pt label (`.money(17)` for the number-free CTA is acceptable; the skill uses `.money(17)`), 2pt ink keyline, hard offset shadow x+3 y+4. Press physics: shadow collapses to x+1 y+1, the button nudges down 3pt, `.sensoryFeedback(.selection)`. Disabled state: desaturated fill (`Color.inkSoft`), label swaps to "Assign all items first," and it does not act (the wiggle is triggered by the caller/Task 5.7).
3. **SecondaryButton** — surface/clear fill, 2pt ink keyline, ink label, small or no offset shadow (lower emphasis than primary). Used for "Copy summary" and inline actions.
4. **DangerButton** — ink keyline + danger-red label (`.danger`) + a `trash` SF Symbol, low emphasis. It is the **only** control that opens a confirm dialog (`.confirmationDialog`) — a shake-to-confirm feel on press. Never use danger-red anywhere else.
5. Ensure every button is ≥44×44pt.
6. Add light and dark `#Preview`s: primary enabled, primary disabled, secondary, danger (with the confirm dialog wired to a `@State` bool).

**Technical details & suggestions:**
- Primary sketch from the skill:
  ```swift
  struct PrimaryButton: View {
      let title: String; var enabled = true; let action: () -> Void
      @State private var pressed = false
      var body: some View {
          Button(action: action) {
              Text(title).font(.money(17)).foregroundStyle(.white)
                  .padding(.horizontal, 20).padding(.vertical, 14)
          }
          .background(RoundedRectangle(cornerRadius: 20).fill(enabled ? Color.tangerine : Color.inkSoft))
          .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.ink, lineWidth: 2))
          .background(Color.ink.offset(x: pressed ? 1 : 3, y: pressed ? 1 : 4))
          .offset(y: pressed ? 3 : 0)
          .sensoryFeedback(.selection, trigger: pressed)
          .disabled(!enabled)
      }
  }
  ```
- Drive `pressed` from a `ButtonStyle` (`configuration.isPressed`) or a `DragGesture(minimumDistance: 0)` so the offset/shadow track the actual press.
- For `DangerButton`, expose an `onConfirm: () -> Void` closure and own the `.confirmationDialog` internally so callers can't accidentally destroy without the dialog. The confirm haptic is `.sensoryFeedback(.success)` on the actual Clear (per motion skill), not on opening the dialog.
- Pitfall: only the primary gets the deep offset shadow; secondary/destructive stay quieter. Don't give three loud buttons.
- Pitfall: the label must say exactly what happens ("Copy summary" → the screen shows a "Copied ✓" toast). No vague verbs like "OK"/"Go."
- The primary lives on the glass footer rail (Task 5.7) but is itself **opaque** — do not make it translucent.

**Done when:**
- All three buttons build with light/dark previews.
- Primary shows the press physics (shadow collapse + 3pt nudge + `.selection`) and, when disabled, desaturates and shows "Assign all items first."
- Danger opens a `.confirmationDialog` and only calls `onConfirm` after confirmation; danger-red appears nowhere else.
- Every button measures ≥44×44pt.

---

### Task 5.4 — Build the Cards (item row + per-person total)
**Skills to load:** `splitfair-cards`, `splitfair-split-ring`, `splitfair-diner-chip`

**Why this matters:** These are the two surfaces that group a price (Screen 1) and a total (Screen 2). They embody the calm-center rule: the money is always ink on matte surface, never a diner hue or accent. The `ItemRow` also carries the unassigned guard's left-edge signal (money-safety), and the `PersonTotalCard`'s expand-to-ledger is where users verify the split is honest down to the cent. Coloring a total, or letting a price sit on a chip, breaks the core trust promise.

**What to do:**
1. Create `SplitFair/DesignSystem/ItemRow.swift` and `SplitFair/DesignSystem/PersonTotalCard.swift`.
2. **ItemRow** — `RoundedRectangle` r=22, Receipt White surface (`.surface`), `BrutalShadow`, 20pt padding:
   - Top: optional label 17pt (placeholder "Item", italic secondary ink) on the left; a right-aligned `.ledger(24)` price (SF Mono Heavy 24pt, `.monospacedDigit()`, ink) wrapped inside a `SplitRing` (Task 5.2).
   - Bottom: a horizontally-scrollable strip of `DinerChip`s (Task 5.1) plus an inline "Shared by all" pill that will cascade-fill every chip.
   - Left edge: a 4pt ink rule that turns to amber hazard-tape when unassigned (the hazard-tape view comes from Task 5.7; expose an `isUnassigned` flag that swaps the edge).
   - Single-tap chips only — no modes, no steppers.
3. **PersonTotalCard** — `RoundedRectangle` r=26, `BrutalShadow`, via `.card()`:
   - Header: the person's `DinerChip` sticker + name 17pt.
   - Right: `.money(40)` total (SF Rounded Black 40pt, `.monospacedDigit()`, **ink, never colored**) + a `chevron.down` that rotates 180° when expanded.
   - Tap the whole card → expand via `matchedGeometryEffect` into that person's itemized lines + prorated tax/tip in `.ledger(15)`, each line faintly tinted (~8%) in the person's hue, using a dotted leader between label and value.
   - Collapsed height ≥64pt (the whole card is the tap target).
   - Support **bento ordering** from the caller: accept an `isFeatured: Bool` (biggest ower) that renders slightly larger/first.
4. Add light and dark `#Preview`s: an assigned item row, an unassigned item row (hazard edge + dashed ring), a collapsed person card, and an expanded person card with a few ledger lines.

**Technical details & suggestions:**
- PersonTotalCard sketch from the skill (note the ink total and `.card()`):
  ```swift
  struct PersonTotalCard: View {
      let style: DinerStyle; let name: String; let total: Money
      var isFeatured = false
      @Binding var expanded: Bool
      var ledger: [LedgerLine] = []          // item shares + prorated tax + tip
      var body: some View {
          VStack(alignment: .leading, spacing: 12) {
              HStack(spacing: 13) {
                  DinerChip(style: style)
                  Text(name).font(.system(size: 17, weight: .semibold)); Spacer()
                  Text(Decimal(total.minorUnits)/100, format: .currency(code: "USD"))
                      .font(.money(40)).foregroundStyle(Color.ink)      // ink, never colored
                  Image(systemName: "chevron.down").rotationEffect(.degrees(expanded ? 180 : 0))
              }
              if expanded {
                  ForEach(ledger) { line in /* label … dotted leader … value in .ledger(15) */ }
              }
          }
          .card()
          .onTapGesture { withAnimation(.spring) { expanded.toggle() } }
      }
  }
  ```
- Money display: render `Money`/`Cents` via `Decimal(total.minorUnits)/100` with `.currency(code:)` — the value comes from `BillCore` upstream; the card never computes it. Prices/totals use `.monospacedDigit()` so they never jitter.
- Prices **wrap** to a second line rather than truncate; display/hero sizes cap Dynamic Type growth (handled by the `.money`/`.ledger` tokens with `relativeTo:` from EPIC 04).
- Pitfall: the total is **always ink** — never a diner hue or accent. Color lives on the chip, not the number.
- Pitfall: respect Reduce Motion on the expand — under Reduce Motion, crossfade instead of the `matchedGeometryEffect` spring (full wiring in EPIC 08, but structure the animation so it's swappable via `@Environment(\.accessibilityReduceMotion)`).
- Left-edge unassigned rule: keep the edge a distinct subview so Task 5.7's hazard-tape can drop in; the ring goes to its dashed state at the same time (pass `assignees: []`).

**Done when:**
- Both card files build with light/dark previews (assigned/unassigned row; collapsed/expanded card).
- The item row shows the ringed price + chip strip + "Shared by all" pill + left edge; the total on the person card is ink and `.monospacedDigit()`.
- Expanding the person card reveals `.ledger(15)` breakdown lines with dotted leaders; collapsed height ≥64pt; the whole card is the tap target.
- No number renders on a chip, gradient, or colored fill.

---

### Task 5.5 — Build the Tip controls
**Skills to load:** `splitfair-tip-controls`

**Why this matters:** This is Screen 2's entry zone and the only place Acid-Lime appears ("money in motion"). Presets-over-typing keeps it fast; the live lime readout gives instant feedback; the base toggle (pre-tax vs total) makes the math trustworthy by showing which base is used. The tax field must display the exact printed tax straight off the receipt — never recompute tax from a percentage — or the reconciliation will fight real-world receipts. Every change here must re-fire the reconciliation stamp (Task 5.6), so the controls expose clean callbacks.

**What to do:**
1. Create `SplitFair/DesignSystem/TipControls.swift`.
2. **Tax field** (`taxcard`): a "TAX" label + a right-aligned `.ledger` field showing the dollar amount (default `$`), with a small `$`/`%` segmented toggle. The exact printed tax is used directly. Parse input through `BillCore.MoneyEdge` (`Decimal + FormatStyle → Cents`) — never store money as `Double`.
3. **Tip preset chips**: a row `[15][18][20][25][Custom]` as clay-pressable stamps — `RoundedRectangle` r=16, 2pt ink keyline, pressable depth (shadow shrinks on press + `.sensoryFeedback(.selection)`).
   - Unselected: surface fill, ink label.
   - Selected: Tangerine fill, white label, spring pop, keyline kept.
   - Custom: opens an inline numeric field (never a modal).
4. **Live readout pill** (the one lime element): a `= $11.79` pill in Acid-Lime with **ink text**, `.money(19)` (the type scale lists the tip readout at 26 for the hero context; use the pill sizing from the skill sketch = 19), rolling via `.contentTransition(.numericText())` as the tip changes.
5. **Base toggle**: a tiny `pre-tax` / `total` segmented control; **default = pre-tax subtotal**. Surface the chosen base so users trust the math; the choice feeds `resolvedTip` upstream.
6. Expose callbacks: `onTipChange(TipMode)`, `onTaxChange(Cents)`, `onBaseChange(TipBase)` — the controls are presentational; the store does the compute.
7. Add light and dark `#Preview`s: a preset selected (20%), Custom open with the inline field, the base toggle on `total`, and the lime pill showing a value.

**Technical details & suggestions:**
- Skill sketch for the preset row + lime pill:
  ```swift
  HStack {
      ForEach([15,18,20,25], id: \.self) { pct in
          Button("\(pct)%") { onTipChange(.percent(pct)) }
              .buttonStyle(TipChip(selected: selectedTip == .percent(pct)))
      }
      Spacer()
      Text(Decimal(tipCents)/100, format: .currency(code: "USD"))
          .font(.money(19)).foregroundStyle(Color.ink)
          .padding(8)
          .background(RoundedRectangle(cornerRadius: 14).fill(Color.acidLime))
          .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 2))
          .contentTransition(.numericText())
  }
  ```
- Build `TipChip` as a `ButtonStyle` reading `configuration.isPressed` for the depth-shrink, selected → Tangerine fill/white label with a spring pop.
- Pitfall: Acid-Lime **always carries ink text** — never white on lime. Lime appears nowhere else in the app.
- Pitfall: the tax amount is the printed receipt figure used directly; when the `$`/`%` toggle is on `%`, that's a convenience input that resolves to cents once — do not keep tax as a live percentage of a moving base.
- Pitfall: there is **no "Calculate" button** — everything is live. Changing a preset must recompute every per-person total and re-fire the reconciliation stamp (the screen wires this in EPIC 07; here just fire the callback promptly).
- Every chip/toggle ≥44pt.
- Money parsing/formatting goes through `BillCore.MoneyEdge`; keep `Cents = Int` end to end.

**Done when:**
- `TipControls.swift` builds with light/dark previews covering a selected preset, Custom open, base = total, and a lime readout.
- Selecting a preset springs it to Tangerine/white and fires `onTipChange`; the lime pill rolls via `.numericText()` with ink text.
- The tax field parses through `MoneyEdge` to `Cents` and shows `$` by default with a working `$`/`%` toggle.
- The base toggle defaults to pre-tax and reports changes via `onBaseChange`.

---

### Task 5.6 — Build the Reconciliation banner
**Skills to load:** `splitfair-reconciliation-banner`, `splitfair-motion-and-haptics`

**Why this matters:** This is the emotional climax — proof that "you're charged right." The perforated success stub, the SETTLED ✓ rubber-stamp, and the counting-up grand total are the payoff that makes users trust the split. It must animate the **exact reconciled integer-cent value** the math produces — never a rounded or faked number — and it must carry the word "SETTLED," not just green, so it survives grayscale and colorblindness. Green is reserved for this state alone; reusing it for "owed" would poison the signal.

**What to do:**
1. Create `SplitFair/DesignSystem/ReconciliationBanner.swift`.
2. Render a perforated tear-edge stub in success green: a container clipped with `PerforationEdge` (`.perforatedTop()`) filled with `.success`, placed above the Screen 2 actions.
3. **Text:** "Totals add up to $97.20" — the grand total in `.money(_)` (SF Rounded Black, `.monospacedDigit()`), plus the label "SETTLED ✓ / adds up" so the word carries the meaning (green is never the only signal).
4. **Stamp:** a `checkmark.seal.fill` ✓ rubber-stamp that thunks in via `PhaseAnimator` — scale `1.4 → 0.95 → 1.0` with a slight rotation (~−6° to −9°) for a hand-stamped feel.
5. **Count-up:** the grand total counts up on entry, capped by a single `.sensoryFeedback(.success)`.
6. **Self-healing note** (`.ledger(13)`, SF Mono 13pt): when rounding was applied, show e.g. "rounding balanced · +$0.02 → tip".
7. **Failure path:** if totals ever fail to reconcile, flip to amber + `exclamationmark.triangle.fill` ⚠ and name the gap. (With correct integer-cent math this never fires, but the path must exist.)
8. **Re-fire on tip change:** expose the banner so the screen can re-trigger the stamp + count-up whenever the tip changes; it always reconciles again.
9. **Reduce Motion:** under `accessibilityReduceMotion`, the stamp just fades in with the haptic and the number sets instantly.
10. Post a VoiceOver announcement on settle: "Totals add up, settled."
11. Add light and dark `#Preview`s: settled state with the $97.20 anchor, a settled state with the rounding note, and the amber failure state.

**Technical details & suggestions:**
- Input: a `state` enum, e.g. `enum Reconciliation { case settled(totalCents: Cents, note: String?); case failed(gapCents: Cents) }`, driven upstream by `BillCore.BillMath.compute` results. The banner never computes — it displays.
- Use `PhaseAnimator([.hidden, .overshoot, .rest])` for the stamp, mapping each phase to `scaleEffect`/`rotationEffect`; gate it on `!reduceMotion`.
- Count-up: animate a displayed `Cents` from 0 → total with a short spring, `.contentTransition(.numericText())`, and fire `.sensoryFeedback(.success)` once at the cap (not per frame).
- Anchor the acceptance case: the $97.20 bill must render exactly "Totals add up to $97.20" from the reconciled integer cents (9720). Never hardcode — format the passed `Cents`.
- Pitfall: the stamp and count-up animate the **exact** reconciled value — never a rounded or faked number; the round-up surplus is a display-only layer (Task 5.7 / EPIC 07), not the source of truth.
- Pitfall: `.success` green is reserved for this settled state; do not reuse it for owed amounts.
- Adjacent round-up toggle ("Round each person up to $1", `.impact(.soft)` haptic) is built in EPIC 07 but must not become the source of truth — reconcile on the exact totals first.

**Done when:**
- `ReconciliationBanner.swift` builds with light/dark previews for settled ($97.20), settled-with-rounding-note, and amber-failure.
- The stamp thunks in via `PhaseAnimator` and the total counts up with a single `.success` haptic; under Reduce Motion it fades in and the number is instant.
- The banner shows the word "SETTLED"/"adds up" alongside green (≥2 non-color signals plus the ✓ icon), and the failure path renders amber + ⚠ naming the gap.
- The displayed total is formatted from passed integer cents (no fake/rounded number).

---

### Task 5.7 — Build the status treatments and empty states
**Skills to load:** `splitfair-status-flags`

**Why this matters:** These treatments enforce two hard promises: money is never silently lost, and the app is instantly actionable. The unassigned hazard-tape flag is the money-safety guard — it must carry three simultaneous, grayscale-legible signals and must block Next (not fake navigation) while anything is unassigned. The empty states teach the two-step model with zero splash. The footer rail is the app's single Liquid-Glass surface, and even there the live number must sit on an opaque pill so no digit ever composites over glass (calm center).

**What to do:**
1. Create `SplitFair/DesignSystem/StatusFlags.swift` (or split into `UnassignedFlag.swift`, `EmptyStates.swift`, `FooterRail.swift`).
2. **Unassigned flag (three simultaneous signals):** for any item with zero assignees, render all three:
   - (1) the item row's left edge becomes amber + ink **hazard-tape** (diagonal stripes) replacing the normal 4pt ink rule (consumed by Task 5.4's `ItemRow` `isUnassigned` hook);
   - (2) an `exclamationmark.triangle.fill` ⚠ in amber;
   - (3) the text "tap a name".
   The split-ring shows its hollow dashed state (Task 5.2 with `assignees: []`).
3. **Blocked-Next behavior:** expose the guard so that tapping Next while any items remain unassigned does **not** navigate — the ⚠ symbols wiggle (`symbolEffect(.bounce)`) + `.sensoryFeedback(.warning)` and the offending rows scroll into view. Provide the running count string helper (e.g. "Nachos + 1 unassigned").
4. **Empty states** (teach the two-step model, no splash):
   - **First run:** a giant Fraunces `.display(~48)` "WHO'S SPLITTING?" centered on the drifting-blob cream canvas, a single ghost (dashed) sticker beneath, name field auto-focused (keyboard up); Return chains the next person.
   - **Diners, no items:** a friendly dashed "+ Add item" sticker-card that expands inline with the numeric keypad presented.
   - **Cleared bill:** returns straight to the "WHO'S SPLITTING?" state.
5. **Sticky footer / subtotal rail (the ONE glass element):** a floating bottom rail using `.glassEffect` (fallback `.regularMaterial`) with a `PerforationEdge` top so the total "tears off" like a check stub.
   - Left: a live "Subtotal $75.50" odometer in `.money(_)` (SF Rounded Black), `.contentTransition(.numericText())` roll on every change — but the number sits on an **opaque cream pill** so no digit composites over glass.
   - Right: the Tangerine `PrimaryButton` (Task 5.3), itself opaque.
   - Under Reduce Transparency the rail becomes opaque cream.
6. Add light and dark `#Preview`s: an unassigned flag on a row, the "WHO'S SPLITTING?" empty state, the "+ Add item" empty state, and the footer rail (glass and Reduce-Transparency-opaque variants).

**Technical details & suggestions:**
- Build the hazard-tape as a reusable view (diagonal amber/ink stripes via a `Canvas` or a striped `LinearGradient` masked to the 4pt edge). Keep it fully legible in grayscale (stripe pattern carries meaning, not just amber).
- The unassigned concept is **one reusable guard** covering three cases at once: never-assigned items, a shared item emptied of sharers, and a deleted person's solo items. Model it as a single predicate the store computes (EPIC 06 wires it); here provide the presentational flag + the block/wiggle behavior and the count helper.
- Footer rail sketch: `RoundedRectangle`/rail background `.glassEffect()` with `if #available` fallback to `.regularMaterial`, `.perforatedTop()` on top; wrap the odometer `Text` in an opaque `.canvas`/cream pill (`Capsule().fill(Color.canvas)`), never letting the digits sit directly on the material. Gate transparency on `@Environment(\.accessibilityReduceTransparency)` → opaque cream.
- Pitfall: **block finalize/Clear-navigation while anything is unassigned** so money is never dropped — the wiggle + warning haptic replace navigation; do not silently proceed or auto-assign.
- Pitfall: this is the **only** glass surface in the app — all content stays matte. Do not add glass elsewhere, and never let a dollar composite over the glass (hence the opaque pill).
- Use only SF Symbols for iconography (`exclamationmark.triangle.fill`, `plus.circle`); nothing bundled.
- Use `.money(56)` (cap 64) sizing conventions for the hero subtotal per the type scale; the odometer must be `.monospacedDigit()` so it never reflows mid-roll.

**Done when:**
- The unassigned flag renders all three signals (hazard-tape edge + ⚠ + "tap a name") with the dashed ring, and is legible in grayscale.
- The blocked-Next path wiggles the ⚠ (`symbolEffect(.bounce)`) + fires `.warning` and does not navigate; the count helper returns strings like "Nachos + 1 unassigned".
- The three empty states render (WHO'S SPLITTING? hero in Fraunces, +Add item card, cleared → hero) with light/dark previews.
- The footer rail uses `.glassEffect` with a `.regularMaterial` fallback and a perforated top; the odometer rides an opaque cream pill and rolls via `.numericText()`; under Reduce Transparency the rail is opaque cream.
