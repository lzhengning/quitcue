import SwiftUI

/// Step 3 — final confirmation. Matches the prototype's green
/// check-in-circle + soft tip card tone.
struct OnboardingDoneView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            successBadge

            Text("You're protected.")
                .font(AppTypography.title2)
                .accessibilityIdentifier("doneTitle")

            Text("CmdQGuard is now running in the background. You'll see a floating card only when you try to quit a protected app.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: 300)

            tipCard

            closeButton
                .padding(.top, 4)
                .accessibilityIdentifier("doneCloseButton")
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 44)
        .frame(minWidth: 440, minHeight: 440)
    }

    private var successBadge: some View {
        ZStack {
            Circle()
                .fill(Color(hue: 155/360, saturation: 0.35, brightness: 0.92))
                .frame(width: 56, height: 56)
            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(hue: 155/360, saturation: 0.55, brightness: 0.50))
        }
    }

    private var tipCard: some View {
        (Text("Tip. ").fontWeight(.semibold)
         + Text("Reopen the control panel by clicking the ")
         + Text("CmdQGuard").font(.system(.body, design: .monospaced))
         + Text(" icon in the Dock."))
            .font(AppTypography.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .lineSpacing(2)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.systemRowBackground)
            )
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
