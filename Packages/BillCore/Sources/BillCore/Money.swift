import Foundation

/// A raw integer number of a currency's minor units. Used inside allocation math,
/// where values are plain integers rather than the `Money` wrapper.
public typealias Cents = Int

/// A monetary amount stored as an integer number of a currency's minor units (e.g. cents).
///
/// A `Double`/`Float` must never touch money — base-2 floats cannot represent `0.01` exactly.
/// Integers make "sum of the parts equals the whole to the exact cent" a structural guarantee
/// rather than something rounding has to preserve. Negative values are legal and represent a
/// discount or credit.
public struct Money: Hashable, Sendable, Codable, Comparable, AdditiveArithmetic {
    public var minorUnits: Int

    public init(_ minorUnits: Int) {
        self.minorUnits = minorUnits
    }

    public static let zero = Money(0)

    public static func + (lhs: Money, rhs: Money) -> Money {
        Money(lhs.minorUnits + rhs.minorUnits)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        Money(lhs.minorUnits - rhs.minorUnits)
    }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.minorUnits < rhs.minorUnits
    }
}
