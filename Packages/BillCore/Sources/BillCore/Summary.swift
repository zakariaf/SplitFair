import Foundation

/// Builds the plain-text per-person summary for the offline Copy/Share action. Pure and
/// Foundation-only (no UIKit), so it is golden-tested and reused verbatim by the share sheet.
public enum Summary {
    public static func text(for bill: Bill, locale: Locale = .current) -> String {
        let result = BillMath.compute(bill)
        let currency = bill.currency

        var lines = ["SplitFair — total \(MoneyEdge.format(result.grandTotal, currency: currency, locale: locale))"]
        for person in bill.people {
            let total = result.perPerson[person.id]?.total ?? .zero
            lines.append("\(person.name): \(MoneyEdge.format(total, currency: currency, locale: locale))")
        }
        switch bill.tip {
        case let .percent(percent):
            lines.append("(tax + \(percent)% tip, split by what each ordered)")
        case .fixed:
            lines.append("(tax + tip, split by what each ordered)")
        }
        return lines.joined(separator: "\n")
    }
}
