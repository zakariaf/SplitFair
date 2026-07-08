---
name: splitfair-ios-platform
description: iOS platform integration for SplitFair — haptics via sensoryFeedback, ShareLink/clipboard for Copy summary, fast keyboard entry with FocusState, locale-aware currency formatting, and the privacy manifest. Use when wiring haptics, sharing, text input, number formatting, or App Store privacy configuration.
---

# SplitFair — iOS platform

100% SwiftUI. The only non-view UIKit touchpoint is an optional `UIPasteboard.general.string` for one-tap Copy.

## Haptics — `.sensoryFeedback` only

Respects system settings automatically (don't read any setting; skip CoreHaptics):
- `.selection` on chip assign (`splitfair-diner-chip`) and tip-preset select
- `.impact(.soft)` on round-up toggle
- `.success` on the reconciliation stamp (`splitfair-reconciliation-banner`) and on Clear

```swift
.sensoryFeedback(.selection, trigger: assignedCount)
.sensoryFeedback(.success, trigger: reconciled)
```

## Copy / Share summary

`ShareLink(item: summaryText)` is the primary action (adds Copy + Messages), plus an optional pasteboard button + "Copied" toast. Build the text through the same currency `FormatStyle`. The summary builder is pure (`Summary.swift`, `splitfair-project-structure`).

## Fast text entry

- **Price fields:** `.decimalPad` **+ a keyboard-toolbar Done button** (`.decimalPad` has no return key). Parse with a cents-accumulator to sidestep the locale decimal-separator bug.
- **Names:** `.default` keyboard, `.words` autocap, autocorrect off, `.submitLabel(.next)`; `@FocusState` + `.onSubmit { append; clear; refocus }` implements "Enter adds another person."

## Currency formatting (edge only)

```swift
Text(Decimal(cents) / 100, format: .currency(code: bill.currency.code))
    .monospacedDigit()   // live totals never jitter
```
Respects device locale. **Don't hardcode `$` or 2 decimals** — derive the minor-unit exponent from the OS and persist it (`splitfair-domain-model`) so JPY (0) / BHD (3) reconcile. `Decimal.FormatStyle.parseStrategy` silently ignores trailing garbage (`"12.50xyz"` → `1250`); `.decimalPad` mostly prevents it, but add a strict re-format-and-compare check.

## Privacy manifest

`PrivacyInfo.xcprivacy`: `NSPrivacyTracking = false`, empty collected-data & tracking-domains, UserDefaults reason `CA92.1`. `ITSAppUsesNonExemptEncryption = NO`. No ATT, no `.entitlements`. See `splitfair-persistence`.
