import Foundation
import Testing
@testable import BillCore

@Suite("MoneyEdge — parse & format")
struct MoneyEdgeTests {
    private let usd = Currency.usd
    private let us = Locale(identifier: "en_US")

    @Test("Parses clean amounts to cents")
    func parseValid() {
        #expect(MoneyEdge.parse("20.39", currency: usd, locale: us) == Money(2039))
        #expect(MoneyEdge.parse("0.05", currency: usd, locale: us) == Money(5))
        #expect(MoneyEdge.parse("100", currency: usd, locale: us) == Money(10000))
        #expect(MoneyEdge.parse("1,234.50", currency: usd, locale: us) == Money(123450)) // grouping stripped
        #expect(MoneyEdge.parse(".5", currency: usd, locale: us) == Money(50))
        #expect(MoneyEdge.parse("-2.50", currency: usd, locale: us) == Money(-250)) // discount
    }

    @Test("Rejects malformed input FormatStyle would silently accept")
    func parseInvalid() {
        #expect(MoneyEdge.parse("12.50xyz", currency: usd, locale: us) == nil) // trailing garbage
        #expect(MoneyEdge.parse("12.999", currency: usd, locale: us) == nil) // more precision than cents
        #expect(MoneyEdge.parse("1.2.3", currency: usd, locale: us) == nil) // two decimal separators
        #expect(MoneyEdge.parse("", currency: usd, locale: us) == nil)
        #expect(MoneyEdge.parse("abc", currency: usd, locale: us) == nil)
        #expect(MoneyEdge.parse("99999999999999999999", currency: usd, locale: us) == nil) // overflow, no trap
    }

    @Test("Currency exponent drives precision (JPY has no minor unit)")
    func exponent() {
        let jpy = Currency(code: "JPY", exponent: 0)
        #expect(MoneyEdge.parse("1234", currency: jpy, locale: us) == Money(1234))
        #expect(MoneyEdge.parse("1234.5", currency: jpy, locale: us) == nil)
    }

    @Test("Formats cents back to a localized currency string")
    func format() {
        #expect(MoneyEdge.format(Money(2039), currency: usd, locale: us) == "$20.39")
        #expect(MoneyEdge.format(Money(9720), currency: usd, locale: us) == "$97.20")
        #expect(MoneyEdge.format(Money(1234), currency: Currency(code: "JPY", exponent: 0), locale: us).contains("1,234"))
    }

    @Test("parse and format round-trip")
    func roundTrip() {
        for cents in [0, 5, 2039, 9720, -250] {
            let formatted = MoneyEdge.format(Money(cents), currency: usd, locale: us)
            // Strip the currency symbol the formatter added, then re-parse.
            let stripped = formatted.replacingOccurrences(of: "$", with: "")
            #expect(MoneyEdge.parse(stripped, currency: usd, locale: us) == Money(cents))
        }
    }
}
