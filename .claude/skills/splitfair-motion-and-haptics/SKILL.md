---
name: splitfair-motion-and-haptics
description: SplitFair's motion and haptics — signature spring animations and sensoryFeedback for assign, split, subtotal odometer, and the SETTLED reconciliation stamp, plus reduce-motion/reduce-transparency handling. Use when adding any animation, transition, or haptic, or wiring the assign/split/reconcile moments.
---

# SplitFair — motion & haptics

Motion is reserved for **assign / split / reconcile** — never idle shimmer or decorative pulse. It always visualizes the true reconciled integer-cent value; it never rounds or fakes.

## Signature moments

- **Assign (signature #1):** tap a hollow chip → fills its hue `.spring(response: 0.32, dampingFraction: 0.7)`, scales 1.0→1.08→1.0, drops a `matchedGeometryEffect` arc onto the split-ring; `.sensoryFeedback(.selection)`. Must feel instant and physical.
- **Split / Shared-by-all:** the split-ring subdivides into equal arcs with a spring; "Shared by all" fills every chip in a staggered cascade (~0.03s) with one `.selection` haptic.
- **Subtotal odometer:** footer subtotal + live tip readout use `.contentTransition(.numericText())` — digits roll like a receipt printer, tabular so nothing reflows.
- **Reconciliation (signature #2, the climax):** the SETTLED ✓ rubber-stamp thunks in via `PhaseAnimator` (scale 1.4→0.95→1.0 + ~−6° rotation), the total counts up, capped by a single `.sensoryFeedback(.success)`. Everything else on screen is calm so this lands. (`splitfair-reconciliation-banner`)
- **Card expand:** per-person card → breakdown via `matchedGeometryEffect` in a shared `@Namespace`; chevron rotates.
- **Add-person:** new sticker drops with a spring overshoot + `symbolEffect` on the plus; name field auto-focuses.
- **Unassigned warning:** blocked Next → ⚠ `symbolEffect(.bounce)` + `.sensoryFeedback(.warning)`; navigation blocked, not faked (`splitfair-status-flags`).
- **Drifting blobs:** `TimelineView`-driven offset, `.easeInOut.repeatForever` — ambient depth only.

## Haptics map (`.sensoryFeedback` only — see `splitfair-ios-platform`)

`.selection` on chip assign + tip select · `.impact(.soft)` on round-up · `.success` on reconcile + Clear · `.warning` on blocked Next.

## Accessibility

- **Reduce Motion:** collapse all springs/odometer/stamp/blobs to simple crossfades and static values; the stamp just fades in with the haptic; numbers set instantly. Honor `@Environment(\.accessibilityReduceMotion)`.
- **Reduce Transparency:** the glass footer rail → opaque cream (`splitfair-design-system`).
