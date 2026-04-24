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

            Text("Stops accidental ⌘Q from closing the apps you care about. Silent. No menubar. No Dock.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: 320)

            getStartedButton
                .padding(.top, 20)
                .accessibilityIdentifier("getStartedButton")
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var getStartedButton: some View {
        let button = Button("Get started") { onNext() }
        if #available(macOS 26, *) {
            button.buttonStyle(.glassProminent).controlSize(.large)
        } else {
            button.buttonStyle(.borderedProminent).controlSize(.large)
        }
    }
}

#Preview {
    OnboardingWelcomeView(onNext: {})
        .frame(width: 480, height: 560)
}
