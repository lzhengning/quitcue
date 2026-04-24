import AppKit
import SwiftUI

/// Bridges NSApplication lifecycle events into the SwiftUI scene graph,
/// owns the app-level singletons (`WhitelistStore`, `AccessibilityPermission`,
/// `CmdQInterceptor`, `OverlayController`), and wires the interceptor ↔
/// overlay ↔ termination pipeline.
///
/// CmdQGuard runs as an `LSUIElement` (no Dock, no persistent menubar). The
/// onboarding window opens automatically on launch via SwiftUI's default
/// behavior; the view self-dismisses if onboarding has already been
/// completed, leaving the app running silently with only the overlay panel
/// available.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let whitelist = WhitelistStore()
    let accessibility = AccessibilityPermission()
    let settings = ConfirmSettings()
    let launchAtLogin = LaunchAtLoginManager()
    let overlay = OverlayController()
    private(set) lazy var interceptor = CmdQInterceptor(store: whitelist)

    func applicationDidFinishLaunching(_ notification: Notification) {
        wireOverlayPipeline()
        startInterceptorIfAuthorized()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        #if DEBUG
        debugForceOverlayIfRequested()
        #endif
    }

    @objc private func appDidBecomeActive() {
        accessibility.refresh()
        whitelist.reload()
        startInterceptorIfAuthorized()
    }

    private func wireOverlayPipeline() {
        overlay.settingsSource = settings
        interceptor.onCmdQDown = { [weak self] bundleID, appName in
            self?.overlay.handleCmdQDown(bundleID: bundleID, appName: appName)
        }
        interceptor.onCmdQUp = { [weak self] in
            self?.overlay.handleCmdQUp()
        }
        overlay.onConfirm = { bundleID in
            guard let bundleID else { return }
            for running in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID) {
                running.terminate()
            }
        }
    }

    private func startInterceptorIfAuthorized() {
        guard accessibility.isGranted else { return }
        interceptor.start()
    }

    #if DEBUG
    /// Honors `-CmdQGuard.showOverlayOnLaunch hold|double`. Test-only path;
    /// production builds skip this entirely because of the `#if DEBUG`.
    private func debugForceOverlayIfRequested() {
        let defaults = UserDefaults.standard
        guard let raw = defaults.string(forKey: "CmdQGuard.showOverlayOnLaunch"),
              let mode = ConfirmMode(rawValue: raw) else { return }
        DispatchQueue.main.async {
            self.overlay.debugForceShow(mode: mode, appName: "Debug Target")
        }
    }
    #endif

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
