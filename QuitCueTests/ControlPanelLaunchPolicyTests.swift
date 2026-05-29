import XCTest
@testable import QuitCue

final class ControlPanelLaunchPolicyTests: XCTestCase {
    func testShowsControlPanelWhenLaunchArgumentRequestsIt() {
        XCTAssertTrue(
            ControlPanelLaunchPolicy.shouldShowControlPanel(
                showSettingsOnLaunch: true,
                isQuitCueEnabled: true
            )
        )
    }

    func testShowsControlPanelWhenQuitCueIsDisabledSoUserCanReEnable() {
        XCTAssertTrue(
            ControlPanelLaunchPolicy.shouldShowControlPanel(
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
