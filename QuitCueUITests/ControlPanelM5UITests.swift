import XCTest

/// M5 Control Panel expanded surface: confirm-method picker + duration
/// slider + launch-at-login toggle + protected-app grid toggles.
@MainActor
final class ControlPanelM5UITests: QuitCueUITestCase {

    private func launch(extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.quitcue.onboarding.completed", "YES",
            "-QuitCue.useUITestAppInventory", "YES",
            "-QuitCue.showSettingsOnLaunch", "YES",
            "-com.quitcue.holdDuration", "1.5"
        ] + extraArgs
        app.launch()
        addTeardownBlock { app.terminate() }
        return app
    }

    func testConfirmMethodPickerAndDurationSliderRender() {
        let app = launch()
        XCTAssertTrue(
            app.staticTexts["Confirm Method"].waitForExistence(timeout: 5),
            "confirm method section missing"
        )
        XCTAssertTrue(
            app.buttons["Hold ⌘Q"].exists,
            "hold confirm option missing"
        )
        XCTAssertTrue(
            app.buttons["Press ⌘Q twice"].exists,
            "double-press confirm option missing"
        )
        XCTAssertTrue(
            app.sliders.firstMatch.exists,
            "confirm duration slider missing"
        )
        XCTAssertTrue(
            app.staticTexts["1.5s"].exists,
            "duration label missing"
        )
    }

    func testLaunchAtLoginToggleRenders() {
        let app = launch()
        XCTAssertTrue(
            app.staticTexts["Launch at Login"].waitForExistence(timeout: 5),
            "launch-at-login label missing"
        )
    }

    func testProtectedAppsEmptyStateByDefault() {
        // Force empty via launchArg override so the test is robust against
        // a whitelist persisted from previous manual dogfooding.
        let app = launch(extraArgs: [
            "-com.quitcue.whitelist.bundleIDs", "()"
        ])
        let empty = app.staticTexts["Tap an app to start protecting it."]
        XCTAssertTrue(empty.waitForExistence(timeout: 5), "expected empty state")
    }

    func testProtectedAppsRowWithInjectedWhitelistShowsRemoveButton() {
        let app = launch(extraArgs: [
            "-com.quitcue.whitelist.bundleIDs", "(\"com.apple.Safari\")"
        ])
        let row = app.descendants(matching: .any)
            .matching(identifier: "whitelistRow_com.apple.Safari").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "whitelist row missing")
        row.click()
        XCTAssertFalse(row.waitForExistence(timeout: 2), "selected tile should toggle off")
    }

    func testAvailableAppGridTileCanBeSelected() {
        let app = launch(extraArgs: [
            "-com.quitcue.whitelist.bundleIDs", "()"
        ])
        let safariTile = app.descendants(matching: .any)
            .matching(identifier: "appTile_com.apple.Safari")
            .firstMatch
        XCTAssertTrue(
            safariTile.waitForExistence(timeout: 5),
            "available app grid should show Safari"
        )
        safariTile.click()

        let selectedTile = app.descendants(matching: .any)
            .matching(identifier: "whitelistRow_com.apple.Safari").firstMatch
        XCTAssertTrue(selectedTile.waitForExistence(timeout: 2), "available tile should toggle on")
    }
}
