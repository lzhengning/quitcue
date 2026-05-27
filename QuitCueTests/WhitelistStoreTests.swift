import XCTest
@testable import QuitCue

final class WhitelistStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "QuitCueTests.WhitelistStore"

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

    func testStartsEmpty() {
        let store = WhitelistStore(defaults: defaults)
        XCTAssertTrue(store.bundleIDs.isEmpty)
    }

    func testAddPersistsAndDedupes() {
        let store = WhitelistStore(defaults: defaults)
        store.add("com.apple.Safari")
        store.add("com.apple.Safari")
        store.add("")
        XCTAssertEqual(store.bundleIDs, ["com.apple.Safari"])

        let reloaded = WhitelistStore(defaults: defaults)
        XCTAssertEqual(reloaded.bundleIDs, ["com.apple.Safari"])
    }

    func testRemove() {
        let store = WhitelistStore(defaults: defaults)
        store.add("com.apple.Safari")
        store.add("com.apple.TextEdit")
        store.remove("com.apple.Safari")
        XCTAssertEqual(store.bundleIDs, ["com.apple.TextEdit"])
    }

    func testContains() {
        let store = WhitelistStore(defaults: defaults)
        store.add("com.apple.Safari")
        XCTAssertTrue(store.contains("com.apple.Safari"))
        XCTAssertFalse(store.contains("com.apple.TextEdit"))
    }

    func testReloadPicksUpExternalWrite() {
        let store = WhitelistStore(defaults: defaults)
        defaults.set(["com.apple.Safari"], forKey: WhitelistStore.defaultsKey)
        store.reload()
        XCTAssertEqual(store.bundleIDs, ["com.apple.Safari"])
    }
}
