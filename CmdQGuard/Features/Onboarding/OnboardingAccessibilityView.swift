import SwiftUI

/// Step 1 of 2 — ask for Accessibility permission. The pill toggle routes
/// through `AccessibilityPermission.requestIfNeeded` so tapping triggers
/// the system TCC prompt. Continue stays disabled until trust lands.
struct OnboardingAccessibilityView: View {
    let accessibility: AccessibilityPermission
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Step 1 of 2")
                .stepLabelStyle()
                .padding(.bottom, 6)

            Text("Grant Accessibility access")
                .font(AppTypography.title2)
                .tracking(-0.3)
                .accessibilityIdentifier("accessibilityStepTitle")
                .padding(.bottom, 6)

            Text("Required to intercept ⌘Q before apps see it. Tap the toggle to allow.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .padding(.bottom, 18)

            SystemSettingsRow {
                HStack(spacing: 12) {
                    BrandMark(size: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CmdQGuard")
                            .font(AppTypography.bodyMedium)
                        Text(accessibility.isGranted ? "Allowed" : "Allow to control your Mac")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    PillToggle(
                        isOn: Binding(
                            get: { accessibility.isGranted },
                            set: { if !$0 { /* TCC can't be revoked from here */ } }
                        ),
                        onTurnOn: { accessibility.requestIfNeeded() }
                    )
                    .accessibilityIdentifier("accessibilityToggle")
                }
            }

            Spacer(minLength: 0)

            Divider()
                .padding(.top, 20)

            HStack {
                Text(accessibility.isGranted ? "✓ Permission granted" : "0 of 1 enabled")
                    .font(AppTypography.footnote)
                    .foregroundStyle(accessibility.isGranted ? Color.guardProtected : .secondary)
                    .accessibilityIdentifier("accessibilityFooterStatus")
                Spacer()
                continueButton
                    .disabled(!accessibility.isGranted)
                    .accessibilityIdentifier("accessibilityContinueButton")
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(minWidth: 460, minHeight: 460)
    }

    @ViewBuilder
    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue →")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 30)
                .background(Color.guardAccent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingAccessibilityView(accessibility: AccessibilityPermission(), onContinue: {})
        .frame(width: 480, height: 560)
}
