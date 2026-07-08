import Foundation

/// Splits `amountCents` across `weights` using integer largest-remainder (Hamilton) apportionment,
/// guaranteeing the returned parts sum **exactly** to `amountCents`.
///
/// This is the single money-splitting primitive in SplitFair. Route every division of money through
/// it — shared items, tax proration, tip proration — so there is exactly one rounding code path to
/// trust. No `Double`/`Float` ever enters: shares are computed from the integer product `amount * w`,
/// then the leftover minor units (provably fewer than `weights.count`) are handed to the largest
/// fractional remainders.
///
/// Guarantees and edge handling:
/// - **Conservation:** `result.reduce(0, +) == amountCents`, always (asserted in debug builds).
/// - **Residual < n:** every share is `floor(ideal)` or `floor(ideal) + 1`.
/// - **Deterministic tie-break:** equal remainders give the leftover unit to the lower index first,
///   so the same bill splits identically on every device.
/// - **Negative amount** (a discount/comp): mirrors the positive split and negates each part.
/// - **Negative weights:** clamped to `0`.
/// - **Zero weight-sum** (e.g. everyone comped): equal-weight `[1, 1, …]` fallback, so a residual
///   tax/tip still splits evenly instead of dividing by zero.
/// - **Empty weights:** returns `[]` rather than trapping — money math must not crash the UI.
///
/// - **Precondition:** `amountCents` and `weights` are integer minor units of a real bill, well
///   within `Int` range. Like the standard library's integer negation, the function assumes money
///   magnitudes and does not defend against degenerate non-money inputs (e.g. `amountCents == Int.min`,
///   or an `amountCents * weight` product that overflows `Int64`). Those are programmer errors, not
///   values reachable from a `MoneyEdge`-parsed bill.
public func allocate(amountCents: Cents, weights: [Int]) -> [Cents] {
    let n = weights.count
    guard n > 0 else { return [] }

    // Negative total (discount/comp): split the magnitude, then negate elementwise.
    if amountCents < 0 {
        return allocate(amountCents: -amountCents, weights: weights).map(-)
    }

    // Clamp stray negative weights; fall back to equal weights when the sum is zero.
    let sanitized = weights.map { max($0, 0) }
    let weightSum = sanitized.reduce(0, +)
    let w = weightSum == 0 ? [Int](repeating: 1, count: n) : sanitized
    let W = weightSum == 0 ? n : weightSum

    // Floor share + integer remainder, product-first (never a float touches money).
    var shares = [Cents](repeating: 0, count: n)
    var remainders: [(remainder: Int, index: Int)] = []
    remainders.reserveCapacity(n)
    var distributed = 0
    for i in 0 ..< n {
        let product = amountCents * w[i] // Int is 64-bit on all targets; safe for any real bill
        let floorShare = product / W // integer floor (amountCents >= 0 here)
        shares[i] = floorShare
        distributed += floorShare
        remainders.append((product % W, i))
    }

    // Hand the leftover minor units to the largest remainders; ties -> ascending index.
    var leftover = amountCents - distributed // always in 0 ..< n
    remainders.sort { $0.remainder != $1.remainder ? $0.remainder > $1.remainder : $0.index < $1.index }
    var k = 0
    while leftover > 0 {
        shares[remainders[k].index] += 1
        leftover -= 1
        k += 1
    }

    assert(shares.reduce(0, +) == amountCents, "allocate must be exact")
    return shares
}
