import AppKit
import CoreGraphics

/// Installs a session-level `CGEventTap` that intercepts ⌘Q keyDown events.
/// The tap consults `WhitelistStore` + the frontmost app's bundle ID via
/// `shouldBlockCmdQ` and either swallows or passes the event.
///
/// AX trust is required to create the tap (see
/// `AccessibilityPermission`). The interceptor is a no-op until `start()`
/// succeeds.
final class CmdQInterceptor {
    private let store: WhitelistStore
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(store: WhitelistStore) {
        self.store = store
    }

    /// Installs the tap on the main run loop. Returns `false` if the tap
    /// could not be created — typically because AX trust isn't granted.
    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: Self.callback,
            userInfo: refcon
        )

        guard let newTap else { return false }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)

        self.tap = newTap
        self.runLoopSource = source
        return true
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
    }

    private static let callback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else { return Unmanaged.passUnretained(event) }
        let me = Unmanaged<CmdQInterceptor>.fromOpaque(refcon).takeUnretainedValue()

        // Re-enable after the system disables us on timeout / user input delay.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = me.tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let frontBundle = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        if shouldBlockCmdQ(
            keyCode: keyCode,
            flags: flags,
            frontmostBundleID: frontBundle,
            whitelist: me.store.bundleIDs
        ) {
            return nil
        }
        return Unmanaged.passUnretained(event)
    }
}
