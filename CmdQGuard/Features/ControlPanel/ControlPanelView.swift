import SwiftUI

/// The user-facing settings surface. Reopened via Spotlight or Cmd+Comma.
/// M2 adds Accessibility status + whitelist readout; full app picker and
/// hold/press-twice picker land in M5.
struct ControlPanelView: View {
    @Environment(WhitelistStore.self) private var whitelist
    @Environment(AccessibilityPermission.self) private var accessibility

    var body: some View {
        Form {
            Section("Accessibility") {
                HStack {
                    Image(systemName: accessibility.isGranted
                          ? "checkmark.circle.fill"
                          : "exclamationmark.triangle.fill")
                        .foregroundStyle(accessibility.isGranted ? .green : .orange)
                    Text(accessibility.isGranted
                         ? "Accessibility: Granted"
                         : "Accessibility: Not granted")
                        .accessibilityIdentifier("accessibilityStatus")
                    Spacer()
                    if !accessibility.isGranted {
                        grantButton
                    }
                }
            }

            Section("Protected Apps") {
                if whitelist.bundleIDs.isEmpty {
                    Text("No protected apps yet — app picker arrives in M5.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(whitelist.bundleIDs, id: \.self) { bundleID in
                        Text(bundleID)
                            .font(.system(.body, design: .monospaced))
                            .accessibilityIdentifier("whitelistRow_\(bundleID)")
                    }
                }
            }

            Section("Confirm Method") {
                Text("Hold vs. press-twice picker arrives in M5.")
                    .foregroundStyle(.secondary)
            }

            Section("General") {
                Text("Launch at login, ghost-mode options arrive in M5.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .scenePadding()
    }

    @ViewBuilder
    private var grantButton: some View {
        let button = Button("Grant…") { accessibility.requestIfNeeded() }
        if #available(macOS 26, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ControlPanelView()
        .environment(WhitelistStore())
        .environment(AccessibilityPermission())
        .frame(width: 520, height: 560)
}
