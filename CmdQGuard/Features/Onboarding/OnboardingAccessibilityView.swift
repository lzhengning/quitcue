import SwiftUI

/// Step 1 of 2 — ask for Accessibility permission. The toggle triggers
/// the system prompt via `AccessibilityPermission.requestIfNeeded`; the
/// Continue button stays disabled until trust is observed.
struct OnboardingAccessibilityView: View {
    let accessibility: AccessibilityPermission
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader

            Text("Grant Accessibility access")
                .font(.system(size: 20, weight: .semibold))
                .accessibilityIdentifier("accessibilityStepTitle")

            Text("Required to intercept ⌘Q before apps see it. Tap the toggle to allow.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            systemStyleRow

            Spacer(minLength: 0)

            footer
        }
        .padding(28)
        .frame(minWidth: 460, minHeight: 460)
    }

    private var stepHeader: some View {
        Text("STEP 1 OF 2")
            .font(.system(size: 11, weight: .regular))
            .tracking(1)
            .foregroundStyle(.secondary)
    }

    private var systemStyleRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 22))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text("CmdQGuard")
                    .font(.system(size: 13, weight: .medium))
                Text(accessibility.isGranted ? "Allowed" : "Allow to control your Mac")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Binding to a stored toggle wouldn't drive the TCC sheet; route
            // through the request API so macOS does the right thing.
            Toggle(
                "",
                isOn: Binding(
                    get: { accessibility.isGranted },
                    set: { requested in
                        if requested && !accessibility.isGranted {
                            accessibility.requestIfNeeded()
                        }
                    }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .accessibilityIdentifier("accessibilityToggle")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var footer: some View {
        HStack {
            Text(accessibility.isGranted ? "✓ Permission granted" : "0 of 1 enabled")
                .font(.system(size: 12))
                .foregroundStyle(accessibility.isGranted ? .green : .secondary)
                .accessibilityIdentifier("accessibilityFooterStatus")
            Spacer()
            continueButton
                .disabled(!accessibility.isGranted)
                .accessibilityIdentifier("accessibilityContinueButton")
        }
        .padding(.top, 14)
        .overlay(Divider(), alignment: .top)
    }

    @ViewBuilder
    private var continueButton: some View {
        let button = Button("Continue →") { onContinue() }
        if #available(macOS 26, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    OnboardingAccessibilityView(accessibility: AccessibilityPermission(), onContinue: {})
        .frame(width: 480, height: 560)
}
