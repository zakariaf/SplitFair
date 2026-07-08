import Foundation

/// The currency a bill is denominated in.
///
/// One `Bill` is denominated in exactly one `Currency`, so `Money` arithmetic never has to guard
/// currency equality. `exponent` is the number of minor-unit digits (2 for USD/EUR, 0 for JPY,
/// 3 for BHD). It is derived from the OS at bill-creation time and **persisted**, so a bill
/// reconciles identically even if the device locale changes before relaunch.
public struct Currency: Hashable, Sendable, Codable {
    public var code: String
    public var exponent: Int

    public init(code: String, exponent: Int) {
        self.code = code
        self.exponent = exponent
    }

    /// US dollars — the default until a bill's locale is resolved at the edge.
    public static let usd = Currency(code: "USD", exponent: 2)
}
