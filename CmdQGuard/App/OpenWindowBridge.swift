import AppKit

/// Helpers for presenting SwiftUI scenes from non-View contexts
/// (`AppDelegate`, menu commands, URL handlers).
enum OpenWindowBridge {
    /// Shows the Control Panel. Prefer the AppDelegate-owned window because
    /// it is available from Dock/LaunchServices reopen callbacks.
    @MainActor
    static func openSettings() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.showControlPanel()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }
}
