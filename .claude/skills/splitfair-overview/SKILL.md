---
name: splitfair-overview
description: Orientation for building SplitFair, a native iOS (SwiftUI) offline bill splitter that splits a restaurant/grocery bill by who ordered what. Use at the start of any SplitFair work, when deciding which area a task belongs to, or when you need the app's non-negotiables and the map of the other splitfair-* skills.
---

# SplitFair — build overview

SplitFair is a native **iOS / SwiftUI** app that splits a shared bill by **who ordered what** — not by headcount. Three screens, fully offline, no account, no ads, no data ever leaving the device. It keeps a **local library of past bills** and a **running who-owes-whom balance** (EPIC 10 expanded it from the original single-bill, two-screen app).

## Non-negotiables (true across every skill)

1. **Correctness over features.** Per-person totals MUST sum to the grand total to the exact cent. All money is integer minor units (cents); a `Double`/`Float` never touches money. → `splitfair-money-math`
2. **Right-sized, not enterprise.** One `@Observable` store, no ViewModels, no TCA/VIPER, no SwiftData. Reject over-engineering. → `splitfair-app-architecture`
3. **Offline & private.** No network calls, no analytics, no accounts, no sync. Persist a local library of bills plus a friends roster on device — never uploaded. → `splitfair-persistence`
4. **Bold but legible.** The look is *Warm Receipt Brutalism* ("HARD COPY"): colorful stickers and stamps, but every number stays ink-on-paper. → `splitfair-design-system`

## The three screens

- **Screen 0 "Bills":** the launch screen — a running balances summary ("Ben owes you $X") over the library of saved bills; tap a bill to open, "+" for a new one, long-press to duplicate/rename/delete.
- **Screen 1 "The Bill":** roster of color-coded diner chips + item rows; tap chips to assign who ordered each item (2+ = split evenly); a "Who paid?" strip; sticky footer with running subtotal + Next.
- **Screen 2 "Tax, Tip & Totals":** tax field, tip presets, per-person total cards (tap to expand), a reconciliation "SETTLED ✓" banner, round-up, Clear bill.

## Skill map

**Architecture & code:** `splitfair-app-architecture` · `splitfair-project-structure` · `splitfair-swift-conventions` · `splitfair-money-math` · `splitfair-domain-model` · `splitfair-state-store` · `splitfair-persistence` · `splitfair-testing` · `splitfair-ios-platform`

**Design foundations:** `splitfair-design-system` · `splitfair-color-system` · `splitfair-typography` · `splitfair-shapes-and-depth` · `splitfair-motion-and-haptics` · `splitfair-accessibility`

**Components:** `splitfair-buttons` · `splitfair-cards` · `splitfair-diner-chip` · `splitfair-split-ring` · `splitfair-tip-controls` · `splitfair-reconciliation-banner` · `splitfair-status-flags`

## Acceptance anchor

The canonical test bill: 3 people, one item shared 3 ways, tax + 20% tip → each person's total sums to **$97.20** to the exact cent. Any change to the math or model must keep that green (`splitfair-testing`).
