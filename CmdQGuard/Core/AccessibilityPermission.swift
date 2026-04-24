import AppKit
@preconcurrency import ApplicationServices
import Observation

/// Observable façade over macOS's per-process Accessibility (AX) trust flag.
/// `CGEventTap` requires this to be granted; the app stays inert until it is.
@Observable
final class AccessibilityPermission {
    private(set) var isGranted: Bool

    init() {
        self.isGranted = AXIsProcessTrusted()
    }

    /// Re-query the current trust state. Call from `NSApplication`'s
    /// `didBecomeActive` notification so returning from System Settings
    /// flips the UI without a restart.
    func refresh() {
        isGranted = AXIsProcessTrusted()
    }

    /// Prompt the user — this triggers macOS's "allow CmdQGuard to control
    /// this computer?" system sheet the first time it's called. Subsequent
    /// calls after denial silently return; the user must flip the toggle
    /// in System Settings → Privacy & Security → Accessibility.
    func requestIfNeeded() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options: CFDictionary = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refresh()
    }
}
