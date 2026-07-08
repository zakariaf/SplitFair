import Foundation

/// The one place where human-readable money strings meet integer minor units. Parsing and
/// formatting are locale-aware; no `Double`/`Float` is ever produced, and a parsed value is
/// returned as `Money` (integer cents) immediately so it never re-enters the arithmetic.
public enum MoneyEdge {
    /// Parse a user-entered amount into `Money`, in the given currency's minor units.
    ///
    /// Locale-aware (decimal + grouping separators) and **strict**: it returns `nil` for anything
    /// that is not a clean number — this is the deliberate guard against `Decimal.FormatStyle`'s
    /// silent "12.50xyz" -> 1250 behaviour. More fractional digits than the currency has, multiple
    /// decimal separators, stray characters, and overflow all return `nil` rather than a wrong value
    /// or a crash.
    public static func parse(_ text: String, currency: Currency, locale: Locale = .current) -> Money? {
        let decimalSeparator = locale.decimalSeparator ?? "."
        let groupingSeparator = locale.groupingSeparator ?? ","

        var string = text.trimmingCharacters(in: .whitespaces)
        guard !string.isEmpty else { return nil }

        var sign = 1
        if string.hasPrefix("-") {
            sign = -1
            string.removeFirst()
        } else if string.hasPrefix("+") {
            string.removeFirst()
        }

        string = string.replacingOccurrences(of: groupingSeparator, with: "") // grouping carries no value

        let parts = string.components(separatedBy: decimalSeparator)
        guard parts.count <= 2 else { return nil } // more than one decimal separator -> invalid
        let wholeText = parts[0]
        let fractionText = parts.count == 2 ? parts[1] : ""

        let digits = Set("0123456789")
        guard wholeText.allSatisfy(digits.contains), fractionText.allSatisfy(digits.contains) else { return nil }
        guard !(wholeText.isEmpty && fractionText.isEmpty) else { return nil }
        guard fractionText.count <= currency.exponent else { return nil } // more precision than the currency has

        guard let whole = Int(wholeText.isEmpty ? "0" : wholeText) else { return nil }
        let padded = fractionText.padding(toLength: currency.exponent, withPad: "0", startingAt: 0)
        guard let fraction = Int(padded.isEmpty ? "0" : padded) else { return nil }

        // Combine to minor units with overflow-safe integer math (never trap the UI).
        let (scaled, overflowedMultiply) = whole.multipliedReportingOverflow(by: pow10(currency.exponent))
        guard !overflowedMultiply else { return nil }
        let (magnitude, overflowedAdd) = scaled.addingReportingOverflow(fraction)
        guard !overflowedAdd else { return nil }
        return Money(sign * magnitude)
    }

    /// Format `Money` for display in the given currency and locale (e.g. `$20.39`, `¥1,234`).
    /// `Decimal` is used only here, at the edge, and is built from the exact integer cents.
    public static func format(_ money: Money, currency: Currency, locale: Locale = .current) -> String {
        let value = Decimal(money.minorUnits) / Decimal(pow10(currency.exponent))
        return value.formatted(.currency(code: currency.code).locale(locale))
    }

    private static func pow10(_ exponent: Int) -> Int {
        var result = 1
        for _ in 0 ..< max(exponent, 0) { result *= 10 }
        return result
    }
}
