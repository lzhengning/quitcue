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

final class ControlPanelProtectedAppOrderingTests: XCTestCase {
    func testSelectedTilesUseDisplayNameOrderAfterSelectAll() {
        let alpha = InstalledApp(
            bundleID: "com.example.beta",
            name: "Alpha",
            url: URL(fileURLWithPath: "/Applications/Alpha.app")
        )
        let figma = InstalledApp(
            bundleID: "com.example.gamma",
            name: "Figma",
            url: URL(fileURLWithPath: "/Applications/Figma.app")
        )
        let zoom = InstalledApp(
            bundleID: "com.example.alpha",
            name: "Zoom",
            url: URL(fileURLWithPath: "/Applications/Zoom.app")
        )

        let tiles = ProtectedAppTileOrdering.orderedTiles(
            selectedBundleIDs: [
                zoom.bundleID,
                figma.bundleID,
                alpha.bundleID
            ],
            installedApps: [alpha, figma, zoom]
        )

        XCTAssertEqual(tiles.map(\.name), ["Alpha", "Figma", "Zoom"])
    }
}
