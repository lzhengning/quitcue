import SwiftUI

/// Typographic scale distilled from the HTML prototype. Use these instead
/// of raw `Font.system(size:)` calls so the hierarchy stays consistent as
/// views multiply.
enum AppTypography {
    /// 26pt, semibold, letter-spacing -0.5 — welcome / hero headlines.
    static let title1: Font = .system(size: 26, weight: .semibold)
    /// 20pt, semibold, letter-spacing -0.3 — section / step titles.
    static let title2: Font = .system(size: 20, weight: .semibold)
    /// 15pt, semibold — overlay card title.
    static let title3: Font = .system(size: 15, weight: .semibold)
    /// 13pt, medium — row titles / primary body text.
    static let bodyMedium: Font = .system(size: 13, weight: .medium)
    /// 13pt, regular — body prose.
    static let body: Font = .system(size: 13)
    /// 12pt, regular — footer text, secondary status.
    static let footnote: Font = .system(size: 12)
    /// 11pt, regular — captions / bundle IDs.
    static let caption: Font = .system(size: 11)
    /// 10.5pt — tile labels (narrow-width constraint).
    static let tileLabel: Font = .system(size: 10.5)
    /// 11pt, tracking 1, uppercase — step indicator.
    static let stepLabel: Font = .system(size: 11, weight: .regular)
}

extension Text {
    /// Apply the uppercase, letter-spaced step-label treatment.
    /// Example: `Text("Step 1 of 2").stepLabelStyle()`.
    func stepLabelStyle() -> some View {
        self.font(AppTypography.stepLabel)
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(Color.inkTertiary)
    }
}
