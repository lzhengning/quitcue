import XCTest
@testable import CmdQGuard

@MainActor
final class OverlayControllerTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "CmdQGuardTests.OverlayController"

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
    }

    /// Regression: repeated keyDown events (macOS keyboard auto-repeat
    /// during a hold) must NOT wipe the state machine back to idle, or
    /// the hold timer never lands on `.confirmed`.
    func testHoldKeepsAccumulatingAcrossRepeatedKeyDown() {
        let settings = ConfirmSettings(defaults: defaults)
        settings.mode = .hold
        let controller = OverlayController()
        controller.settingsSource = settings

        controller.handleCmdQDown(bundleID: "com.example.a", appName: "A")
        if case .holding(let start1) = controller.debugMachinePhase {
            controller.handleCmdQDown(bundleID: "com.example.a", appName: "A")
            if case .holding(let start2) = controller.debugMachinePhase {
                XCTAssertEqual(start1, start2, "auto-repeat keyDown reset the hold start time")
            } else {
                XCTFail("second keyDown should stay in .holding")
            }
        } else {
            XCTFail("first keyDown should transition to .holding")
        }
    }

    /// Regression: the hold-duration timer must not be invalidated and
    /// re-scheduled every time macOS delivers an auto-repeat keyDown, or
    /// the timer never fires and the user can never confirm.
    func testHoldConfirmsDespiteAutoRepeatKeyDowns() async throws {
        let settings = ConfirmSettings(defaults: defaults)
        settings.mode = .hold
        settings.holdDuration = 0.2
        let controller = OverlayController()
        controller.settingsSource = settings

        let expectation = XCTestExpectation(description: "onConfirm fires")
        nonisolated(unsafe) var confirmedBundleID: String?
        controller.onConfirm = { bundleID in
            confirmedBundleID = bundleID
            expectation.fulfill()
        }

        // Simulate initial keyDown + auto-repeat deliveries during hold.
        controller.handleCmdQDown(bundleID: "com.example.hold", appName: "Hold")
        try await Task.sleep(for: .milliseconds(40))
        controller.handleCmdQDown(bundleID: "com.example.hold", appName: "Hold")
        try await Task.sleep(for: .milliseconds(40))
        controller.handleCmdQDown(bundleID: "com.example.hold", appName: "Hold")

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(confirmedBundleID, "com.example.hold")
    }

    /// Regression: in double-press mode, the second ⌘Q must confirm.
    /// Previously `handleCmdQDown` rebuilt the machine on every call,
    /// always leaving the phase at `.awaitingSecondPress`.
    func testDoublePressSecondKeyDownConfirms() {
        let settings = ConfirmSettings(defaults: defaults)
        settings.mode = .doublePress
        let controller = OverlayController()
        controller.settingsSource = settings

        var confirmedBundleID: String??
        controller.onConfirm = { id in confirmedBundleID = .some(id) }

        controller.handleCmdQDown(bundleID: "com.example.b", appName: "B")
        XCTAssertEqual(controller.isVisible, true)
        if case .awaitingSecondPress = controller.debugMachinePhase {
            // expected
        } else {
            XCTFail("first keyDown should transition to .awaitingSecondPress")
        }

        controller.handleCmdQDown(bundleID: "com.example.b", appName: "B")
        XCTAssertEqual(confirmedBundleID, .some(.some("com.example.b")),
                       "second keyDown must fire onConfirm with the target bundle ID")
    }
}
