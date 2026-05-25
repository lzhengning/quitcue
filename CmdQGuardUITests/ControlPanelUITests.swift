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

        let status = app.descendants(matching: .any)
            .matching(identifier: "accessibilityStatus").firstMatch
        XCTAssertTrue(
            status.waitForExistence(timeout: 5),
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

        let safariRow = app.descendants(matching: .any)
            .matching(identifier: "whitelistRow_com.apple.Safari").firstMatch
        let textEditRow = app.descendants(matching: .any)
            .matching(identifier: "whitelistRow_com.apple.TextEdit").firstMatch

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
