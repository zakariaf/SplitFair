import SwiftUI

@main
struct SplitFairApp: App {
    /// The single store, constructed ONCE at the app root and injected into the environment.
    /// Never construct it inside a child view — `@State` re-runs its initializer on rebuilds.
    @State private var store = BillStore(
        seedSample: CommandLine.arguments.contains("--seed-sample")
            || CommandLine.arguments.contains("--start-totals")
    )
    @Environment(\.scenePhase) private var scenePhase

    private let startOnTotals = CommandLine.arguments.contains("--start-totals")

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if startOnTotals {
                    TotalsScreen() // screenshot/UI-test seam
                } else {
                    BillScreen()
                }
            }
            .environment(store)
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
