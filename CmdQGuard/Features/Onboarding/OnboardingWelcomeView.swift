import SwiftUI

/// Step 0 — full-bleed welcome. The sole action is "Get started" which
/// advances to the Accessibility step.
struct OnboardingWelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.tint)

            Text("Welcome to CmdQGuard")
                .font(.system(size: 26, weight: .semibold))
                .accessibilityIdentifier("welcomeTitle")

            Text("Stops accidental ⌘Q from closing the apps you care about. Silent. No menubar. No Dock.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .padding(.top, 4)

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
