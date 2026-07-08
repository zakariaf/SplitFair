# EPIC 08 — Motion, Haptics & Accessibility

> Make it feel alive and work for everyone: signature motion, the haptics map, and a full accessibility pass that survives grayscale, VoiceOver, and Dynamic Type.

## What this epic is for
Both screens now compute and display the correct integer-cent math, but they are visually plain: springs are missing, the odometer and SETTLED stamp are static, and there has been no dedicated accessibility pass. This epic layers the delight (springs, matched-geometry arcs, the numericText odometer, the rubber-stamp) and the haptics map onto the two finished screens, then guarantees inclusivity: every stateful meaning carries at least three non-color signals, Dynamic Type reflows without truncating or jittering money, VoiceOver labels and announcements are complete, and Reduce Motion / Reduce Transparency fallbacks work. The rule is fixed: motion only ever visualizes the exact reconciled value the math produces — it never rounds, fakes, or shimmers idly.

## Where we are before starting (starting state)
- Screen 1 (The Bill) is functionally complete: diner roster, item rows with ringed prices, tap-to-assign chips, Shared-by-all, inline add-item with the decimal keypad, live subtotal, the unassigned hazard-tape guard that blocks Next, and a NavigationLink to Screen 2 when everything is assigned.
- Screen 2 (Tax, Tip & Totals) is functionally complete: tax field, tip presets + live lime readout + base toggle, per-person bento cards that expand into a receipt breakdown, the reconciliation banner reconciling live, the display-only round-up with an honest surplus, Copy/Share summary, and Clear bill.
- The DesignSystem component library exists (DinerChip, SplitRing, three Buttons, ItemRow, PersonTotalCard, TipControls, ReconciliationBanner, status treatments) with light/dark #Previews.
- BillCore is complete and tested (Money/Currency, `allocate()`, `BillMath.compute`, `Summary`); the `@Observable BillStore` drives both screens and persists.
- Animations are minimal or absent, `.sensoryFeedback` is not yet wired, and there is no VoiceOver labeling, Dynamic Type capping, or reduced-mode handling.

## What we will have after finishing (definition of done)
- The signature motion is wired on both screens: assign spring + matched-geometry arc onto the split-ring, split-ring subdivision, subtotal/tip `.numericText()` odometer, per-person card expand via `matchedGeometryEffect`, add-person bounce, Shared-by-all cascade, and the SETTLED rubber-stamp via `PhaseAnimator`.
- The haptics map is wired entirely through `.sensoryFeedback` (no CoreHaptics): `.selection` on assign + tip select, `.impact(.soft)` on round-up, `.success` on reconcile + Clear, `.warning` on blocked Next — all respecting system settings automatically.
- Every state carries at least three non-color signals; the UI is verified fully legible in a grayscale pass and in deuteranopia / protanopia / tritanopia simulation on every state.
- Dynamic Type reflows: hero/display sizes cap their growth and wrap prices to a second line rather than truncate; the horizontal chip bar reflows at accessibility sizes; every changeable amount uses `.monospacedDigit()` so money never jitters mid-animation.
- VoiceOver labels/traits/values are complete for chips, totals, the split-ring, the reconciliation announcement, and the grouped unassigned rows; combined item rows read as one element; all targets are ≥ 44×44pt and single-tap only.
- Reduce Motion collapses all springs/odometer/stamp/blobs to crossfades and static values; Reduce Transparency turns the one glass rail into opaque cream.
- Composited-background contrast is verified for money, amber, and green in both light and dark; a UI test calls `app.performAccessibilityAudit()` and passes.

## Dependencies
- Depends on: EPIC 07 — Screen 2 — Tax, Tip & Totals (both screens must be functionally complete and navigable before motion/haptics/a11y can be layered on).
- Enables: EPIC 09 — Privacy, Compliance & Release Prep (the accessibility audit and reduced-mode fallbacks become CI gates and on-device verification there).

---

## Tasks

