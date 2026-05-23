import XCTest

/// M4 onboarding coverage: welcome title, advance to Accessibility step,
/// jump straight to the app picker via `onboardingStartStep` launch flag.
final class OnboardingFlowUITests: CmdQGuardUITestCase {

    private func launch(onboardingComplete: Bool, startStep: Int? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        var args = [
"-com.cmdqguard.onboarding.completed", onboardingComplete ? "YES" : "NO"
        ]
        if let startStep {
            args += ["-CmdQGuard.onboardingStartStep", String(startStep)]
        }
        app.launchArguments = args
        app.launch()
        addTeardownBlock { app.terminate() }
        return app
    }

    func testWelcomeStepRendersTitleAndCTA() {
        let app = launch(onboardingComplete: false)
        let title = app.staticTexts["welcomeTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "welcome title missing")
        let cta = app.buttons["getStartedButton"]
        XCTAssertTrue(cta.exists, "Get started button missing")
    }

    func testGetStartedAdvancesToAccessibilityStep() {
        let app = launch(onboardingComplete: false)
        let cta = app.buttons["getStartedButton"]
        XCTAssertTrue(cta.waitForExistence(timeout: 5))
        cta.click()

        let axTitle = app.staticTexts["accessibilityStepTitle"]
        XCTAssertTrue(axTitle.waitForExistence(timeout: 5), "did not advance to Accessibility step")
        let toggle = app.descendants(matching: .any)
            .matching(identifier: "accessibilityToggle").firstMatch
        XCTAssertTrue(toggle.exists, "AX toggle missing")
    }

    func testJumpStraightToAppPicker() {
        let app = launch(onboardingComplete: false, startStep: 2)
        let pickerTitle = app.staticTexts["appPickerTitle"]
        XCTAssertTrue(pickerTitle.waitForExistence(timeout: 5), "app picker did not render")
        let count = app.staticTexts["appPickerCount"]
        XCTAssertTrue(count.exists, "apps-protected count missing")
        XCTAssertTrue(app.buttons["finishButton"].exists, "finish button missing")
    }

    func testAppPickerShowsSafariWhenInstalled() throws {
        guard FileManager.default.fileExists(atPath: "/Applications/Safari.app") else {
            throw XCTSkip("Safari is not installed in /Applications")
        }

        let app = launch(onboardingComplete: false, startStep: 2)
        let safariTile = app.buttons["appTile_com.apple.Safari"]

        XCTAssertTrue(safariTile.waitForExistence(timeout: 5), "Safari should be visible in the app picker")
    }
}
