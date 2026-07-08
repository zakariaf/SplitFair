import SwiftUI

/// The one loud CTA: Tangerine fill, white money-font label, 2pt ink keyline, and a hard offset
/// shadow that collapses as the button pushes down on press. Disabled shows a reason and stays put.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var enabled = true
    var disabledTitle: String?
    let action: () -> Void
    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            HStack(spacing: 8) {
                Text(enabled ? title : (disabledTitle ?? title))
                if enabled, let systemImage { Image(systemName: systemImage) }
            }
            .font(.money(16))
            .foregroundStyle(enabled ? Color.white : Color.inkSoft)
            .padding(.vertical, 15)
            .padding(.horizontal, 22)
        }
        .buttonStyle(HardPressButtonStyle(fill: enabled ? Color.tangerine : Color.divider))
        .disabled(!enabled)
        .sensoryFeedback(.selection, trigger: taps)
    }
}

/// A lower-emphasis outlined action (e.g. "Copy summary").
struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.money(15))
            .foregroundStyle(Color.ink)
            .padding(.vertical, 13)
            .padding(.horizontal, 18)
        }
        .buttonStyle(HardPressButtonStyle(fill: Color.surface, shadowDX: 2, shadowDY: 3))
    }
}

/// The destructive "Clear bill" — ink keyline, danger-red label. The parent gates it behind the
/// app's only confirm dialog.
struct DangerButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "trash")
                .font(.money(15))
                .foregroundStyle(Color.danger)
                .padding(.vertical, 13)
                .padding(.horizontal, 18)
        }
        .buttonStyle(HardPressButtonStyle(fill: Color.surface, shadowDX: 2, shadowDY: 3))
    }
}

/// Hard offset shadow that collapses and pushes the button down on press — a physical "push".
struct HardPressButtonStyle: ButtonStyle {
    var fill: Color
    var corner: CGFloat = 20
    var shadowDX: CGFloat = 3
    var shadowDY: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        let pressed = configuration.isPressed
        return configuration.label
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(Color.keyline, lineWidth: 2))
            .background(shape.fill(Color.hardShadow).offset(x: pressed ? 1 : shadowDX, y: pressed ? 1 : shadowDY))
            .offset(y: pressed ? 3 : 0)
            .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        PrimaryButton(title: "Next: Tax & Tip", systemImage: "arrow.right") {}
        PrimaryButton(title: "Next", enabled: false, disabledTitle: "Assign all items first") {}
        HStack {
            SecondaryButton(title: "Copy summary", systemImage: "doc.on.doc") {}
            DangerButton(title: "Clear bill") {}
        }
    }
    .padding()
    .background(Color.canvas)
}
