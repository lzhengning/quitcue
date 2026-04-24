import XCTest
import CoreGraphics
@testable import CmdQGuard

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
}
