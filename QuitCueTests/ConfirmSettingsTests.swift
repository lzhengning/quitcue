import XCTest
@testable import QuitCue

@MainActor
final class ConfirmSettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "QuitCueTests.ConfirmSettings"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testDefaultsAreSensible() {
        let s = ConfirmSettings(defaults: defaults)
        XCTAssertTrue(s.isEnabled)
        XCTAssertEqual(s.mode, .hold)
        XCTAssertEqual(s.holdDuration, ConfirmConfig.default.holdDuration)
        XCTAssertEqual(s.doublePressWindow, ConfirmConfig.default.doublePressWindow)
    }

    func testPersistenceRoundTrip() {
        let s = ConfirmSettings(defaults: defaults)
        s.isEnabled = false
        s.mode = .doublePress
        s.holdDuration = 2.2
        s.doublePressWindow = 1.1

        let reloaded = ConfirmSettings(defaults: defaults)
        XCTAssertFalse(reloaded.isEnabled)
        XCTAssertEqual(reloaded.mode, .doublePress)
        XCTAssertEqual(reloaded.holdDuration, 2.2, accuracy: 0.001)
        XCTAssertEqual(reloaded.doublePressWindow, 1.1, accuracy: 0.001)
    }

    func testConfigExposure() {
        let s = ConfirmSettings(defaults: defaults)
        s.holdDuration = 1.8
        s.doublePressWindow = 1.0
        XCTAssertEqual(s.config.holdDuration, 1.8)
        XCTAssertEqual(s.config.doublePressWindow, 1.0)
    }

    func testHoldDurationRangeExposed() {
        XCTAssertLessThan(ConfirmSettings.holdDurationRange.lowerBound, ConfirmSettings.holdDurationRange.upperBound)
        XCTAssertTrue(ConfirmSettings.holdDurationRange.contains(ConfirmConfig.default.holdDuration))
    }
}
