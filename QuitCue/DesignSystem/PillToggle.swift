import SwiftUI

/// Theme-tinted system switch. On macOS 26 this inherits the native Liquid
/// Glass switch rendering; older systems fall back to the platform switch.
struct PillToggle: View {
    @Binding var isOn: Bool
    /// Called instead of direct `isOn` write when the user taps to turn ON.
    /// Lets callers route through `AccessibilityPermission.requestIfNeeded`.
    var onTurnOn: (() -> Void)?

    var body: some View {
        Toggle("", isOn: binding)
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(.guardAccent)
            .accentColor(.guardAccent)
            .controlSize(.small)
            .accessibilityValue(isOn ? "On" : "Off")
    }

    private var binding: Binding<Bool> {
        Binding {
            isOn
        } set: { newValue in
            if newValue {
                if !isOn, let onTurnOn {
                    onTurnOn()
                } else {
                    isOn = true
                }
            } else {
                isOn = false
            }
        }
    }
}

/// Flat-grouped-list-style row container — mimics the System Settings
/// "Allow to control your Mac" card the prototype wraps around the AX toggle.
struct SystemSettingsRow<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.glassGroupTop,
                                Color.glassGroupBottom
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.glassGroupInnerHighlight, lineWidth: 0.5)
                    .blendMode(.screen)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.glassGroupLine, lineWidth: 0.5)
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.glassGroupTopHighlight)
                    .frame(height: 1)
                    .blendMode(.screen)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.glassGroupBottomShade)
                    .frame(height: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }
}

#Preview {
    PillToggle(isOn: .constant(true))
        .padding(40)
}
