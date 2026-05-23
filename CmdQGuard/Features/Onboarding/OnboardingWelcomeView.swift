import SwiftUI

/// Step 0 — full-bleed welcome. The sole action is "Get started" which
/// advances to the Accessibility step.
struct OnboardingWelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            BrandMark(size: 72)
                .padding(.bottom, 4)

            Text("Welcome to CmdQGuard")
                .font(AppTypography.title1)
                .tracking(-0.5)
                .accessibilityIdentifier("welcomeTitle")

            (Text("Stops accidental ")
             + Text("⌘").font(.system(.caption, design: .monospaced)).fontWeight(.semibold)
             + Text(" ")
             + Text("Q").font(.system(.caption, design: .monospaced)).fontWeight(.semibold)
             + Text(" from closing the apps you care about. Silent. No menubar. No Dock."))
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: 320)

            getStartedButton
                .padding(.top, 20)
                .accessibilityIdentifier("getStartedButton")
        }
        .padding(.horizontal, 48)
        .padding(.top, 48)
        .padding(.bottom, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var getStartedButton: some View {
        Button(action: onNext) {
            Text("Get started")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: 34)
                .background(Color.guardAccent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingWelcomeView(onNext: {})
        .frame(width: 480, height: 560)
}
