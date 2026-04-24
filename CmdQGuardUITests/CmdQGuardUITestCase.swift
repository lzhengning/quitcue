import XCTest

/// Shared base for XCUITest cases. Because the production PRD keeps the
/// app alive after the last window closes (Dock icon visible,
/// CGEventTap running in the background), and Dock-icon apps are
/// single-instance per bundle ID, a prior test's still-running process
/// will survive into the next test's `XCUIApplication.launch()` call
/// and ignore the fresh `launchArguments`. We force-terminate any
/// lingering instances in `setUp` and wait for the OS to actually reap
/// them before handing control back to the test.
class CmdQGuardUITestCase: XCTestCase {
    private let bundleID = "com.cmdqguard.CmdQGuard"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        terminateLingeringInstances()
    }

    private func terminateLingeringInstances() {
        var instances = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        guard !instances.isEmpty else { return }
        for app in instances { app.forceTerminate() }

        let deadline = Date().addingTimeInterval(4)
        while Date() < deadline {
            instances = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            if instances.isEmpty { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
}
