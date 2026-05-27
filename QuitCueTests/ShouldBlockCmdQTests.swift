import XCTest
import CoreGraphics
@testable import QuitCue

final class ShouldBlockCmdQTests: XCTestCase {
    private let whitelist = ["com.apple.Safari"]

    func testBlocksPlainCmdQOnWhitelistedApp() {
        XCTAssertTrue(shouldBlockCmdQ(
            keyCode: kVK_ANSI_Q,
            flags: .maskCommand,
            frontmostBundleID: "com.apple.Safari",
            whitelist: whitelist
        ))
    }

    func testIgnoresCmdQOnNonWhitelistedApp() {
        XCTAssertFalse(shouldBlockCmdQ(
            keyCode: kVK_ANSI_Q,
            flags: .maskCommand,
            frontmostBundleID: "com.apple.TextEdit",
            whitelist: whitelist
        ))
    }

    func testIgnoresOtherKeys() {
        XCTAssertFalse(shouldBlockCmdQ(
            keyCode: 0x00,
            flags: .maskCommand,
            frontmostBundleID: "com.apple.Safari",
            whitelist: whitelist
        ))
    }

    func testIgnoresQWithoutCommand() {
        XCTAssertFalse(shouldBlockCmdQ(
            keyCode: kVK_ANSI_Q,
            flags: [],
            frontmostBundleID: "com.apple.Safari",
            whitelist: whitelist
        ))
    }

    func testIgnoresShiftCmdQ() {
        XCTAssertFalse(shouldBlockCmdQ(
            keyCode: kVK_ANSI_Q,
            flags: [.maskCommand, .maskShift],
            frontmostBundleID: "com.apple.Safari",
            whitelist: whitelist
        ))
    }

    func testIgnoresOptCmdQ() {
        XCTAssertFalse(shouldBlockCmdQ(
            keyCode: kVK_ANSI_Q,
            flags: [.maskCommand, .maskAlternate],
            frontmostBundleID: "com.apple.Safari",
            whitelist: whitelist
        ))
    }

    func testIgnoresMissingBundleID() {
        XCTAssertFalse(shouldBlockCmdQ(
            keyCode: kVK_ANSI_Q,
            flags: .maskCommand,
            frontmostBundleID: nil,
            whitelist: whitelist
        ))
    }

    func testIgnoresEmptyWhitelist() {
        XCTAssertFalse(shouldBlockCmdQ(
            keyCode: kVK_ANSI_Q,
            flags: .maskCommand,
            frontmostBundleID: "com.apple.Safari",
            whitelist: []
        ))
    }

    func testSuppressesHeldCmdQRepeatsAfterInitialBlockEvenIfFrontmostChanges() {
        var state = CmdQInterceptionState()

        XCTAssertEqual(
            state.keyDownDecision(
                keyCode: kVK_ANSI_Q,
                flags: .maskCommand,
                frontmostBundleID: "com.apple.Safari",
                whitelist: whitelist
            ),
            .startBlockedSequence
        )

        XCTAssertEqual(
            state.keyDownDecision(
                keyCode: kVK_ANSI_Q,
                flags: .maskCommand,
                frontmostBundleID: "com.quitcue.QuitCue",
                whitelist: whitelist
            ),
            .suppressRepeat
        )
    }

    func testSuppressingHeldCmdQResetsOnQKeyUp() {
        var state = CmdQInterceptionState()

        _ = state.keyDownDecision(
            keyCode: kVK_ANSI_Q,
            flags: .maskCommand,
            frontmostBundleID: "com.apple.Safari",
            whitelist: whitelist
        )
        XCTAssertTrue(state.keyUpShouldNotify(keyCode: kVK_ANSI_Q))

        XCTAssertEqual(
            state.keyDownDecision(
                keyCode: kVK_ANSI_Q,
                flags: .maskCommand,
                frontmostBundleID: "com.quitcue.QuitCue",
                whitelist: whitelist
            ),
            .pass
        )
    }

    func testSuppressingHeldCmdQResetsOnCommandRelease() {
        var state = CmdQInterceptionState()

        _ = state.keyDownDecision(
            keyCode: kVK_ANSI_Q,
            flags: .maskCommand,
            frontmostBundleID: "com.apple.Safari",
            whitelist: whitelist
        )
        XCTAssertTrue(state.flagsChangedShouldNotify(flags: []))

        XCTAssertEqual(
            state.keyDownDecision(
                keyCode: kVK_ANSI_Q,
                flags: .maskCommand,
                frontmostBundleID: "com.quitcue.QuitCue",
                whitelist: whitelist
            ),
            .pass
        )
    }
}
