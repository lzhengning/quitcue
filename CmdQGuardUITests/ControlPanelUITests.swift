import XCTest

/// M2 smoke: Control Panel renders AX status row + whitelist rows injected
/// via `launchArguments` (UserDefaults arg-domain override).
final class ControlPanelUITests: CmdQGuardUITestCase {

    func testControlPanelShowsAccessibilityStatus() {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.cmdqguard.onboarding.completed", "YES",
            "-CmdQGuard.showSettingsOnLaunch", "YES"
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        let granted = app.staticTexts["Accessibility: Granted"]
        let notGranted = app.staticTexts["Accessibility: Not granted"]
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, !granted.exists, !notGranted.exists {
            Thread.sleep(forTimeInterval: 0.2)
        }
        XCTAssertTrue(
            granted.exists || notGranted.exists,
            "Accessibility status row did not appear"
        )
    }

    func testControlPanelListsInjectedWhitelist() {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.cmdqguard.onboarding.completed", "YES",
            "-CmdQGuard.showSettingsOnLaunch", "YES",
            "-com.cmdqguard.whitelist.bundleIDs",
            "(\"com.apple.Safari\", \"com.apple.TextEdit\")"
        ]
        app.launch()
        addTeardownBlock { app.terminate() }

        let safariRow = app.staticTexts["whitelistRow_com.apple.Safari"]
        let textEditRow = app.staticTexts["whitelistRow_com.apple.TextEdit"]

        XCTAssertTrue(
            safariRow.waitForExistence(timeout: 5),
            "Safari whitelist row missing"
        )
        XCTAssertTrue(
            textEditRow.waitForExistence(timeout: 5),
            "TextEdit whitelist row missing"
        )
    }
}
