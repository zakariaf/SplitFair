import Foundation
import Testing
@testable import BillCore

@Suite("Money & Currency")
struct MoneyTests {
    @Test("Additive arithmetic and zero")
    func arithmetic() {
        #expect(Money.zero + Money(5) == Money(5))
        #expect(Money(700) + Money(25) == Money(725))
        #expect(Money(725) - Money(725) == .zero)
    }

    @Test("Comparable")
    func comparable() {
        #expect(Money(3) < Money(4))
        #expect(!(Money(4) < Money(4)))
        #expect(Money(-100) < Money.zero) // a discount is less than nothing
    }

    @Test("Codable round-trip is identity-preserving")
    func codableRoundTrip() throws {
        for value in [Money.zero, Money(1), Money(9720), Money(-250)] {
            let data = try JSONEncoder().encode(value)
            #expect(try JSONDecoder().decode(Money.self, from: data) == value)
        }
        let currency = Currency(code: "JPY", exponent: 0)
        let data = try JSONEncoder().encode(currency)
        #expect(try JSONDecoder().decode(Currency.self, from: data) == currency)
    }
}
