// swift-tools-version: 6.0
import PackageDescription

// BillCore — the pure, Foundation-only money/split domain for SplitFair.
// It deliberately declares NO SwiftUI/UIKit dependency: the missing import is a
// compile firewall around the correctness-critical math, and it lets `swift test`
// run the whole suite in milliseconds with no simulator.
let package = Package(
    name: "BillCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BillCore", targets: ["BillCore"]),
    ],
    targets: [
        .target(name: "BillCore"),
        .testTarget(name: "BillCoreTests", dependencies: ["BillCore"]),
    ]
)
