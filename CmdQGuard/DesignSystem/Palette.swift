import SwiftUI

extension Color {
    /// The protective accent — Aurora purple (prototype hue 272–278°).
    /// Drives prominence, selection tints, and halo glow.
    static let guardAccent = Color(hue: 276/360, saturation: 0.74, brightness: 0.56)

    /// Light-tint variant for selected backgrounds (app picker, row hover).
    /// Mimics the prototype's `oklch(0.96 0.04 272)` subtle tint.
    static let guardAccentTint = Color(hue: 272/360, saturation: 0.18, brightness: 0.96)

    /// The quit / destructive signifier.
    static let guardDanger = Color("DangerColor")

    /// The "protected / safe" signifier (prototype hue 155° — green).
    static let guardProtected = Color("ProtectedColor")

    /// Halo hue used by the Aurora overlay; 272° with a mid-bright luminance.
    static let auroraHalo = Color(hue: 272/360, saturation: 0.75, brightness: 0.58)

    /// Dark card background used by the Aurora overlay card.
    static let overlayCardBase = Color(red: 20/255, green: 22/255, blue: 30/255)

    /// System-settings-style row chrome background for the AX step.
    static let systemRowBackground = Color(nsColor: .controlBackgroundColor)

    /// Secondary / tertiary / quaternary text tones tuned to the prototype.
    static let inkSecondary = Color.secondary
    static let inkTertiary = Color.secondary.opacity(0.7)
}
