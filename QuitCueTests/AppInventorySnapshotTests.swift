import XCTest
@testable import QuitCue

final class AppInventorySnapshotTests: XCTestCase {
    func testRefreshReplacesExistingSnapshotWithLatestScanResult() {
        let safari = InstalledApp(
            bundleID: "com.apple.Safari",
            name: "Safari",
            url: URL(fileURLWithPath: "/Applications/Safari.app")
        )
        let figma = InstalledApp(
            bundleID: "com.figma.Desktop",
            name: "Figma",
            url: URL(fileURLWithPath: "/Applications/Figma.app")
        )

        var snapshot = AppInventorySnapshot(
            apps: [safari],
            scanner: { [safari, figma] }
        )

        let refreshedApps = snapshot.refresh()

        XCTAssertEqual(refreshedApps, [safari, figma])
        XCTAssertEqual(snapshot.apps, [safari, figma])
    }
}
