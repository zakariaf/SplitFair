import BillCore
import Foundation

/// Display-only money formatting for the UI. Uses `Decimal` at the edge (never `Double`); the
/// integer cents are the source of truth.
enum MoneyDisplay {
    /// Full currency string, e.g. "$51.93".
    static func full(_ money: Money, _ currency: Currency, locale: Locale = .current) -> String {
        MoneyEdge.format(money, currency: currency, locale: locale)
    }

    /// Number only, no currency symbol, e.g. "28.00" — used inside the split-ring.
    static func plain(_ money: Money, _ currency: Currency, locale: Locale = .current) -> String {
        var scale = Decimal(1)
        for _ in 0 ..< max(currency.exponent, 0) { scale *= 10 }
        return (Decimal(money.minorUnits) / scale)
            .formatted(.number.precision(.fractionLength(currency.exponent)).locale(locale))
    }
}
