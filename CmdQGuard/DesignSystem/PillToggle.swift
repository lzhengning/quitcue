import SwiftUI

/// iOS-style pill toggle used by the Accessibility onboarding row, per the
/// prototype's inline-styled toggle. Matches macOS 14+ `Toggle(.switch)`
/// accessibility traits (it reports as a `checkBox` to XCUI) but gives us
/// pixel control over geometry and color.
struct PillToggle: View {
    @Binding var isOn: Bool
    /// Called instead of direct `isOn` write when the user taps to turn ON.
    /// Lets callers route through `AccessibilityPermission.requestIfNeeded`.
    var onTurnOn: (() -> Void)?

    private let size: CGSize = .init(width: 38, height: 22)
    private let knob: CGFloat = 20

    var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? Color(hue: 155/360, saturation: 0.60, brightness: 0.70) : Color(white: 0.47, opacity: 0.32))
                .overlay(
                    Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                )

            Circle()
                .fill(Color.white)
                .frame(width: knob, height: knob)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                .shadow(color: .black.opacity(0.04), radius: 0, y: 0)
                .offset(x: isOn ? (size.width - knob) / 2 - 1 : -(size.width - knob) / 2 + 1)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onTapGesture {
            if isOn {
                isOn = false
            } else if let onTurnOn {
                onTurnOn()
            } else {
                isOn = true
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isOn)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "On" : "Off")
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
                    .fill(Color.systemRowBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 0, y: 0.5)
    }
}

#Preview {
    PillToggle(isOn: .constant(true))
        .padding(40)
}
