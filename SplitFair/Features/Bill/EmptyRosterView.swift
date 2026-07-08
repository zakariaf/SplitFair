import SwiftUI

/// First-run empty state: the "WHO'S SPLITTING?" hero over an auto-focused name field. Adding a
/// person moves the screen to its populated layout (the roster bar then handles adding more).
struct EmptyRosterView: View {
    @Environment(BillStore.self) private var store
    @State private var draftName = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 26) {
            WhoSplittingHero()
            HStack(spacing: 10) {
                TextField("Name", text: $draftName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .font(.personName)
                    .foregroundStyle(Color.ink)
                    .focused($focused)
                    .onSubmit(add)
                Button(action: add) {
                    Image(systemName: "arrow.right.circle.fill").font(.title)
                }
                .foregroundStyle(Color.tangerine)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.surface))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.keyline, lineWidth: 2))
            .padding(.horizontal, 44)
        }
        .onAppear { focused = true }
    }

    private func add() {
        store.addPerson(named: draftName)
        draftName = ""
        focused = true
    }
}
