import SwiftUI

@main
struct SplitFairApp: App {
    /// The single store, constructed ONCE at the app root and injected into the environment.
    /// Never construct it inside a child view — `@State` re-runs its initializer on rebuilds.
    @State private var store = BillStore(
        seedSample: CommandLine.arguments.contains("--seed-sample")
            || CommandLine.arguments.contains("--start-totals")
            || CommandLine.arguments.contains("--start-bill")
    )
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Screenshot / UI-test seams that deep-link past the Bills home screen.
    private let startOnTotals = CommandLine.arguments.contains("--start-totals")
    private let startOnBill = CommandLine.arguments.contains("--start-bill")

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if startOnTotals {
                    TotalsScreen()
                } else if startOnBill {
                    BillScreen()
                } else {
                    BillsHomeScreen()
                }
            }
            .environment(store)
            // Reduce Motion: nil out animations app-wide (springs/odometer/stamp collapse to
            // instant). The drifting blobs and glass rail already opt out of motion/transparency.
            .transaction { transaction in
                if reduceMotion { transaction.animation = nil }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Belt-and-suspenders: flush the draft immediately when leaving the foreground,
            // in addition to the debounced auto-save, so a background/lock never loses the bill.
            if newPhase != .active {
                Task { await store.flush() }
            }
        }
    }
}
