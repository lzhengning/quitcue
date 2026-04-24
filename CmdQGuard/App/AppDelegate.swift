import AppKit
import SwiftUI

/// Bridges NSApplication lifecycle events into the SwiftUI scene graph.
///
/// CmdQGuard runs as an `LSUIElement` (no Dock, no persistent menubar). The
/// onboarding window opens automatically on launch via SwiftUI's default
/// behavior; the view self-dismisses if onboarding has already been
/// completed, leaving the app running silently with only the overlay panel
/// available.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Ghost mode: keep running so the overlay can appear on demand, even
        // when no UI window is open.
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            OpenWindowBridge.openSettings()
        }
        return true
    }
}
