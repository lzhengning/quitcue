import AppKit
import SwiftUI

extension Color {
    /// Prototype `--accent`: light `oklch(0.6 0.2 285)`, dark `oklch(0.72 0.2 285)`.
    static let guardAccent = adaptive(
        lightRed: 121/255, lightGreen: 103/255, lightBlue: 240/255,
        darkRed: 155/255, darkGreen: 140/255, darkBlue: 255/255
    )

    /// Prototype primary button / active segment color: `oklch(0.6 0.2 285)`.
    static let guardPrimaryButton = adaptive(
        lightRed: 121/255, lightGreen: 103/255, lightBlue: 240/255,
        darkRed: 121/255, darkGreen: 103/255, darkBlue: 240/255
    )

    /// Prototype hover/deep accent: light `oklch(0.45 0.2 285)`, dark `oklch(0.45 0.2 285)`.
    static let guardAccentDeep = adaptive(
        lightRed: 82/255, lightGreen: 52/255, lightBlue: 188/255,
        darkRed: 82/255, darkGreen: 52/255, darkBlue: 188/255
    )

    /// Prototype `--accent-soft`.
    static let guardAccentTint = adaptive(
        lightRed: 224/255, lightGreen: 224/255, lightBlue: 255/255,
        darkRed: 43/255, darkGreen: 35/255, darkBlue: 93/255
    )

    /// The quit / destructive signifier.
    static let guardDanger = Color("DangerColor")

    /// The "protected / safe" signifier (prototype hue 155° — green).
    static let guardProtected = Color("ProtectedColor")

    /// Halo hue used by the Aurora overlay; 285° with a mid-bright luminance.
    static let auroraHalo = adaptive(
        lightRed: 121/255, lightGreen: 103/255, lightBlue: 240/255,
        darkRed: 155/255, darkGreen: 140/255, darkBlue: 255/255
    )

    /// Dark card background used by the Aurora overlay card.
    static let overlayCardBase = Color(red: 20/255, green: 22/255, blue: 30/255)

    /// System-settings-style row chrome background for the AX step.
    static let systemRowBackground = Color(nsColor: .controlBackgroundColor)

    static let pageBackground = adaptive(
        lightRed: 240/255, lightGreen: 238/255, lightBlue: 233/255,
        darkRed: 26/255, darkGreen: 26/255, darkBlue: 29/255
    )

    /// Exact prototype text tokens (`--lg-text*`).
    static let inkPrimary = adaptive(
        lightRed: 29/255, lightGreen: 31/255, lightBlue: 36/255,
        darkRed: 240/255, darkGreen: 241/255, darkBlue: 245/255
    )
    static let inkSecondary = adaptive(
        lightRed: 58/255, lightGreen: 61/255, lightBlue: 68/255,
        darkRed: 207/255, darkGreen: 209/255, darkBlue: 214/255
    )
    static let inkTertiary = adaptive(
        lightRed: 107/255, lightGreen: 112/255, lightBlue: 120/255,
        darkRed: 154/255, darkGreen: 160/255, darkBlue: 168/255
    )
    static let inkQuaternary = adaptive(
        lightRed: 154/255, lightGreen: 160/255, lightBlue: 168/255,
        darkRed: 107/255, darkGreen: 112/255, darkBlue: 120/255
    )

    /// Window glass shell tokens from the design prototype's Liquid Glass
    /// surface variables.
    static let glassShellTop = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.55,
        darkRed: 38/255, darkGreen: 40/255, darkBlue: 48/255, darkAlpha: 0.68
    )
    static let glassShellBottom = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.32,
        darkRed: 24/255, darkGreen: 26/255, darkBlue: 32/255, darkAlpha: 0.62
    )
    static let glassWashPrimary = adaptive(
        lightRed: 207/255, lightGreen: 204/255, lightBlue: 255/255,
        darkRed: 107/255, darkGreen: 85/255, darkBlue: 223/255
    )
    static let glassWashSecondary = adaptive(
        lightRed: 226/255, lightGreen: 188/255, lightBlue: 255/255,
        darkRed: 130/255, darkGreen: 59/255, darkBlue: 174/255
    )

    static let glassGroupTop = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.72,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.07
    )
    static let glassGroupBottom = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.52,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.03
    )
    static let glassGroupLine = adaptive(
        lightRed: 0, lightGreen: 0, lightBlue: 0, lightAlpha: 0.06,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.08
    )
    static let glassGroupTopHighlight = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.85,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.12
    )
    static let glassGroupInnerHighlight = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.86,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.07
    )
    static let glassGroupBottomShade = adaptive(
        lightRed: 0, lightGreen: 0, lightBlue: 0, lightAlpha: 0.04,
        darkRed: 0, darkGreen: 0, darkBlue: 0, darkAlpha: 0.20
    )
    static let glassDivider = adaptive(
        lightRed: 0, lightGreen: 0, lightBlue: 0, lightAlpha: 0.06,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.06
    )
    static let glassWellTop = adaptive(
        lightRed: 0, lightGreen: 0, lightBlue: 0, lightAlpha: 0.08,
        darkRed: 0, darkGreen: 0, darkBlue: 0, darkAlpha: 0.45
    )
    static let glassWellBottom = adaptive(
        lightRed: 0, lightGreen: 0, lightBlue: 0, lightAlpha: 0.04,
        darkRed: 0, darkGreen: 0, darkBlue: 0, darkAlpha: 0.30
    )
    static let glassWellLine = adaptive(
        lightRed: 0, lightGreen: 0, lightBlue: 0, lightAlpha: 0.12,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.06
    )
    static let glassPillBackground = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.60,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.06
    )
    static let glassPillLine = adaptive(
        lightRed: 0, lightGreen: 0, lightBlue: 0, lightAlpha: 0.06,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.08
    )
    static let glassTitlebarTop = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.40,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.06
    )
    static let glassTitlebarBottom = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.10,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.02
    )
    static let glassTitlebarLine = adaptive(
        lightRed: 0, lightGreen: 0, lightBlue: 0, lightAlpha: 0.08,
        darkRed: 1, darkGreen: 1, darkBlue: 1, darkAlpha: 0.08
    )
    static let glassBadgeStroke = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1, lightAlpha: 0.9,
        darkRed: 28/255, darkGreen: 30/255, darkBlue: 38/255, darkAlpha: 0.9
    )
    static let toggleOffBackground = adaptive(
        lightRed: 120/255, lightGreen: 120/255, lightBlue: 128/255, lightAlpha: 0.32,
        darkRed: 120/255, darkGreen: 120/255, darkBlue: 128/255, darkAlpha: 0.42
    )
    static let toggleKnob = adaptive(
        lightRed: 1, lightGreen: 1, lightBlue: 1,
        darkRed: 246/255, darkGreen: 246/255, darkBlue: 248/255
    )

    static func adaptive(
        lightRed: CGFloat,
        lightGreen: CGFloat,
        lightBlue: CGFloat,
        lightAlpha: CGFloat = 1,
        darkRed: CGFloat,
        darkGreen: CGFloat,
        darkBlue: CGFloat,
        darkAlpha: CGFloat = 1
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            let isDark = bestMatch == .darkAqua
            return NSColor(
                srgbRed: isDark ? darkRed : lightRed,
                green: isDark ? darkGreen : lightGreen,
                blue: isDark ? darkBlue : lightBlue,
                alpha: isDark ? darkAlpha : lightAlpha
            )
        })
    }
}
