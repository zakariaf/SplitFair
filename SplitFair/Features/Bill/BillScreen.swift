import BillCore
import SwiftUI

/// Screen 1 — "The Bill". Add people, add items, and tap to assign who ordered what. A sticky diner
/// roster on top, a scrolling item list, and a sticky footer with the running subtotal + Next.
struct BillScreen: View {
    @Environment(BillStore.self) private var store
    @State private var showTotals = false
    @State private var wiggle = false

    var body: some View {
        ZStack {
            BillBackground()
            if store.bill.people.isEmpty {
                EmptyRosterView()
            } else {
                populated
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showTotals) { TotalsScreen() }
    }

    private var populated: some View {
        VStack(spacing: 0) {
            DinerBar()
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(store.bill.items) { item in
                        ItemRow(
                            item: item,
                            people: store.bill.people,
                            currency: store.bill.currency,
                            onToggle: { store.toggleAssignment(item: item.id, person: $0) },
                            onSharedByAll: { store.assignToEveryone(item: item.id) },
                            onSetAmount: { store.setItemAmount(item.id, $0) }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteItem(item.id)
                            } label: {
                                Label("Delete \(item.label.isEmpty ? "item" : item.label)", systemImage: "trash")
                            }
                        }
                    }
                    AddItemRow()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 130)
            }
        }
        .safeAreaInset(edge: .bottom) { footer }
        // A light tap on every assignment change (single toggle or a Shared-by-all cascade).
        .sensoryFeedback(.selection, trigger: assignmentSignature)
    }

    /// Changes on any assignment toggle — the trigger for the assign haptic.
    private var assignmentSignature: Int {
        store.bill.items.reduce(0) { $0 + $1.assigneeIDs.count }
    }

    private var footer: some View {
        FooterRail(
            title: "Subtotal",
            amount: MoneyDisplay.full(itemsSubtotal, store.bill.currency),
            unassignedCount: unassignedCount
        ) {
            PrimaryButton(
                title: "Next: Tax & Tip",
                systemImage: "arrow.right",
                enabled: unassignedCount == 0,
                disabledTitle: "Assign all items first"
            ) { advance() }
            .modifier(ShakeEffect(travel: wiggle ? 1 : 0))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var itemsSubtotal: Money {
        store.bill.items.reduce(Money.zero) { $0 + $1.amount }
    }

    private var unassignedCount: Int {
        let roster = Set(store.bill.people.map(\.id))
        return store.bill.items.filter { $0.assigneeIDs.isDisjoint(with: roster) }.count
    }

    private func advance() {
        if unassignedCount == 0 {
            showTotals = true
        } else {
            withAnimation(.default) { wiggle.toggle() }
        }
    }
}

/// The warm cream canvas + dot-matrix grid + drifting blobs, shared by both screens.
struct BillBackground: View {
    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            DotMatrixBackground().ignoresSafeArea()
            DriftingBlobs().ignoresSafeArea()
        }
    }
}

/// A one-shot horizontal shake for the blocked "Next" action.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat
    var animatableData: CGFloat {
        get { travel }
        set { travel = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(travel * .pi * 4), y: 0))
    }
}
