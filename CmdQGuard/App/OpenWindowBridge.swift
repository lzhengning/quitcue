import AppKit

/// Helpers for presenting SwiftUI scenes from non-View contexts
/// (`AppDelegate`, menu commands, URL handlers).
enum OpenWindowBridge {
    /// Shows the Settings scene. The Settings scene is created once by
    /// SwiftUI and reused on every invocation.
    static func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
