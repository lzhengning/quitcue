import Foundation

@MainActor
struct QuitCueEnablementController {
    let settings: ConfirmSettings
    let launchAtLogin: LaunchAtLoginManager
    let startProtection: @MainActor () -> Void
    let stopProtection: @MainActor () -> Void
    let cancelActiveConfirmation: @MainActor () -> Void
    let terminateApplication: @MainActor () -> Void

    func setEnabled(_ isEnabled: Bool) {
        settings.isEnabled = isEnabled

        guard !isEnabled else {
            startProtection()
            return
        }

        cancelActiveConfirmation()
        stopProtection()
        if launchAtLogin.isEnabled {
            launchAtLogin.setEnabled(false)
        }
        terminateApplication()
    }
}
