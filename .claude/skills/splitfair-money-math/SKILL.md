---
name: splitfair-money-math
description: The correctness-critical money math for SplitFair — integer cents and one largest-remainder allocate() primitive used for shared items, tax, and tip so per-person totals always sum to the grand total to the exact cent. Use whenever splitting, prorating, rounding, or reconciling money, or writing/reviewing any code that computes amounts.
---

# SplitFair — money math

This is the product. Get it exactly right; everything else is decoration.

## Foundations

- **Represent every amount as `Int` minor units (cents).** No `Double`/`Float`, ever. Integers make "sum of parts == whole to the exact cent" structural, not hoped-for.
- **Route every division of money through ONE function: `allocate(amountCents:weights:)`** — shared items, tax proration, tip proration. One rounding path = one thing to test.

## `allocate()` — integer largest-remainder (Hamilton)

```swift
public typealias Cents = Int

/// Splits `amountCents` across `weights`, guaranteeing the parts sum EXACTLY to `amountCents`.
/// Conservation asserted in debug; residual < n; deterministic ascending-index tie-break;
/// negative amount mirrors + negates (discounts/comps); zero weight-sum → equal-weight fallback;
/// empty weights → [] (never traps — money math must not crash the UI).
public func allocate(amountCents: Cents, weights: [Int]) -> [Cents] {
    let n = weights.count
    guard n > 0 else { return [] }
    if amountCents < 0 { return allocate(amountCents: -amountCents, weights: weights).map(-) }

    let sanitized = weights.map { max($0, 0) }
    let weightSum = sanitized.reduce(0, +)
    let w = weightSum == 0 ? [Int](repeating: 1, count: n) : sanitized
    let W = weightSum == 0 ? n : weightSum

    var shares = [Cents](repeating: 0, count: n)
    var remainders = [(remainder: Int, index: Int)](); remainders.reserveCapacity(n)
    var distributed = 0
    for i in 0..<n {
        let product = amountCents * w[i]        // product FIRST, then div/mod — no float
        let floorShare = product / W
        shares[i] = floorShare; distributed += floorShare
        remainders.append((product % W, i))
    }
    var leftover = amountCents - distributed    // always in 0 ..< n
    remainders.sort { $0.remainder != $1.remainder ? $0.remainder > $1.remainder : $0.index < $1.index }
    var k = 0
    while leftover > 0 { shares[remainders[k].index] += 1; leftover -= 1; k += 1 }
    assert(shares.reduce(0, +) == amountCents, "allocate must be exact")
    return shares
}
```
Verified vectors: `allocate(1001,[1,1,1]) == [334,334,333]` · `allocate(660,[1584,4033,1933]) == [138,353,169]` · `allocate(1510,[1584,4033,1933]) == [317,807,386]`.

## The three passes (each closed by allocate)

1. **Item subtotals.** Personal item cents → its owner. Each shared item → `allocate(itemCents, [1]*k)` across its `k` assignees (roster order). Person subtotal `S[i]` = personal + shared shares.
2. **Tax.** Take the exact printed `taxCents` (do NOT recompute from a %) and `tax = allocate(taxCents, S)`.
3. **Tip.** `tip = allocate(tipCents, S)`. Default base = **pre-tax subtotal** (toggle for post-tax).

`finalᵢ = S[i] + tax[i] + tip[i]`. Because every whole-bill figure is distributed by `allocate()`, the per-person finals sum to the grand total to the exact cent, for any input.

## The invariant that must never break

`Σ perPerson.total == assignedSubtotal + taxCents + tipCents == grandTotal`, exactly. Assert it and test it (`splitfair-testing`).

## Traps

- **Two rounding sites, not one:** `allocate()` AND percent→cents. Round the percent to `Int` **once** before feeding `allocate()` — `tipCents = Int((assignedSubtotal * pct).rounded())`. A naive `Double` percent is a classic off-by-a-cent bug allocate() coverage won't catch.
- **Never sum independently-rounded parts to get a total.** Always allocate a known integer total and let the parts absorb the residual.
- **Worked anchor:** items 1250 + 2800 + 900 + 1600 + nachos 1000(shared 3) ; tax 660 ; tip 20% = 1510 → Ana 2039 / Ben 5193 / Cy 2488, grand **9720**.
