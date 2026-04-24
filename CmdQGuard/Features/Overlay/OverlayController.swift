import AppKit
import Observation
import SwiftUI

/// Observable front-door for the overlay subsystem. Owns the state machine,
/// the one-shot timer that drives its timeouts, and the `NSPanel` host.
///
/// The `CGEventTap` callback forwards ⌘Q events here via `onCmdQDown` /
/// `onCmdQUp`; we in turn call `onConfirm` when the user commits so the
/// AppDelegate can terminate the target app.
@MainActor
@Observable
final class OverlayController {
    // Persisted confirm-mode preference. Surfaced as a picker in M5.
    static let modeDefaultsKey = "com.cmdqguard.confirmMode"

    private(set) var isVisible: Bool = false
    private(set) var mode: ConfirmMode
    private(set) var appName: String = ""
    private var bundleID: String?
    private var machine: ConfirmStateMachine
    private var timeoutTimer: Timer?
    private var window: OverlayWindow?

    /// Invoked when the user confirms; receives the target bundle ID to quit.
    var onConfirm: ((String?) -> Void)?

    init(mode: ConfirmMode? = nil, config: ConfirmConfig = .default) {
        let resolved = mode ?? Self.loadMode()
        self.mode = resolved
        self.machine = ConfirmStateMachine(mode: resolved, config: config)
    }

    static func loadMode() -> ConfirmMode {
        if let raw = UserDefaults.standard.string(forKey: modeDefaultsKey),
           let mode = ConfirmMode(rawValue: raw) {
            return mode
        }
        return .hold
    }

    func setMode(_ newMode: ConfirmMode) {
        mode = newMode
        machine = ConfirmStateMachine(mode: newMode, config: machine.config)
        UserDefaults.standard.set(newMode.rawValue, forKey: Self.modeDefaultsKey)
    }

    // MARK: - Event intake

    func handleCmdQDown(bundleID: String?, appName: String?) {
        self.bundleID = bundleID
        self.appName = appName ?? bundleID ?? "this app"
        machine.cmdQDown(at: Date())
        applyPhase()
    }

    func handleCmdQUp() {
        machine.cmdQUp(at: Date())
        applyPhase()
    }

    // MARK: - Progress for the view

    /// Used by `AuroraHaloView`'s `TimelineView` to animate halo and
    /// (double-press mode) card fade-out.
    func currentProgress() -> Double {
        machine.progress(at: Date())
    }

    // MARK: - Internals

    private func applyPhase() {
        switch machine.phase {
        case .idle:
            hide()
        case .holding, .awaitingSecondPress:
            scheduleTimeout()
            show()
        case .confirmed:
            onConfirm?(bundleID)
            hide()
            machine.reset()
        }
    }

    private func scheduleTimeout() {
        timeoutTimer?.invalidate()
        let delay: TimeInterval
        switch machine.phase {
        case .holding:
            delay = machine.config.holdDuration
        case .awaitingSecondPress:
            delay = machine.config.doublePressWindow
        default:
            return
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: delay + 0.02, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.machine.tick(at: Date())
                self?.applyPhase()
            }
        }
    }

    private func show() {
        if window == nil {
            window = OverlayWindow(controller: self)
        }
        window?.present()
        isVisible = true
    }

    private func hide() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        window?.dismiss()
        isVisible = false
    }

    #if DEBUG
    /// Test hook — forces the overlay visible for a given mode without a
    /// real ⌘Q event. Wired up by the `-CmdQGuard.showOverlayOnLaunch`
    /// launch flag honored in `AppDelegate`.
    func debugForceShow(mode: ConfirmMode, appName: String) {
        setMode(mode)
        handleCmdQDown(bundleID: "com.example.debug", appName: appName)
    }
    #endif
}
