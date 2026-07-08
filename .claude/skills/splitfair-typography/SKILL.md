---
name: splitfair-typography
description: SplitFair's three-voice type system — SF Mono ledger, SF Pro Rounded display money, and a bundled Fraunces serif voice — with a fixed type scale and tabular-numeral rules. Use when setting any text style, sizing numbers, choosing fonts, or ensuring money never jitters or truncates.
---

# SplitFair — typography

Three voices: the **ledger** speaks printer-receipt monospace (trust), the **display** speaks friendly rounded (arm's-length legibility + joy), the **voice** speaks a warm serif (character). All offline.

| Face | Role | Notes |
|---|---|---|
| **SF Mono** (Heavy/Bold) | Ledger — item prices, prorated tax/tip breakdown lines | Column-aligns like printer output — the trust cue. `.monospacedDigit()`. |
| **SF Pro Rounded** (Black) | Display money — hero subtotal, per-person totals, live tip readout, reconciliation total | `.monospacedDigit()` always. Odometer via `.contentTransition(.numericText())`. |
| **Fraunces** (variable serif, SIL OFL, bundled once) | Voice — wordmark, section titles ("THE BILL", "TAX, TIP & TOTALS"), the "WHO'S SPLITTING?" hero **only** | High optical size + slight soft/"wonky" axis. |
| **SF Pro (Text)** | Body, labels, captions | Regular/Medium. |

```swift
extension Font {
    static func money(_ s: CGFloat)  -> Font { .system(size: s, weight: .black, design: .rounded).monospacedDigit() }
    static func ledger(_ s: CGFloat) -> Font { .system(size: s, weight: .heavy, design: .monospaced).monospacedDigit() }
    static func display(_ s: CGFloat)-> Font { .custom("Fraunces", size: s) } // register in Info.plist ATSApplicationFontsPath
}
```

## Type scale (map to Dynamic Type via `relativeTo:`)

| Element | Font | Size |
|---|---|---|
| Hero subtotal / odometer | money | 56 (cap 64) |
| "WHO'S SPLITTING?" hero | display | ~48 |
| Wordmark / section title | display | 32–34 |
| Per-person total | money | 40 |
| Live tip readout pill | money | 26 |
| Item price (ledger) | ledger | 24 |
| Body / person name | SF Pro | 17 |
| Chip initials | rounded semibold | 15 |
| Breakdown ledger line | ledger | 15 |
| Caption / meta | SF Pro | 13 |

## Non-negotiable numeral rules

- **Every changeable amount uses `.monospacedDigit()`** so columns align and numbers never reflow or jitter mid-animation.
- **Prices never truncate — they wrap** to a second line. Display/hero sizes **cap** their Dynamic Type growth.
- Big totals target 7:1 contrast; all money ≥ 4.5:1 (`splitfair-accessibility`).
- Use the **voice serif sparingly** — wordmark, section titles, hero only. Overusing it kills its "voice" role and hurts legibility.
