import XCTest
@testable import CmdQGuard

final class DesignSystemTests: XCTestCase {
    @MainActor
    func testAppIconHeroResizesResolvedIconForHeroDisplay() throws {
        let safariLocations = [
            "/Applications/Safari.app",
            "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
        ]
        guard safariLocations.contains(where: { FileManager.default.fileExists(atPath: $0) }) else {
            throw XCTSkip("Safari is not installed in a known system location")
        }

        let icon = try XCTUnwrap(AppIconHero.resolvedIcon(bundleID: "com.apple.Safari", size: 88))

        XCTAssertEqual(icon.size.width, 88)
        XCTAssertEqual(icon.size.height, 88)
        XCTAssertTrue(
            icon.representations.contains { $0.pixelsWide >= 176 || $0.pixelsHigh >= 176 },
            "hero icon should retain high-resolution representations for retina rendering"
        )
    }

    func testOnboardingStatePersistsRoundTrip() {
        OnboardingState.isComplete = false
        XCTAssertTrue(OnboardingState.shouldPresentOnLaunch)

        OnboardingState.isComplete = true
        XCTAssertFalse(OnboardingState.shouldPresentOnLaunch)

        // Reset for other test runs.
        OnboardingState.isComplete = false
    }
}

@MainActor
final class DockPresenceControllerTests: XCTestCase {
    func testVisibleControlPanelUsesRegularActivationPolicy() {
        let application = FakeDockPresenceApplication()
        let controller = DockPresenceController(application: application)

        controller.controlPanelDidOpen()

        XCTAssertEqual(application.activationPolicies, [.regular])
    }

    func testClosingControlPanelHidesDockWithoutTerminating() {
        let application = FakeDockPresenceApplication()
        let controller = DockPresenceController(application: application)

        controller.controlPanelDidClose()

        XCTAssertEqual(application.activationPolicies, [.accessory])
        XCTAssertFalse(application.didTerminate)
    }

    func testCommandQClosesControlPanelAndHidesDockWithoutTerminating() {
        let application = FakeDockPresenceApplication()
        let window = FakeDockPresenceWindow()
        let controller = DockPresenceController(application: application)

        controller.hideControlPanel(window: window)

        XCTAssertTrue(window.didClose)
        XCTAssertEqual(application.activationPolicies, [.accessory])
        XCTAssertFalse(application.didTerminate)
    }
}

@MainActor
private final class FakeDockPresenceApplication: DockPresenceApplication {
    var activationPolicies: [NSApplication.ActivationPolicy] = []
    var didTerminate = false

    func setActivationPolicy(_ activationPolicy: NSApplication.ActivationPolicy) -> Bool {
        activationPolicies.append(activationPolicy)
        return true
    }

    func terminate(_ sender: Any?) {
        didTerminate = true
    }
}

@MainActor
private final class FakeDockPresenceWindow: DockPresenceWindow {
    var didClose = false

    func close() {
        didClose = true
    }
}
