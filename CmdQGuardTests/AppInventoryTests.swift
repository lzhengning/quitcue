import XCTest
@testable import CmdQGuard

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

    func testCustomRootReturnsEmptyIfMissing() {
        let nowhere = URL(fileURLWithPath: "/does/not/exist", isDirectory: true)
        XCTAssertEqual(AppInventory.scan(roots: [nowhere]), [])
    }
}
