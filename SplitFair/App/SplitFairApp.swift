import SwiftUI

@main
struct SplitFairApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootPlaceholderView()
            }
        }
    }
}

/// Temporary root shown until EPIC 06 replaces it with the Bill screen.
/// Confirms the navigation shell builds and launches.
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

#Preview {
    NavigationStack { RootPlaceholderView() }
}
