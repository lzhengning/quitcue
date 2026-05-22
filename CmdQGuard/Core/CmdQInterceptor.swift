import AppKit
import CoreGraphics

/// Installs a session-level `CGEventTap` and routes key events into the
/// overlay/confirm pipeline. Three event types are observed:
///
/// - `.keyDown` → `shouldBlockCmdQ` gate; on match, forwards a
///   `onCmdQDown(bundleID, appName)` to the main actor and swallows.
/// - `.keyUp`   → forwards `onCmdQUp()` when the released key is Q (used by
///   hold-mode to cancel pre-confirm).
/// - `.flagsChanged` → forwards `onCmdQUp()` when Command is released
///   (cancels hold mode without needing the Q keyUp).
///
/// AX trust is required to create the tap (see
/// `AccessibilityPermission`). The interceptor is a no-op until `start()`
/// succeeds.
final class CmdQInterceptor {
    private let store: WhitelistStore
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Dispatched on the main actor.
    var onCmdQDown: (@MainActor @Sendable (_ bundleID: String?, _ appName: String?) -> Void)?
    var onCmdQUp: (@MainActor @Sendable () -> Void)?

    init(store: WhitelistStore) {
        self.store = store
    }

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: Self.callback,
            userInfo: refcon
        )

        guard let newTap else {
            Self.debugLog("tapCreate failed")
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)

        self.tap = newTap
        self.runLoopSource = source
        Self.debugLog("tapCreate succeeded")
        return true
    }

    func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
    }

    private static let callback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else { return Unmanaged.passUnretained(event) }
        let me = Unmanaged<CmdQInterceptor>.fromOpaque(refcon).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = me.tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .keyDown:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            let flags = event.flags
            let front = NSWorkspace.shared.frontmostApplication
            let bundleID = front?.bundleIdentifier
            let appName = front?.localizedName

            if shouldBlockCmdQ(
                keyCode: keyCode,
                flags: flags,
                frontmostBundleID: bundleID,
                whitelist: me.store.bundleIDs
            ) {
                debugLog("blocking keyDown keyCode=\(keyCode) frontmost=\(bundleID ?? "nil") whitelist=\(me.store.bundleIDs)")
                if let handler = me.onCmdQDown {
                    Task { @MainActor in handler(bundleID, appName) }
                }
                return nil
            }
            debugLog("passing keyDown keyCode=\(keyCode) flags=\(flags.rawValue) frontmost=\(bundleID ?? "nil") whitelist=\(me.store.bundleIDs)")

        case .keyUp:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == kVK_ANSI_Q, let handler = me.onCmdQUp {
                Task { @MainActor in handler() }
            }

        case .flagsChanged:
            if !event.flags.contains(.maskCommand), let handler = me.onCmdQUp {
                Task { @MainActor in handler() }
            }

        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }
}

private extension CmdQInterceptor {
    static func debugLog(_ message: String) {
        EventTapDiagnostics.log(message)
    }
}

enum EventTapDiagnostics {
    static func log(_ message: String) {
        #if DEBUG
        guard UserDefaults.standard.bool(forKey: "CmdQGuard.eventTapDiagnostics") else {
            return
        }

        NSLog("CMDQ_TAP_DIAG %@", message)
        let line = "CMDQ_TAP_DIAG \(message)\n"
        let url = URL(fileURLWithPath: "/tmp/cmdqguard-eventtap-diag.log")
        guard let data = line.data(using: .utf8) else { return }

        if !FileManager.default.fileExists(atPath: url.path) {
            _ = FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        if let handle = try? FileHandle(forWritingTo: url) {
            defer {
                try? handle.close()
            }
            handle.seekToEndOfFile()
            handle.write(data)
        }
        #endif
    }
}
