import CoreGraphics

/// Virtual keycode for the "Q" key on a US layout — same physical key across
/// all Roman layouts, so matching on the keycode (not the translated character)
/// keeps behavior stable under Dvorak/Colemak/etc.
let kVK_ANSI_Q: CGKeyCode = 0x0C

/// Pure decision function invoked from the `CGEventTap` callback.
/// - Returns: `true` when the event is a ⌘Q keyDown **and** the current
///   frontmost app's bundle ID is in the whitelist, meaning the tap should
///   swallow the event.
func shouldBlockCmdQ(
    keyCode: CGKeyCode,
    flags: CGEventFlags,
    frontmostBundleID: String?,
    whitelist: [String],
    isEnabled: Bool = true
) -> Bool {
    guard isEnabled else { return false }
    guard keyCode == kVK_ANSI_Q else { return false }

    // ⌘ held, and no other modifiers beyond the ones macOS always sets
    // (numeric keypad, function key bits). We match on presence of .maskCommand.
    guard flags.contains(.maskCommand) else { return false }

    // Reject option/control/shift-modified ⌘Q — those are different chords the
    // user may have bound to other actions; only plain ⌘Q is the quit gesture.
    let disallowed: CGEventFlags = [.maskShift, .maskAlternate, .maskControl]
    if !flags.intersection(disallowed).isEmpty { return false }

    guard let bundleID = frontmostBundleID, !bundleID.isEmpty else { return false }
    return whitelist.contains(bundleID)
}

enum CmdQKeyDownDecision: Equatable {
    case pass
    case startBlockedSequence
    case suppressRepeat
}

struct CmdQInterceptionState {
    private var isSuppressingCmdQSequence = false

    mutating func keyDownDecision(
        keyCode: CGKeyCode,
        flags: CGEventFlags,
        frontmostBundleID: String?,
        whitelist: [String],
        isEnabled: Bool = true
    ) -> CmdQKeyDownDecision {
        guard keyCode == kVK_ANSI_Q, flags.contains(.maskCommand) else {
            return .pass
        }

        if isSuppressingCmdQSequence {
            return .suppressRepeat
        }

        if shouldBlockCmdQ(
            keyCode: keyCode,
            flags: flags,
            frontmostBundleID: frontmostBundleID,
            whitelist: whitelist,
            isEnabled: isEnabled
        ) {
            isSuppressingCmdQSequence = true
            return .startBlockedSequence
        }

        return .pass
    }

    mutating func keyUpShouldNotify(keyCode: CGKeyCode) -> Bool {
        guard keyCode == kVK_ANSI_Q else { return false }
        isSuppressingCmdQSequence = false
        return true
    }

    mutating func flagsChangedShouldNotify(flags: CGEventFlags) -> Bool {
        guard !flags.contains(.maskCommand) else { return false }
        isSuppressingCmdQSequence = false
        return true
    }
}
