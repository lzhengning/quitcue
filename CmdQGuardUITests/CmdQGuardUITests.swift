import XCTest

/// M1 smoke coverage: activation policy + first-run onboarding window.
final class CmdQGuardUITests: CmdQGuardUITestCase {
    private let bundleID = "com.cmdqguard.CmdQGuard"

    func testAppLaunchesWithRegularActivationPolicy() throws {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.cmdqguard.onboarding.completed", "YES"
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        let target = try XCTUnwrap(running.first, "CmdQGuard process not found")
        XCTAssertEqual(
            target.activationPolicy,
            .regular,
            "App must launch with a regular activation policy (Dock icon visible)"
        )
    }

    func testOnboardingWindowAppearsOnFirstRun() {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.cmdqguard.onboarding.completed", "NO"
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        let window = app.windows["Welcome to CmdQGuard"]
        XCTAssertTrue(
            window.waitForExistence(timeout: 5),
            "Onboarding window did not appear when onboarding was not yet complete"
        )
    }
}
