import XCTest

/// M3 smoke: the `OverlayController.debugForceShow` path puts an NSPanel on
/// screen showing the Aurora Halo card. These tests assert the two
/// mode-specific titles render.
final class OverlayUITests: CmdQGuardUITestCase {

    private func launch(mode: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.cmdqguard.onboarding.completed", "YES",
            "-CmdQGuard.showOverlayOnLaunch", mode
        ]
        app.launch()
        addTeardownBlock { app.terminate() }
        return app
    }

    func testHoldOverlayRendersHoldTitle() {
        let app = launch(mode: "hold")
        let title = app.staticTexts["Hold ⌘Q to quit"]
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "Hold-mode overlay title did not appear"
        )
        let subtitle = app.staticTexts["Release to cancel"]
        XCTAssertTrue(subtitle.exists, "Hold-mode subtitle missing")
    }

    func testDoublePressOverlayRendersPressAgainTitle() {
        let app = launch(mode: "double")
        let title = app.staticTexts["Press ⌘Q again"]
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "Double-press overlay title did not appear"
        )
        let subtitle = app.staticTexts["Or let it fade"]
        XCTAssertTrue(subtitle.exists, "Double-press subtitle missing")
    }
}
