// BillCore — pure, Foundation-only domain for SplitFair.
//
// Money, Currency, the allocate() largest-remainder primitive, the Bill model,
// BillMath.compute, MoneyEdge, and Summary all live in this module (EPIC 02).
// Nothing here may import SwiftUI or UIKit — that omission is the compile firewall
// that keeps a Double/Float or a view out of the money math.
import Foundation
