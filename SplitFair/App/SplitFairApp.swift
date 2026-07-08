import SwiftUI

@main
struct SplitFairApp: App {
    /// The single store, constructed ONCE at the app root and injected into the environment.
    /// Never construct it inside a child view — `@State` re-runs its initializer on rebuilds.
    @State private var store = BillStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootPlaceholderView()
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

/// Temporary root shown until EPIC 06 replaces it with the Bill screen.
private struct RootPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.split.2x1")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.tint)
            Text("SplitFair")
                .font(.largeTitle.weight(.bold))
            Text("Split the bill by who ordered what.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("SplitFair")
        .navigationBarTitleDisplayMode(.inline)
    }
}
