import XCTest
@testable import QuitCue

final class ControlPanelLaunchPolicyTests: XCTestCase {
    func testShowsControlPanelWhenLaunchArgumentRequestsIt() {
        XCTAssertTrue(
            ControlPanelLaunchPolicy.shouldShowControlPanel(
                onboardingComplete: false,
                showSettingsOnLaunch: true,
                isQuitCueEnabled: true
            )
        )
    }

    func testShowsControlPanelWhenQuitCueIsDisabledSoUserCanReEnable() {
        XCTAssertTrue(
            ControlPanelLaunchPolicy.shouldShowControlPanel(
                onboardingComplete: true,
                showSettingsOnLaunch: false,
                isQuitCueEnabled: false
            )
        )
    }

    func testDoesNotShowControlPanelBeforeOnboardingCompletesJustBecauseQuitCueIsDisabled() {
        XCTAssertFalse(
            ControlPanelLaunchPolicy.shouldShowControlPanel(
                onboardingComplete: false,
                showSettingsOnLaunch: false,
                isQuitCueEnabled: false
            )
        )
    }

    func testHidesDockOnlyForEnabledBackgroundLaunches() {
        XCTAssertTrue(
            ControlPanelLaunchPolicy.shouldHideDockAfterLaunch(
                onboardingComplete: true,
                showSettingsOnLaunch: false,
                isQuitCueEnabled: true
            )
        )
        XCTAssertFalse(
            ControlPanelLaunchPolicy.shouldHideDockAfterLaunch(
                onboardingComplete: true,
                showSettingsOnLaunch: false,
                isQuitCueEnabled: false
            )
        )
    }
}
