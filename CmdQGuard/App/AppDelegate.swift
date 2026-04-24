import AppKit
import SwiftUI

/// Bridges NSApplication lifecycle events into the SwiftUI scene graph,
/// owns the app-level singletons (`WhitelistStore`, `AccessibilityPermission`,
/// `CmdQInterceptor`), and starts the event tap once AX trust is granted.
///
/// CmdQGuard runs as an `LSUIElement` (no Dock, no persistent menubar). The
/// onboarding window opens automatically on launch via SwiftUI's default
/// behavior; the view self-dismisses if onboarding has already been
/// completed, leaving the app running silently with only the overlay panel
/// available.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let whitelist = WhitelistStore()
    let accessibility = AccessibilityPermission()
    private(set) lazy var interceptor = CmdQInterceptor(store: whitelist)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // UI-test convenience: `-CmdQGuard.showSettingsOnLaunch YES` is
        // honored by OnboardingView via @Environment(\.openSettings) so the
        // Settings scene is opened from within SwiftUI's own scene graph.
        startInterceptorIfAuthorized()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        accessibility.refresh()
        whitelist.reload()
        startInterceptorIfAuthorized()
    }

    private func startInterceptorIfAuthorized() {
        guard accessibility.isGranted else { return }
        interceptor.start()
    }

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
