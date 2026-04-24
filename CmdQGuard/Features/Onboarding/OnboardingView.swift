import SwiftUI

/// First-run setup flow. M1 scaffold — the real three-step stepper
/// (Welcome → Accessibility → App Picker) is implemented in M4.
struct OnboardingView: View {
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.tint)

            Text("CmdQGuard")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Silent ⌘Q guardian for macOS")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Onboarding flow arrives in M4.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .padding(.top, 24)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if OnboardingState.isComplete {
                dismissWindow(id: WindowID.onboarding.rawValue)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .frame(width: 480, height: 560)
}
