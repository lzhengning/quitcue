import XCTest

/// M1 smoke coverage: activation policy + first-run onboarding window.
@MainActor
final class CmdQGuardUITests: CmdQGuardUITestCase {
    private let bundleID = "com.cmdqguard.CmdQGuard"

    func testBackgroundLaunchHidesDockIcon() throws {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.cmdqguard.onboarding.completed", "YES"
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        try waitForActivationPolicy(.accessory)
    }

    func testOnboardingWindowAppearsOnFirstRun() {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.cmdqguard.onboarding.completed", "NO"
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        let welcomeTitle = app.staticTexts["welcomeTitle"]
        XCTAssertTrue(
            welcomeTitle.waitForExistence(timeout: 5),
            "Onboarding window did not appear when onboarding was not yet complete"
        )
    }

    func testCommandQHidesControlPanelButKeepsAppRunning() throws {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.cmdqguard.onboarding.completed", "YES",
"-CmdQGuard.showSettingsOnLaunch", "YES"
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        let controlPanelTitle = app.staticTexts["Protected Apps"]
        XCTAssertTrue(
            controlPanelTitle.waitForExistence(timeout: 5),
            "Control Panel should open for this lifecycle check"
        )

        app.typeKey("q", modifierFlags: .command)

        XCTAssertFalse(
            controlPanelTitle.waitForExistence(timeout: 1),
            "⌘Q should close the Control Panel"
        )
        try waitForActivationPolicy(.accessory)
    }

    func testCloseButtonHidesControlPanelButKeepsAppRunning() throws {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.cmdqguard.onboarding.completed", "YES",
"-CmdQGuard.showSettingsOnLaunch", "YES"
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        let controlPanelTitle = app.staticTexts["Protected Apps"]
        XCTAssertTrue(
            controlPanelTitle.waitForExistence(timeout: 5),
            "Control Panel should open for this lifecycle check"
        )

        app.windows.firstMatch.buttons[XCUIIdentifierCloseWindow].click()

        XCTAssertFalse(
            controlPanelTitle.waitForExistence(timeout: 1),
            "Closing the window should hide the Control Panel"
        )
        try waitForActivationPolicy(.accessory)
    }

    private func waitForActivationPolicy(
        _ expected: NSApplication.ActivationPolicy,
        timeout: TimeInterval = 4
    ) throws {
        let deadline = Date().addingTimeInterval(timeout)
        var lastPolicy: NSApplication.ActivationPolicy?

        while Date() < deadline {
            let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            let target = try XCTUnwrap(running.first, "CmdQGuard process not found")
            lastPolicy = target.activationPolicy
            if lastPolicy == expected { return }
            Thread.sleep(forTimeInterval: 0.1)
        }

        XCTAssertEqual(
            lastPolicy,
            expected,
            "CmdQGuard activation policy did not become \(expected)"
        )
    }
}
