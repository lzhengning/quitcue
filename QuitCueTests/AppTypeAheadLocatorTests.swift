import Foundation
import XCTest
@testable import QuitCue

final class AppTypeAheadLocatorTests: XCTestCase {
    func testTypingMultipleCharactersLocatesAppByNamePrefix() {
        var locator = AppTypeAheadLocator(timeout: 1)
        let apps = [
            app(bundleID: "com.apple.Safari", name: "Safari"),
            app(bundleID: "com.tinyspeck.slackmacgap", name: "Slack"),
            app(bundleID: "com.apple.dt.Xcode", name: "Xcode")
        ]

        let safari = locator.locate(
            typedCharacter: "s",
            in: apps,
            currentBundleID: nil,
            now: Date(timeIntervalSinceReferenceDate: 0)
        )
        let slack = locator.locate(
            typedCharacter: "l",
            in: apps,
            currentBundleID: safari?.bundleID,
            now: Date(timeIntervalSinceReferenceDate: 0.2)
        )

        XCTAssertEqual(safari?.bundleID, "com.apple.Safari")
        XCTAssertEqual(slack?.bundleID, "com.tinyspeck.slackmacgap")
    }

    func testTypingAfterTimeoutStartsNewLookup() {
        var locator = AppTypeAheadLocator(timeout: 1)
        let apps = [
            app(bundleID: "com.apple.Safari", name: "Safari"),
            app(bundleID: "com.apple.dt.Xcode", name: "Xcode")
        ]

        _ = locator.locate(
            typedCharacter: "s",
            in: apps,
            currentBundleID: nil,
            now: Date(timeIntervalSinceReferenceDate: 0)
        )
        let match = locator.locate(
            typedCharacter: "x",
            in: apps,
            currentBundleID: "com.apple.Safari",
            now: Date(timeIntervalSinceReferenceDate: 1.1)
        )

        XCTAssertEqual(match?.bundleID, "com.apple.dt.Xcode")
    }

    func testRepeatingSameCharacterCyclesThroughMatchingApps() {
        var locator = AppTypeAheadLocator(timeout: 1)
        let apps = [
            app(bundleID: "com.apple.Safari", name: "Safari"),
            app(bundleID: "com.tinyspeck.slackmacgap", name: "Slack"),
            app(bundleID: "com.readdle.Spark", name: "Spark")
        ]

        let safari = locator.locate(
            typedCharacter: "s",
            in: apps,
            currentBundleID: nil,
            now: Date(timeIntervalSinceReferenceDate: 0)
        )
        let slack = locator.locate(
            typedCharacter: "s",
            in: apps,
            currentBundleID: safari?.bundleID,
            now: Date(timeIntervalSinceReferenceDate: 0.2)
        )
        let spark = locator.locate(
            typedCharacter: "s",
            in: apps,
            currentBundleID: slack?.bundleID,
            now: Date(timeIntervalSinceReferenceDate: 0.4)
        )

        XCTAssertEqual(safari?.bundleID, "com.apple.Safari")
        XCTAssertEqual(slack?.bundleID, "com.tinyspeck.slackmacgap")
        XCTAssertEqual(spark?.bundleID, "com.readdle.Spark")
    }

    private func app(bundleID: String, name: String) -> InstalledApp {
        InstalledApp(
            bundleID: bundleID,
            name: name,
            url: URL(fileURLWithPath: "/Applications/\(name).app")
        )
    }
}
