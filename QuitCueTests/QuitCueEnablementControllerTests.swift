import XCTest
@testable import QuitCue

@MainActor
final class QuitCueEnablementControllerTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "QuitCueTests.QuitCueEnablementController"

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
    }

    func testDisablingQuitCueStopsProtectionDisablesLaunchAtLoginAndTerminates() {
        let settings = ConfirmSettings(defaults: defaults)
        settings.isEnabled = true
        let launchAtLogin = LaunchAtLoginManager(backend: FakeLaunchAtLoginBackend(state: true))
        var didStartProtection = false
        var didStopProtection = false
        var didCancelActiveConfirmation = false
        var didTerminateApplication = false
        let controller = QuitCueEnablementController(
            settings: settings,
            launchAtLogin: launchAtLogin,
            startProtection: { didStartProtection = true },
            stopProtection: { didStopProtection = true },
            cancelActiveConfirmation: { didCancelActiveConfirmation = true },
            terminateApplication: { didTerminateApplication = true }
        )

        controller.setEnabled(false)

        XCTAssertFalse(settings.isEnabled)
        XCTAssertFalse(launchAtLogin.isEnabled)
        XCTAssertFalse(didStartProtection)
        XCTAssertTrue(didStopProtection)
        XCTAssertTrue(didCancelActiveConfirmation)
        XCTAssertTrue(didTerminateApplication)
    }

    func testEnablingQuitCueStartsProtectionWithoutTerminating() {
        let settings = ConfirmSettings(defaults: defaults)
        settings.isEnabled = false
        let launchAtLogin = LaunchAtLoginManager(backend: FakeLaunchAtLoginBackend(state: false))
        var didStartProtection = false
        var didStopProtection = false
        var didTerminateApplication = false
        let controller = QuitCueEnablementController(
            settings: settings,
            launchAtLogin: launchAtLogin,
            startProtection: { didStartProtection = true },
            stopProtection: { didStopProtection = true },
            cancelActiveConfirmation: {},
            terminateApplication: { didTerminateApplication = true }
        )

        controller.setEnabled(true)

        XCTAssertTrue(settings.isEnabled)
        XCTAssertTrue(didStartProtection)
        XCTAssertFalse(didStopProtection)
        XCTAssertFalse(didTerminateApplication)
    }
}
