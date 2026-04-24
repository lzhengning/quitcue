import SwiftUI

/// Step 3 — final confirmation. The onboarding window auto-dismisses
/// after a short pause so the app fades into its ghost-mode state.
struct OnboardingDoneView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.green)
            }

            Text("You're protected.")
                .font(.system(size: 20, weight: .semibold))
                .accessibilityIdentifier("doneTitle")

            Text("CmdQGuard is now running silently. No menubar, no Dock — it's only visible when you try to quit a protected app.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            VStack(alignment: .leading, spacing: 6) {
                (Text("Tip. ").fontWeight(.semibold)
                 + Text("Reopen settings by launching ")
                 + Text("CmdQGuard").font(.system(.body, design: .monospaced))
                 + Text(" from Spotlight or Launchpad."))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            closeButton
                .padding(.top, 4)
                .accessibilityIdentifier("doneCloseButton")
        }
        .padding(44)
        .frame(minWidth: 440, minHeight: 440)
    }

    @ViewBuilder
    private var closeButton: some View {
        let button = Button("Close") { onDismiss() }
        if #available(macOS 26, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    OnboardingDoneView(onDismiss: {})
        .frame(width: 480, height: 560)
}
