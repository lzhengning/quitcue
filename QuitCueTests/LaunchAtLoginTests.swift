import XCTest
@testable import QuitCue

@MainActor
final class FakeLaunchAtLoginBackend: LaunchAtLoginBackend {
    var state: Bool
    var registerError: Error?
    var unregisterError: Error?

    init(state: Bool = false) { self.state = state }

    var isEnabled: Bool { state }
    func register() throws {
        if let e = registerError { throw e }
        state = true
    }
    func unregister() throws {
        if let e = unregisterError { throw e }
        state = false
    }
}

@MainActor
final class LaunchAtLoginTests: XCTestCase {
    func testInitReadsBackendState() {
        let backend = FakeLaunchAtLoginBackend(state: true)
        let manager = LaunchAtLoginManager(backend: backend)
        XCTAssertTrue(manager.isEnabled)
    }

    func testSetEnabledTogglesState() {
        let backend = FakeLaunchAtLoginBackend(state: false)
        let manager = LaunchAtLoginManager(backend: backend)

        manager.setEnabled(true)
        XCTAssertTrue(manager.isEnabled)
        XCTAssertNil(manager.lastError)

        manager.setEnabled(false)
        XCTAssertFalse(manager.isEnabled)
        XCTAssertNil(manager.lastError)
    }

    func testSetEnabledSurfacesRegisterError() {
        struct FakeErr: Error, LocalizedError { var errorDescription: String? { "boom" } }
        let backend = FakeLaunchAtLoginBackend(state: false)
        backend.registerError = FakeErr()
        let manager = LaunchAtLoginManager(backend: backend)
        manager.setEnabled(true)
        XCTAssertFalse(manager.isEnabled)
        XCTAssertEqual(manager.lastError, "boom")
    }

    func testRefreshPicksUpExternalChange() {
        let backend = FakeLaunchAtLoginBackend(state: false)
        let manager = LaunchAtLoginManager(backend: backend)
        backend.state = true
        manager.refresh()
        XCTAssertTrue(manager.isEnabled)
    }
}
