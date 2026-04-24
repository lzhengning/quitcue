import XCTest
@testable import CmdQGuard

final class DesignSystemTests: XCTestCase {
    func testOnboardingStatePersistsRoundTrip() {
        OnboardingState.isComplete = false
        XCTAssertTrue(OnboardingState.shouldPresentOnLaunch)

        OnboardingState.isComplete = true
        XCTAssertFalse(OnboardingState.shouldPresentOnLaunch)

        // Reset for other test runs.
        OnboardingState.isComplete = false
    }
}
