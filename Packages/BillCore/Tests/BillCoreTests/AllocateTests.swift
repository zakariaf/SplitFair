import Foundation
import Testing
@testable import BillCore

@Suite("allocate — largest remainder")
struct AllocateTests {
    /// THE core invariant, fuzzed 500 ways: the parts always sum to the exact input, and every
    /// share is floor(ideal) or floor(ideal) + 1 (residual < n). Seeded, so failures reproduce.
    @Test("Conservation and residual < n (fuzzed, reproducible)", arguments: 0 ..< 500)
    func conservationAndResidual(seed: Int) {
        var rng = SeededRNG(seed: UInt64(seed))
        let n = Int.random(in: 1 ... 20, using: &rng)
        let amount = Int.random(in: 0 ... 1_000_000, using: &rng)
        let weights = (0 ..< n).map { _ in Int.random(in: 0 ... 5000, using: &rng) }

        let shares = allocate(amountCents: amount, weights: weights)

        #expect(shares.reduce(0, +) == amount) // exact to the cent, always
        #expect(shares.count == n)

        let totalW = weights.reduce(0, +)
        let effectiveW = totalW == 0 ? n : totalW
        for i in 0 ..< n {
            let w = totalW == 0 ? 1 : weights[i]
            let floorShare = (amount * w) / effectiveW
            #expect(shares[i] == floorShare || shares[i] == floorShare + 1)
        }
    }

    @Test("Deterministic ascending-index tie-break, stable across calls")
    func tieBreak() {
        #expect(allocate(amountCents: 1001, weights: [1, 1, 1]) == [334, 334, 333])
        #expect(allocate(amountCents: 2, weights: [1, 1, 1]) == [1, 1, 0])
        #expect(allocate(amountCents: 1000, weights: [1, 1, 1]) == allocate(amountCents: 1000, weights: [1, 1, 1]))
    }

    /// The exact vectors the $97.20 acceptance bill relies on (nachos shared 3 ways, tax, 20% tip).
    @Test("Verified proration vectors from the spec")
    func vectors() {
        #expect(allocate(amountCents: 1000, weights: [1, 1, 1]) == [334, 333, 333])
        #expect(allocate(amountCents: 660, weights: [1584, 4033, 1933]) == [138, 353, 169])
        #expect(allocate(amountCents: 1510, weights: [1584, 4033, 1933]) == [317, 807, 386])
    }

    @Test("Pathological edges")
    func edges() {
        #expect(allocate(amountCents: 1, weights: [1, 1, 1]) == [1, 0, 0]) // 1 cent, 3 ways
        #expect(allocate(amountCents: 123, weights: [1]) == [123]) // single odd-cent identity
        #expect(allocate(amountCents: 100, weights: [0, 0, 0]) == [34, 33, 33]) // everyone comped -> equal split
        #expect(allocate(amountCents: 10, weights: []) == []) // empty roster, no trap
        #expect(allocate(amountCents: 0, weights: [5, 3, 2]) == [0, 0, 0]) // nothing to split
    }

    @Test("Negative amount mirrors the positive split and sums to -A (discounts/comps)")
    func negativeMirror() {
        let weights = [1584, 4033, 1933]
        #expect(allocate(amountCents: -1000, weights: weights) == allocate(amountCents: 1000, weights: weights).map { -$0 })
        #expect(allocate(amountCents: -1000, weights: weights).reduce(0, +) == -1000)
        #expect(allocate(amountCents: -1, weights: [1, 1, 1]) == [-1, 0, 0])
    }

    @Test("Negative weights are clamped to zero")
    func negativeWeights() {
        #expect(allocate(amountCents: 100, weights: [-5, 1, 1]) == allocate(amountCents: 100, weights: [0, 1, 1]))
    }
}
