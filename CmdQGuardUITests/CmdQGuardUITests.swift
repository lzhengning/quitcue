import XCTest

/// M1 smoke coverage: ghost-mode activation policy + first-run onboarding window.
final class CmdQGuardUITests: XCTestCase {
    private let bundleID = "com.cmdqguard.CmdQGuard"

    override func setUp() {
        continueAfterFailure = false
    }

    func testGhostModeActivationPolicy() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-com.cmdqguard.onboarding.completed", "YES"]
        app.launch()
        addTeardownBlock { app.terminate() }

        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        let target = try XCTUnwrap(running.first, "CmdQGuard process not found")
        XCTAssertEqual(
            target.activationPolicy,
            .accessory,
            "Ghost mode violated — activation policy must stay .accessory (LSUIElement)"
        )
    }

    func testOnboardingWindowAppearsOnFirstRun() {
        let app = XCUIApplication()
        app.launchArguments = ["-com.cmdqguard.onboarding.completed", "NO"]
        app.launch()
        addTeardownBlock { app.terminate() }

        let window = app.windows["Welcome to CmdQGuard"]
        XCTAssertTrue(
            window.waitForExistence(timeout: 5),
            "Onboarding window did not appear when onboarding was not yet complete"
        )
    }
}
