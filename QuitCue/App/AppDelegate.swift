import AppKit
import SwiftUI

/// Bridges NSApplication lifecycle events into the SwiftUI scene graph,
/// owns the app-level singletons (`WhitelistStore`, `AccessibilityPermission`,
/// `CmdQInterceptor`, `OverlayController`), and wires the interceptor ↔
/// overlay ↔ termination pipeline.
///
/// The app uses a regular activation policy only while a user-facing window is
/// open. Closing the Control Panel or pressing ⌘Q hides the Dock icon while the
/// process and event tap keep running in the background.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let whitelist = WhitelistStore()
    let accessibility = AccessibilityPermission()
    let settings = ConfirmSettings()
    let launchAtLogin = LaunchAtLoginManager()
    let overlay = OverlayController()
    private(set) lazy var interceptor = CmdQInterceptor(store: whitelist)
    private var controlPanelWindow: NSWindow?
    private lazy var dockPresence = DockPresenceController(application: NSApp)

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
        guard !Self.isPreviewHost else { return }

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
        showControlPanelIfRequested()
        hideDockIfLaunchingWithoutVisibleWindow()
    }

    @objc private func appDidBecomeActive() {
        guard !Self.isPreviewHost else { return }

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

    private func showControlPanelIfRequested() {
        guard UserDefaults.standard.bool(forKey: "QuitCue.showSettingsOnLaunch") else { return }

        DispatchQueue.main.async {
            self.showControlPanel()
        }
    }

    #if DEBUG
    /// Honors `-QuitCue.showOverlayOnLaunch hold|double`. Test-only path;
    /// production builds skip this entirely because of the `#if DEBUG`.
    private func debugForceOverlayIfRequested() {
        let defaults = UserDefaults.standard
        guard let raw = defaults.string(forKey: "QuitCue.showOverlayOnLaunch"),
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

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard isCommandQKeyEvent(sender.currentEvent) else {
            return .terminateNow
        }

        hideControlPanel()
        return .terminateCancel
    }

    func showControlPanel() {
        guard !Self.isPreviewHost else { return }

        dockPresence.controlPanelDidOpen()
        accessibility.refresh()
        whitelist.reload()
        startInterceptorIfAuthorized()

        if let controlPanelWindow {
            NSApp.activate(ignoringOtherApps: true)
            controlPanelWindow.makeKeyAndOrderFront(nil)
            controlPanelWindow.orderFrontRegardless()
            return
        }

        let scannedApps = installedAppsForControlPanel()
        let content = ControlPanelView(installedApps: scannedApps)
            .environment(whitelist)
            .environment(accessibility)
            .environment(settings)
            .environment(launchAtLogin)

        let hostingController = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable]
        UnifiedWindowChrome.apply(to: window)
        let fittingSize = hostingController.sizeThatFits(
            in: NSSize(width: ControlPanelMetrics.width, height: .greatestFiniteMagnitude)
        )
        let contentSize = NSSize(
            width: ControlPanelMetrics.width,
            height: max(fittingSize.height, 620)
        )
        hostingController.view.setFrameSize(contentSize)
        window.setContentSize(contentSize)
        window.contentMinSize = contentSize
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()

        controlPanelWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func hideControlPanel() {
        guard !Self.isPreviewHost else { return }

        dockPresence.hideControlPanel(window: controlPanelWindow)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running after the window closes so the CGEventTap can keep
        // intercepting ⌘Q in the background.
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !Self.isPreviewHost else { return false }

        showControlPanel()
        // Suppress AppKit's default reopen path. SwiftUI may still have a
        // closed Welcome scene in its window graph after onboarding, so
        // `hasVisibleWindows` is not a reliable proxy for whether the user
        // can actually see the Control Panel.
        return false
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window === controlPanelWindow else { return }

        dockPresence.controlPanelDidClose()
    }

    private func hideDockIfLaunchingWithoutVisibleWindow() {
        guard OnboardingState.isComplete,
              !UserDefaults.standard.bool(forKey: "QuitCue.showSettingsOnLaunch") else { return }

        DispatchQueue.main.async {
            guard self.controlPanelWindow?.isVisible != true else { return }

            self.dockPresence.controlPanelDidClose()
        }
    }

    private func isCommandQKeyEvent(_ event: NSEvent?) -> Bool {
        guard let event,
              event.type == .keyDown,
              event.charactersIgnoringModifiers?.lowercased() == "q" else { return false }

        return event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)
    }

    private func installedAppsForControlPanel() -> [InstalledApp] {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "QuitCue.useUITestAppInventory") {
            return [
                InstalledApp(
                    bundleID: "com.apple.Safari",
                    name: "Safari",
                    url: URL(fileURLWithPath: "/Applications/Safari.app")
                ),
                InstalledApp(
                    bundleID: "com.apple.TextEdit",
                    name: "TextEdit",
                    url: URL(fileURLWithPath: "/System/Applications/TextEdit.app")
                )
            ]
        }
        #endif

        return AppInventory.scan()
    }

    private static var isPreviewHost: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
            || environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

@MainActor
protocol DockPresenceApplication: AnyObject {
    @discardableResult
    func setActivationPolicy(_ activationPolicy: NSApplication.ActivationPolicy) -> Bool
    func terminate(_ sender: Any?)
}

extension NSApplication: DockPresenceApplication {}

@MainActor
protocol DockPresenceWindow: AnyObject {
    func close()
}

extension NSWindow: DockPresenceWindow {}

@MainActor
final class DockPresenceController {
    private let application: any DockPresenceApplication

    init(application: any DockPresenceApplication) {
        self.application = application
    }

    func controlPanelDidOpen() {
        application.setActivationPolicy(.regular)
    }

    func controlPanelDidClose() {
        application.setActivationPolicy(.accessory)
    }

    func hideControlPanel(window: (any DockPresenceWindow)?) {
        window?.close()
        controlPanelDidClose()
    }
}
