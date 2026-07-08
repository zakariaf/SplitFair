---
name: splitfair-tip-controls
description: The tax and tip controls on SplitFair's Screen 2 — the tax field, the tip preset chips (15/18/20/25/custom), the live Acid-Lime tip readout pill, and the pre-tax/total base toggle. Use when building or reviewing tax/tip entry, the live tip amount, or the money-in-motion pill.
---

# SplitFair — tip controls

Screen 2's entry zone. Presets over typing; the live amount is the only place Acid-Lime appears ("money in motion").

## Tax field

`taxcard`: label "TAX" + a right-aligned SF Mono field showing the dollar amount **straight off the receipt** (default `$`), with a small `$`/`%` segmented toggle. The exact printed tax is used directly — never recomputed from a % (`splitfair-money-math`).

## Tip preset chips

Row of `[15][18][20][25][Custom]` as clay-pressable stamps: `RoundedRectangle` r=16, 2pt ink keyline, subtle pressable depth (shadow shrinks on press + `.sensoryFeedback(.selection)`).
- **Unselected:** surface fill, ink label.
- **Selected:** **Tangerine fill, white label**, spring pop, keyline kept.
- **Custom** opens an inline numeric field, never a modal.

## Live readout pill (the one lime element)

Beside the presets: a **`= $11.79` pill in Acid-Lime with ink text** (`splitfair-color-system`), rolling via `.contentTransition(.numericText())` as the tip changes (`splitfair-motion-and-haptics`). Lime always carries ink text.

## Base toggle

A tiny `pre-tax` / `total` segmented control. **Default = pre-tax subtotal.** Show the chosen base in the UI so users trust the math; the choice feeds `resolvedTip` (`splitfair-domain-model`).

```swift
HStack {
    ForEach([15,18,20,25], id: \.self) { pct in
        Button("\(pct)%") { store.setTip(.percent(pct)) }
            .buttonStyle(TipChip(selected: store.bill.tip == .percent(pct)))
    }
    Spacer()
    Text(Decimal(store.totals.tipCents)/100, format: .currency(code: "USD"))
        .font(.money(19)).foregroundStyle(Color.ink)
        .padding(8).background(RoundedRectangle(cornerRadius: 14).fill(Color.acidLime))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink, lineWidth: 2))
        .contentTransition(.numericText())
}
```

## Rules

- Changing a preset recomputes every per-person total live and re-fires the reconciliation stamp (`splitfair-reconciliation-banner`) — it always still reconciles.
- No "Calculate" button anywhere; everything is live (`splitfair-app-architecture`).
- Every chip/toggle ≥ 44pt (`splitfair-accessibility`).
