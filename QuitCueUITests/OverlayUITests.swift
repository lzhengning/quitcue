import XCTest

/// M3 smoke: the `OverlayController.debugForceShow` path puts an NSPanel on
/// screen showing the Aurora Halo card. These tests assert the two
/// mode-specific titles render.
@MainActor
final class OverlayUITests: QuitCueUITestCase {

    private func launch(mode: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
"-com.quitcue.onboarding.completed", "YES",
            "-com.quitcue.doublePressWindow", "2.0",
            "-QuitCue.showOverlayOnLaunch", mode
        ]
        app.launch()
        addTeardownBlock { app.terminate() }
        return app
    }

    func testHoldOverlayRendersHoldTitle() {
        let app = launch(mode: "hold")
        let title = app.descendants(matching: .any)
            .matching(identifier: "overlayTitle")
            .firstMatch
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "Hold-mode overlay title did not appear"
        )
        XCTAssertEqual(title.label, "Hold Command Q to Quit")
    }

    func testDoublePressOverlayRendersPressAgainTitle() {
        let app = launch(mode: "double")
        let title = app.descendants(matching: .any)
            .matching(identifier: "overlayTitle")
            .firstMatch
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "Double-press overlay title did not appear"
        )
        XCTAssertEqual(title.label, "Press Command Q Again")
    }
}
