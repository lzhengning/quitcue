import AppKit
import SwiftUI

/// Bridges NSApplication lifecycle events into the SwiftUI scene graph,
/// owns the app-level singletons (`WhitelistStore`, `AccessibilityPermission`,
/// `CmdQInterceptor`, `OverlayController`), and wires the interceptor ↔
/// overlay ↔ termination pipeline.
///
/// The app runs with a regular activation policy (Dock icon visible). The
/// onboarding window opens automatically on first run; once onboarding is
/// complete the window self-dismisses and the app keeps running in the
/// background so the event tap stays active. The user can reopen the
/// Control Panel from the Dock icon, Spotlight, or Launchpad.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let whitelist = WhitelistStore()
    let accessibility = AccessibilityPermission()
    let settings = ConfirmSettings()
    let launchAtLogin = LaunchAtLoginManager()
    let overlay = OverlayController()
    private(set) lazy var interceptor = CmdQInterceptor(store: whitelist)
    private var controlPanelWindow: NSWindow?

    override init() {
        // Suppress macOS's "unexpectedly quit while reopening windows"
        // dialog. We don't model documents, the welcome window is
        // re-derived from `OnboardingState`, and the Settings scene is
        // always reachable from the Dock — restoration adds nothing and
        // blocks UI tests behind a modal sheet after any forced kill.
        UserDefaults.standard.register(defaults: [
            "NSQuitAlwaysKeepsWindows": false,
            "ApplePersistenceIgnoreState": true
        ])
        super.init()
    }

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
        guard accessibility.isGranted else {
            EventTapDiagnostics.log("accessibility not granted")
            return
        }
        EventTapDiagnostics.log("accessibility granted; starting interceptor")
        let didStart = interceptor.start()
        EventTapDiagnostics.log("interceptor start returned \(didStart)")
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

    func applicationWillTerminate(_ notification: Notification) {
        // The CGEventTap's run-loop source can otherwise keep the process
        // alive past a terminate request; explicitly tear it down so
        // XCUIApplication.launch()'s implicit "terminate existing instance
        // before relaunching" doesn't hang.
        interceptor.stop()
    }

    func showControlPanel() {
        accessibility.refresh()
        whitelist.reload()
        startInterceptorIfAuthorized()

        if let controlPanelWindow {
            NSApp.activate(ignoringOtherApps: true)
            controlPanelWindow.makeKeyAndOrderFront(nil)
            controlPanelWindow.orderFrontRegardless()
            return
        }

        let content = ControlPanelView()
            .environment(whitelist)
            .environment(accessibility)
            .environment(settings)
            .environment(launchAtLogin)
            .frame(width: 520)
            .frame(minHeight: 620)
            .preferredColorScheme(.light)

        let window = NSWindow(contentViewController: NSHostingController(rootView: content))
        window.title = "CmdQGuard"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 520, height: 620))
        window.isReleasedWhenClosed = false
        window.center()

        controlPanelWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running after the window closes so the CGEventTap can keep
        // intercepting ⌘Q in the background. The Dock icon stays visible so
        // the user can Cmd-click → Quit when they really want to stop us.
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showControlPanel()
        // Suppress AppKit's default reopen path. SwiftUI may still have a
        // closed Welcome scene in its window graph after onboarding, so
        // `hasVisibleWindows` is not a reliable proxy for whether the user
        // can actually see the Control Panel.
        return false
    }
}