### Task 8.1 — Wire the signature animations
**Skills to load:** `splitfair-motion-and-haptics`

**Why this matters:** Motion is what turns a correct calculator into a settle-up experience people trust and enjoy. The two signature moments — **assign** (tap a chip, watch an arc fly onto the ring) and **reconcile** (the SETTLED stamp thunks in as the total counts up) — carry the whole product feel. Get it wrong and the app is either dead-plain or, worse, distracting: idle shimmer, motion that fakes a rounded number, or digits that reflow mid-roll and read as untrustworthy. The governing rule from the skill is absolute: **motion is reserved for assign / split / reconcile — never idle shimmer or decorative pulse — and it always visualizes the true reconciled integer-cent value; it never rounds or fakes.**

**What to do:**
1. **Assign (signature #1).** On tapping a hollow `DinerChip`, animate the fill of its diner hue with `.spring(response: 0.32, dampingFraction: 0.7)`, scale the chip 1.0 → 1.08 → 1.0, and drop a `matchedGeometryEffect` arc from the tapped chip onto the item's `SplitRing`. It must feel instant and physical. Pair this with the `.sensoryFeedback(.selection)` wired in Task 8.2.
2. **Split-ring subdivision.** When an item's assignee count changes, subdivide the ring into N equal arcs with the same spring (`response: 0.32, dampingFraction: 0.7`) driven off `assignees.count`, matching the `SplitRing` snippet in `splitfair-split-ring`.
3. **Shared-by-all cascade.** When "Shared by all" is tapped, fill every chip in a staggered cascade (~0.03s stagger per chip) and fire exactly **one** `.selection` haptic for the whole gesture (not one per chip).
4. **Subtotal / tip odometer.** Apply `.contentTransition(.numericText())` to the footer subtotal (Screen 1) and the live tip readout pill (Screen 2) so digits roll like a receipt printer. Keep them `.monospacedDigit()` / tabular so nothing reflows during the roll.
5. **Per-person card expand.** Animate the `PersonTotalCard` → receipt breakdown transition with `matchedGeometryEffect` in a shared `@Namespace`; rotate the disclosure chevron.
6. **Add-person bounce.** When a new diner sticker is added, drop it in with a spring overshoot and a `symbolEffect` on the plus glyph; auto-focus the name field (already wired for entry — just add the motion).
7. **Reconciliation (signature #2, the climax).** The SETTLED ✓ rubber-stamp thunks in via `PhaseAnimator` (scale 1.4 → 0.95 → 1.0 + ~−6° rotation), the grand total counts up, and it is capped by a single `.sensoryFeedback(.success)` (wired in 8.2). Keep everything else on screen calm so this lands. Re-fire the stamp whenever the tip changes (it always reconciles again).
8. **Drifting blobs.** Keep the ambient `TimelineView`-driven blob offset with `.easeInOut.repeatForever` — depth only, no content motion. This is the *only* permitted idle animation.

**Technical details & suggestions:**
- Assign spring, everywhere it appears: `.spring(response: 0.32, dampingFraction: 0.7)`. Do not invent per-view timing; the single spring is the signature.
- Matched geometry arc: use one `@Namespace private var assignArc` shared between the chip and the ring, and give the flying arc and the ring segment the same `matchedGeometryEffect(id:in:)`. The arc lands as one of the N ring arcs from `splitfair-split-ring`.
- Odometer: `Text(Decimal(cents) / 100, format: .currency(code: bill.currency.code)).monospacedDigit().contentTransition(.numericText())`. The number must sit on the **opaque cream pill** in the footer rail so no digit composites over glass (`splitfair-status-flags`, `splitfair-design-system`).
- Stamp: drive the `PhaseAnimator` off a `reconciled` trigger value so it re-runs on every tip change. Phases: scale `[1.4, 0.95, 1.0]`, rotation ending at ~−6° (the banner itself is rotated ~−9° for the hand-stamped feel — keep the animation rotation and the resting rotation distinct).
- **Pitfall:** never animate a rounded or display-only value. The odometer, the count-up, and the stamp all animate the exact reconciled integer-cent value `BillMath.compute` produced. The round-up surplus is display-only and must not become the number the stamp celebrates.
- **Pitfall:** do not add hover/appear shimmer, pulsing CTAs, or looping attention motion. Motion that does not visualize assign/split/reconcile does not ship.
- Files: Screen 1 assign/odometer/cascade live under `SplitFair/Features/Bill/`; the ring is `SplitFair/DesignSystem/Components/SplitRing.swift`; the stamp/count-up live in `SplitFair/DesignSystem/Components/ReconciliationBanner.swift` and `SplitFair/Features/Totals/`; blobs live in the DesignSystem shapes layer.

**Done when:**
- Tapping a chip fills its hue with the signature spring, scales 1.0→1.08→1.0, and an arc flies onto the split-ring which subdivides into the correct N arcs.
- "Shared by all" cascades all chips with a single selection haptic.
- The Screen 1 subtotal and Screen 2 tip readout roll via `.numericText()` with no digit reflow.
- The per-person card expands/collapses via matched geometry with a rotating chevron.
- Adding a person drops the sticker in with a spring overshoot + plus `symbolEffect`.
- The SETTLED stamp thunks in via `PhaseAnimator`, the total counts up, and it re-fires when the tip changes — always on the exact reconciled value.
- The only idle motion anywhere is the ambient drifting blobs.

---

### Task 8.2 — Wire the haptics map
**Skills to load:** `splitfair-ios-platform`, `splitfair-motion-and-haptics`

**Why this matters:** Haptics make the touch feel physical — the chip "clicks," the reconcile "thunks," the blocked Next "buzzes." But haptics are also an accessibility and trust surface: they must respect the user's system settings, must not fire on every frame of an animation, and must map meaning consistently (success is never a warning; a blocked action is never celebrated). The skill is explicit: **`.sensoryFeedback` only — no CoreHaptics — and it respects system settings automatically, so you must not read any haptic setting yourself.** Getting this wrong (CoreHaptics, or firing per-chip on cascade, or a success buzz on a blocked action) breaks both feel and trust.

**What to do:**
1. Wire **`.selection`** on chip assign and on tip-preset select. Trigger it off a monotonic counter or the assigned/selected value so it fires once per discrete user action.
2. Wire **`.impact(.soft)`** on the round-up toggle (Screen 2), fired when the toggle flips.
3. Wire **`.success`** on the reconciliation stamp (capping the count-up) and on Clear bill (fired when the bill is actually cleared, after the confirm dialog).
4. Wire **`.warning`** on blocked Next: when the user taps Next while any item is unassigned, fire `.warning` alongside the ⚠ `symbolEffect(.bounce)` — and do **not** navigate (`splitfair-status-flags`).
5. For the Shared-by-all cascade, fire exactly **one** `.selection` for the whole gesture (align with Task 8.1, step 3).
6. Confirm no `CoreHaptics` import or `UIFeedbackGenerator` exists anywhere; confirm you never read a "haptics enabled" flag.

**Technical details & suggestions:**
- Canonical form from `splitfair-ios-platform`:
  ```swift
  .sensoryFeedback(.selection, trigger: assignedCount)
  .sensoryFeedback(.success, trigger: reconciled)
  ```
- Full map from `splitfair-motion-and-haptics`: `.selection` on chip assign + tip select · `.impact(.soft)` on round-up · `.success` on reconcile + Clear · `.warning` on blocked Next.
- Triggers must be **discrete, changing values** — e.g. an `Int` assigned-count, a `Bool reconciled`, a `Bool roundUp`, an incrementing `blockedNextAttempts` counter for the warning. Never bind a haptic trigger to a continuously animating value, or it will fire every frame.
- The `.warning` trigger should be an attempt counter, not the unassigned-count, so repeated blocked taps each buzz even when the count is unchanged.
- **Pitfall:** do not fire `.success` on a blocked Next — that is `.warning`. Do not fire `.selection` per chip during the Shared-by-all cascade — one for the whole gesture.
- **Pitfall:** `.sensoryFeedback` already honors the system's System Haptics setting; adding any manual gate or CoreHaptics engine is both redundant and off-spec.
- Files: attach modifiers on the relevant views — chip/assign in `SplitFair/Features/Bill/`, tip select + round-up + reconcile in `SplitFair/Features/Totals/` and `SplitFair/DesignSystem/Components/ReconciliationBanner.swift`, Clear in wherever the confirm dialog resolves, blocked Next on the Screen 1 footer CTA.

**Done when:**
- Assigning a chip and selecting a tip preset each produce one `.selection` tap.
- The round-up toggle produces `.impact(.soft)`; the reconcile stamp and Clear each produce `.success`.
- Tapping a blocked Next produces `.warning`, wiggles ⚠, and does not navigate.
- Shared-by-all produces exactly one `.selection`.
- A repo-wide search finds no `CoreHaptics`, no `UIFeedbackGenerator`, and no manual haptic-setting reads; all haptics go through `.sensoryFeedback`.

---

### Task 8.3 — Run the accessibility labeling pass
**Skills to load:** `splitfair-accessibility`

**Why this matters:** SplitFair is passed across a restaurant table and used by people who rely on VoiceOver. The visual language leans on color, shape, and motion; VoiceOver users get none of that unless every element is labeled with its name, its assignment, and its action. Un-grouped rows force a blind user to swipe through a chip, a price, and a ring separately with no relationship; missing announcements mean the SETTLED climax is silent. The skill's requirements are concrete: **chips announce name + assignment + action; totals read the full amount; the split-ring is described ("split 3 ways"); the reconciliation banner posts an announcement; unassigned rows are grouped and reachable via the blocked-Next action; every target ≥ 44×44pt; single-tap only.**

**What to do:**
1. **Chips.** Give each `DinerChip` a combined VoiceOver label following the skill's exact pattern: name + assignment + action, e.g. `"Ana, assigned to Nachos, double-tap to remove."` For a hollow (unassigned-to-this-item) chip, the action reads "double-tap to assign." Add the `.isButton` trait.
2. **Totals.** Every money value reads its **full amount** (e.g. "$97.20", derived from the currency `FormatStyle`), not the raw digits or a truncated string. Apply to the subtotal, per-person totals, tip readout, and grand total.
3. **Split-ring.** Add an `.accessibilityLabel` that describes the split spatially: `"split 3 ways"` for N=3, `"unassigned"` for the hollow state. The ring is decorative visually but must be a described, redundant "shared N ways" signal for VoiceOver.
4. **Combined item rows.** Use `.accessibilityElement(children: .combine)` (or `.ignore` + an explicit combined label) so an item row reads as **one** element: item name + price + split state (e.g. "Nachos, $12.00, split 3 ways between Ana, Bo, Cy"), rather than three separate swipe stops.
5. **Reconciliation announcement.** When the banner reaches the settled state, post a VoiceOver announcement: `"Totals add up, settled."` Re-post it when the tip changes and it reconciles again.
6. **Grouped unassigned rows.** Group unassigned item rows so they are announced together, and make them reachable via the blocked-Next accessibility action (an `.accessibilityAction` on the Next button that moves focus to the first unassigned row), so a VoiceOver user who cannot navigate learns why and where.
7. **Targets & flow.** Verify every interactive element is ≥ 44×44pt (chips, toggles, presets, CTAs, add buttons). Confirm the whole app is **single-tap only** — no long-press or precise gestures — and that there is exactly **one** confirm dialog (Clear bill).

**Technical details & suggestions:**
- Post the announcement via an accessibility notification, e.g. `AccessibilityNotification.Announcement("Totals add up, settled.").post()` gated on the reconciled transition, or the `.accessibilityAnnouncement` trigger approach — fire it on the same `reconciled` value that caps the `.success` haptic.
- Chip label sketch:
  ```swift
  DinerChip(...)
      .accessibilityLabel("\(diner.name), \(isAssigned ? "assigned to \(item.name)" : "not assigned to \(item.name)")")
      .accessibilityHint(isAssigned ? "Double-tap to remove" : "Double-tap to assign")
      .accessibilityAddTraits(.isButton)
  ```
- Item row: prefer `.accessibilityElement(children: .combine)` when the child labels already read cleanly; use `.ignore` + a hand-built `.accessibilityLabel` + `.accessibilityValue` when you need to control ordering (name, then amount, then split).
- The split-ring's spoken description must stay in sync with `Item.assigneeIDs.count` — reuse the same count that drives the arcs so it never lies (`splitfair-split-ring`).
- **Pitfall:** don't let the raw money `Text` read as separated digits — VoiceOver reads a currency `FormatStyle` value as a proper amount; keep the label as the formatted value string.
- **Pitfall:** don't add a second confirm dialog or any long-press. The blocked-Next path must remain a real block (no fake navigation) that VoiceOver can act on.
- Files: chip labels in `SplitFair/DesignSystem/Components/DinerChip.swift`; ring in `SplitFair/DesignSystem/Components/SplitRing.swift`; row combine in `SplitFair/DesignSystem/Components/ItemRow.swift` and its Screen 1 host; totals in `SplitFair/DesignSystem/Components/PersonTotalCard.swift`; announcement in `ReconciliationBanner.swift`; blocked-Next action on the Screen 1 footer.

**Done when:**
- VoiceOver reads each chip as name + assignment + action per the exact pattern.
- Each item row is a single combined element reading name + amount + split state.
- The split-ring is described as "split N ways" / "unassigned" in sync with the model.
- The banner posts "Totals add up, settled." on reconcile and re-posts on tip change.
- Unassigned rows are grouped and reachable via a blocked-Next accessibility action.
- All targets measure ≥ 44×44pt; the app is single-tap only with exactly one confirm dialog.

---

### Task 8.4 — Implement Dynamic Type and reduced-mode fallbacks
**Skills to load:** `splitfair-accessibility`, `splitfair-motion-and-haptics`

**Why this matters:** Large accessibility text sizes are where bold layouts break: a 56pt hero total grows until it truncates or overlaps, a horizontal chip bar runs off-screen, and money digits jitter mid-animation. Users who need large type or Reduce Motion / Reduce Transparency are exactly the users the bold look most risks failing. The skills are explicit: **all text maps to text styles via `relativeTo:` so it scales; display/hero sizes cap their growth and wrap prices to a second line rather than truncate; `.monospacedDigit()` everywhere numbers change; reflow the horizontal chip bar at accessibility sizes; under Reduce Motion collapse all springs/odometer/stamp/blobs to crossfades and static values; under Reduce Transparency the glass rail becomes opaque cream.**

**What to do:**
1. **Dynamic Type mapping.** Ensure every text style maps to a Dynamic Type text style via `relativeTo:` (per the type scale in `splitfair-typography`) so all text scales with the user's setting.
2. **Cap hero growth + wrap prices.** For the hero subtotal / odometer (56, cap 64), the per-person total (40), and the tip readout pill (26), cap Dynamic Type growth and allow prices to **wrap to a second line** rather than truncate. Set `.lineLimit(nil)` / allow multi-line and never `.truncationMode(.tail)` on money.
3. **`.monospacedDigit()` on all changeable amounts.** Confirm every amount that animates or updates uses `.monospacedDigit()` so columns align and nothing reflows or jitters mid-odometer.
4. **Chip-bar reflow.** At accessibility Dynamic Type sizes, reflow the horizontal chip bar into a wrapping layout so no chip is clipped or scrolled off — switch from an `HStack`/horizontal scroll to a wrapping layout when `dynamicTypeSize >= .accessibility1`.
5. **Reduce Motion.** Honor `@Environment(\.accessibilityReduceMotion)`. When on: collapse all springs, the odometer, the stamp, and the blobs to simple crossfades and static values — numbers set instantly; the stamp just **fades in** with its `.success` haptic still firing; blobs stop drifting.
6. **Reduce Transparency.** When on, the single glass footer rail becomes **opaque cream** (`splitfair-design-system`) instead of `.glassEffect` / `.regularMaterial`.

**Technical details & suggestions:**
- Read the environment values:
  ```swift
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  ```
- Cap growth by clamping: e.g. `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` on hero containers, or size the font relative to a text style and let wrapping absorb the rest. The type scale gives the hero cap explicitly (56, cap 64).
- Chip-bar reflow: gate the layout on `typeSize.isAccessibilitySize` — use a wrapping `Layout` (or `FlowLayout`) at accessibility sizes and the horizontal bar otherwise.
- Reduce Motion pattern: choose the animation at the call site, e.g. `withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.7))`, and swap `.contentTransition(.numericText())` for `.identity` (or set the value without animation) when `reduceMotion`. The stamp `PhaseAnimator` becomes a plain `.opacity` fade. **The `.success` haptic still fires** — Reduce Motion suppresses motion, not feedback.
- Reduce Transparency pattern for the rail:
  ```swift
  .background(reduceTransparency ? AnyShapeStyle(Color.canvas) : AnyShapeStyle(.regularMaterial))
  ```
  keeping the `PerforationEdge` top and the opaque cream number pill in both branches.
- **Pitfall:** never truncate money — wrapping is required. A truncated total is a trust failure.
- **Pitfall:** don't drop the haptic under Reduce Motion; don't leave blobs drifting under Reduce Motion; don't leave the rail translucent under Reduce Transparency.
- **Pitfall:** capping growth must not shrink the number below its legible role; cap, then wrap — do not scale-to-fit money into one line.
- Files: type styles in `SplitFair/DesignSystem/` (Font tokens + Theme); chip-bar reflow in the Screen 1 host under `SplitFair/Features/Bill/`; hero/odometer in the footer rail (`status-flags` footer) and Screen 2 totals; rail fallback in the footer rail view; blob fallback in the DesignSystem shapes layer.

**Done when:**
- Every text style scales with Dynamic Type via `relativeTo:`.
- At the largest accessibility sizes, hero/total/tip money **wraps** to a second line and never truncates; hero growth is capped.
- All changeable amounts use `.monospacedDigit()` and do not jitter during the odometer roll.
- The chip bar reflows into a wrapping layout at accessibility Dynamic Type sizes with no clipped chips.
- With Reduce Motion on: springs/odometer/stamp/blobs are static crossfades, numbers set instantly, the stamp fades in, and the `.success` haptic still fires.
- With Reduce Transparency on: the footer rail is opaque cream (perforated edge and cream number pill intact).

---

### Task 8.5 — Verify contrast, grayscale and CVD, and run the audit
**Skills to load:** `splitfair-accessibility`, `splitfair-color-system`

**Why this matters:** The bold look must never cost legibility or trust — and the only way to prove that is to measure, not eyeball. Amber and green in particular look fine nominally but can fail against their **composited** backgrounds (over the cream canvas, over a card, in dark mode). Color-blind users (deuteranopia / protanopia / tritanopia) and anyone reading in a grayscale context must still parse every state — which is exactly why the design carries ≥3 non-color signals. And `performAccessibilityAudit()` catches the machine-checkable failures (contrast, hit size, missing labels, clipped text) that a human pass misses. The skills are explicit: **money is ink-on-cream (14.8:1) / cream-on-aubergine (~15:1); big totals clear 7:1; all amounts ≥ 4.5:1; verify amber/green in BOTH modes against their composited backgrounds; verify the whole UI in a grayscale pass and deuteranopia/protanopia/tritanopia simulation.**

**What to do:**
1. **Composited-background contrast checks.** For money, amber, and green, measure contrast against the **actual composited** background they render on (not the nominal token), in **both** light and dark:
   - Money: ink-on-cream ≈ 14.8:1, cream-on-aubergine ≈ 15:1; big totals ≥ 7:1; all amounts ≥ 4.5:1.
   - Amber (Warning `#FF9E1C` light on `#FFEBC4` / dark on `#3A2A12`) rendered as hazard-tape — verify the ⚠ and text legibility, not the tape alone.
   - Green (Success `#1FB25A` light / `#34D07A` dark) in the SETTLED stamp — verify the ✓ and "adds up" text.
   - Confirm no number ever renders on a gradient, chip fill, or glass; the footer number must sit on the opaque cream pill.
2. **Grayscale pass.** Desaturate every state (roster, assigned rows, unassigned hazard-tape, split-ring at N=1/2/3+, tip pill, reconciliation settled, empty states, Clear confirm) and confirm each is fully legible via its non-color signals — diner identity (color + initials + corner-notch + micro-texture), assignment (fill + keyline + scale + arc), unassigned (stripes + ⚠ + "tap a name"), settled (green + ✓ + "adds up").
3. **CVD simulation.** Repeat the pass under deuteranopia, protanopia, and tritanopia simulation on every state, in both light and dark. Confirm the 10 diner colors remain distinguishable by their four-channel identity, not hue.
4. **Automated audit.** Add a UI test that navigates both screens and calls `app.performAccessibilityAudit()`; make it pass (fix any contrast, dynamic-type, hit-region, clipping, or element-description failures it reports).

**Technical details & suggestions:**
- Use Xcode's Accessibility Inspector (Color Contrast Calculator) and the Simulator's Environment Overrides / the Accessibility Inspector's vision simulations (grayscale + the three CVD types) for the manual passes. Capture screenshots per state so EPIC 09 can re-verify.
- UI test sketch (XCTest):
  ```swift
  func testAccessibilityAudit() throws {
      let app = XCUIApplication()
      app.launch()
      // build the $97.20 acceptance bill, navigate to Screen 2
      try app.performAccessibilityAudit()   // add options to scope known-safe exceptions only if justified
  }
  ```
- If `performAccessibilityAudit()` flags the odometer/stamp during animation, assert after motion settles (or run with Reduce Motion on) rather than suppressing the check.
- **Pitfall:** measure the **composited** color. A semitransparent amber over cream is not `#FF9E1C` — sample the rendered pixel. The skill calls this out specifically for amber/green in both modes.
- **Pitfall:** do not "pass" the audit by broadly disabling audit types. Only exclude a specific, justified false positive; a clipped or low-contrast money value is never acceptable.
- **Pitfall:** the grayscale/CVD pass is a requirement, not a nicety — any state that dies in grayscale wasn't designed (`splitfair-design-system` principle 2). Fix the design (add a signal), don't waive the check.
- Files: the audit UI test lives in the app's UI test target (e.g. `SplitFairUITests/AccessibilityAuditTests.swift`); contrast/vision findings drive fixes back into `SplitFair/DesignSystem/` tokens and component views. The acceptance bill total is the `$97.20` anchor from BillCore.

**Done when:**
- Money, amber, and green each meet their contrast targets against their **composited** backgrounds in both light and dark (money ≥ 7:1 for big totals, ≥ 4.5:1 for all amounts; no number on a gradient/chip/glass).
- Every state is verified legible in a grayscale pass and under deuteranopia / protanopia / tritanopia simulation in both modes, relying on its ≥3 non-color signals.
- A UI test calls `app.performAccessibilityAudit()` on both screens and passes with no unjustified exclusions.
- Screenshots of each state (grayscale + CVD) are captured for EPIC 09 re-verification.
