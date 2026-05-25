import XCTest
@testable import CmdQGuard

@MainActor
final class OnboardingFlowTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "CmdQGuardTests.OnboardingFlow"

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        OnboardingState.isComplete = false
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        OnboardingState.isComplete = false
    }

    func testStartsAtWelcomeByDefault() {
        let flow = OnboardingFlow()
        XCTAssertEqual(flow.step, .welcome)
    }

    func testNextAdvancesStep() {
        let flow = OnboardingFlow(startStep: .welcome)
        flow.next()
        XCTAssertEqual(flow.step, .accessibility)
        flow.next()
        XCTAssertEqual(flow.step, .appPicker)
    }

    func testBackReverses() {
        let flow = OnboardingFlow(startStep: .appPicker)
        flow.back()
        XCTAssertEqual(flow.step, .accessibility)
    }

    func testToggleAddsAndRemoves() {
        let flow = OnboardingFlow()
        flow.toggle("com.apple.Safari")
        XCTAssertEqual(flow.selectedBundleIDs, ["com.apple.Safari"])
        flow.toggle("com.apple.Safari")
        XCTAssertTrue(flow.selectedBundleIDs.isEmpty)
    }

    func testClearSelection() {
        let flow = OnboardingFlow()
        flow.toggle("com.apple.Safari")
        flow.toggle("com.apple.TextEdit")
        flow.clearSelection()
        XCTAssertTrue(flow.selectedBundleIDs.isEmpty)
    }

    func testFinishCommitsIntoWhitelistAndMarksComplete() {
        let suite = UserDefaults(suiteName: suiteName + ".finish")!
        suite.removePersistentDomain(forName: suiteName + ".finish")
        let store = WhitelistStore(defaults: suite)
        let flow = OnboardingFlow(startStep: .appPicker)
        flow.toggle("com.apple.Safari")
        flow.toggle("com.apple.TextEdit")
        flow.finish(into: store)

        XCTAssertEqual(Set(store.bundleIDs), ["com.apple.Safari", "com.apple.TextEdit"])
        XCTAssertEqual(flow.step, .done)
        XCTAssertTrue(OnboardingState.isComplete)
    }

    func testFinishWithEmptySelectionDoesNotComplete() {
        let suite = UserDefaults(suiteName: suiteName + ".emptyFinish")!
        suite.removePersistentDomain(forName: suiteName + ".emptyFinish")
        let store = WhitelistStore(defaults: suite)
        let flow = OnboardingFlow(startStep: .appPicker)

        flow.finish(into: store)

        XCTAssertTrue(store.bundleIDs.isEmpty)
        XCTAssertEqual(flow.step, .appPicker)
        XCTAssertFalse(OnboardingState.isComplete)
    }
}
