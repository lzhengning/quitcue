import XCTest

/// M5 Control Panel expanded surface: confirm-method picker + duration
/// slider + launch-at-login toggle + add/remove app affordances.
final class ControlPanelM5UITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.cmdqguard.onboarding.completed", "YES",
            "-CmdQGuard.showSettingsOnLaunch", "YES"
        ] + extraArgs
        app.launch()
        addTeardownBlock { app.terminate() }
        return app
    }

    func testConfirmMethodPickerAndDurationSliderRender() {
        let app = launch()
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(identifier: "confirmModePicker")
                .firstMatch.waitForExistence(timeout: 5),
            "confirmModePicker missing"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(identifier: "confirmDurationSlider")
                .firstMatch.exists,
            "confirmDurationSlider missing"
        )
        XCTAssertTrue(
            app.staticTexts["confirmDurationLabel"].exists,
            "duration label missing"
        )
    }

    func testLaunchAtLoginToggleRenders() {
        let app = launch()
        let toggle = app.descendants(matching: .any)
            .matching(identifier: "launchAtLoginToggle").firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "launch-at-login toggle missing")
    }

    func testProtectedAppsEmptyStateByDefault() {
        // Force empty via launchArg override so the test is robust against
        // a whitelist persisted from previous manual dogfooding.
        let app = launch(extraArgs: [
            "-com.cmdqguard.whitelist.bundleIDs", "()"
        ])
        let empty = app.staticTexts["protectedAppsEmpty"]
        XCTAssertTrue(empty.waitForExistence(timeout: 5), "expected empty state")
    }

    func testProtectedAppsRowWithInjectedWhitelistShowsRemoveButton() {
        let app = launch(extraArgs: [
            "-com.cmdqguard.whitelist.bundleIDs", "(\"com.apple.Safari\")"
        ])
        let row = app.descendants(matching: .any)
            .matching(identifier: "whitelistRow_com.apple.Safari").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "whitelist row missing")
        let remove = app.descendants(matching: .any)
            .matching(identifier: "removeProtectedApp_com.apple.Safari").firstMatch
        XCTAssertTrue(remove.exists, "remove button missing")
    }

    func testAddProtectedAppButtonOpensSheet() {
        let app = launch()
        let addButton = app.descendants(matching: .any)
            .matching(identifier: "addProtectedAppButton").firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add button missing")
        addButton.click()

        let search = app.descendants(matching: .any)
            .matching(identifier: "addProtectedAppSearch").firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Add sheet did not open")
    }
}
