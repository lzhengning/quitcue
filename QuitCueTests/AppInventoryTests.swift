import XCTest
@testable import QuitCue

final class AppInventoryTests: XCTestCase {
    func testDefaultScanReturnsNonEmptySorted() {
        let apps = AppInventory.scan()
        XCTAssertFalse(apps.isEmpty, "expected some built-in macOS apps to be discovered")

        let names = apps.map(\.name)
        let sorted = names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        XCTAssertEqual(names, sorted, "AppInventory.scan should return a case-insensitive name-sorted list")
    }

    func testUniqueBundleIDs() {
        let apps = AppInventory.scan()
        let ids = apps.map(\.bundleID)
        XCTAssertEqual(ids.count, Set(ids).count, "duplicate bundle IDs in inventory")
    }

    func testDefaultScanIncludesSafariWhenInstalled() throws {
        let safariLocations = [
            "/Applications/Safari.app",
            "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
        ]
        guard safariLocations.contains(where: { FileManager.default.fileExists(atPath: $0) }) else {
            throw XCTSkip("Safari is not installed in a known system location")
        }

        let apps = AppInventory.scan()

        XCTAssertTrue(
            apps.contains { $0.bundleID == "com.apple.Safari" },
            "Safari should be included when installed"
        )
    }

    func testCustomRootReturnsEmptyIfMissing() {
        let nowhere = URL(fileURLWithPath: "/does/not/exist", isDirectory: true)
        XCTAssertEqual(AppInventory.scan(roots: [nowhere]), [])
    }

    func testScanFindsAppsNestedBelowRoot() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let nested = root.appendingPathComponent("Utilities", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try makeApplicationBundle(
            named: "NestedSafari",
            bundleID: "com.example.NestedSafari",
            in: nested
        )

        let apps = AppInventory.scan(roots: [root])

        XCTAssertTrue(
            apps.contains { $0.bundleID == "com.example.NestedSafari" },
            "nested .app bundles should be included in the inventory"
        )
    }

    func testScanIncludesHiddenApplicationSymlinks() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let targetRoot = root.appendingPathComponent("Targets", isDirectory: true)
        try FileManager.default.createDirectory(at: targetRoot, withIntermediateDirectories: true)
        let target = try makeApplicationBundle(
            named: "LinkedSafari",
            bundleID: "com.example.LinkedSafari",
            in: targetRoot
        )

        var symlink = root.appendingPathComponent("LinkedSafari.app")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: target)
        var values = URLResourceValues()
        values.isHidden = true
        try symlink.setResourceValues(values)

        let apps = AppInventory.scan(roots: [root])

        XCTAssertTrue(
            apps.contains { $0.bundleID == "com.example.LinkedSafari" },
            "hidden application symlinks, like Safari on modern macOS, should still be included"
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    private func makeApplicationBundle(named name: String, bundleID: String, in root: URL) throws -> URL {
        let appURL = root.appendingPathComponent("\(name).app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)

        let info: [String: String] = [
            "CFBundleIdentifier": bundleID,
            "CFBundleName": name,
            "CFBundlePackageType": "APPL"
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contentsURL.appendingPathComponent("Info.plist"))

        return appURL
    }
}
