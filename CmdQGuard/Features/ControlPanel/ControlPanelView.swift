import SwiftUI

/// The user-facing settings surface. Reopened via Spotlight or Cmd+Comma.
/// M1 scaffold — protected-apps list, hold-duration slider, launch-at-login,
/// and ghost-mode toggles land in M5.
struct ControlPanelView: View {
    var body: some View {
        Form {
            Section("Protected Apps") {
                Text("Protected-app management arrives in M5.")
                    .foregroundStyle(.secondary)
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
}

#Preview {
    ControlPanelView()
        .frame(width: 520, height: 560)
}
