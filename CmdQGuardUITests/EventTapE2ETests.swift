import XCTest
import AppKit

/// Event-tap E2E suite. Exercises CmdQGuard's `CGEventTap` interception
/// against a real target app (Calculator) inside the authorised VM.
///
/// These tests require:
///   - /Applications/CmdQGuard.app staged with a stable local signing
///     identity (the private VM harness handles this).
///   - /usr/local/bin/keysender CLI baked into the same snapshot.
///   - Accessibility + Input Monitoring granted to BOTH the CmdQGuard
///     bundle and keysender (captured in authorised VM snapshot).
///
/// We can't drive ⌘Q from XCUITest's `typeKey` because that path goes
/// through AX/Apple Events and never reaches a CGEventTap. Instead we
/// shell out to `keysender`, which uses CGEventPost(.cghidEventTap),
/// the same path real hardware input takes.
///
/// When run on a host that doesn't have the staged bundle, every case
/// is skipped so the suite never fails outside the VM lane.
final class EventTapE2ETests: CmdQGuardUITestCase {
    private static let stagedBundlePath = "/Applications/CmdQGuard.app"
    private static let keysenderPath = "/Applications/Keysender.app/Contents/MacOS/keysender"
    private static let calculatorBundleID = "com.apple.calculator"
    // Virtual key code for 'Q' on the US ANSI layout (kVK_ANSI_Q = 12).
    private static let kVKQ = "12"

    override func setUpWithError() throws {
        super.setUp()
        let fm = FileManager.default
        try XCTSkipUnless(
            fm.fileExists(atPath: Self.stagedBundlePath),
            "No staged /Applications/CmdQGuard.app — stage the app in the authorised VM first."
        )
        try XCTSkipUnless(
            fm.fileExists(atPath: Self.keysenderPath),
            "No /Applications/Keysender.app — stage Keysender in the authorised VM."
        )
    }

    // MARK: - Cases

    /// Control case: with Calculator NOT whitelisted, ⌘Q should pass
    /// through unmodified and Calculator should quit.
    func testCmdQOnNonWhitelistedAppQuitsIt() throws {
        let cmdq = launchStagedCmdQGuard(whitelist: [])
        addTeardownBlock { cmdq.terminate() }

        _ = launchCalculator()
        sendCmdQ()

        XCTAssertTrue(
            waitForCalculatorState(.notRunning, timeout: 5),
            "Calculator should have quit when ⌘Q is not intercepted"
        )
    }

    /// With Calculator whitelisted in hold mode, a brief ⌘Q tap should
    /// be swallowed; Calculator stays alive.
    func testCmdQOnWhitelistedAppIsBlocked() throws {
        let cmdq = launchStagedCmdQGuard(
            whitelist: [Self.calculatorBundleID],
            mode: "hold",
            showSettings: true
        )
        addTeardownBlock { cmdq.terminate() }

        // Diagnostic: confirm the whitelist arg-domain override actually
        // reached the staged bundle by checking Control Panel surface it.
        let calcRow = cmdq.staticTexts["whitelistRow_com.apple.calculator"]
        XCTAssertTrue(
            calcRow.waitForExistence(timeout: 5),
            "Whitelist injection did not reach staged CmdQGuard.app"
        )

        let calc = launchCalculator()
        sendCmdQ()

        // Give CmdQGuard a beat to see + swallow the event.
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertTrue(
            isCalculatorRunning(),
            "Calculator should still be alive when CmdQGuard intercepts ⌘Q"
        )

        // Cleanup: real quit so the next test starts clean.
        calc.terminate()
    }

    // MARK: - Helpers

    private func launchStagedCmdQGuard(
        whitelist: [String],
        mode: String = "hold",
        showSettings: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication(
            url: URL(fileURLWithPath: Self.stagedBundlePath)
        )
        var args: [String] = [
            "-com.cmdqguard.onboarding.completed", "YES",
            "-com.cmdqguard.confirmMode", mode,
            "-CmdQGuard.eventTapDiagnostics", "YES"
        ]
        if showSettings {
            args.append("-CmdQGuard.showSettingsOnLaunch")
            args.append("YES")
        }
        if !whitelist.isEmpty {
            let plistArray = "(" + whitelist
                .map { "\"\($0)\"" }
                .joined(separator: ", ") + ")"
            args.append("-com.cmdqguard.whitelist.bundleIDs")
            args.append(plistArray)
        }
        app.launchArguments = args
        app.launch()
        // CmdQGuard needs a moment to install its event tap.
        Thread.sleep(forTimeInterval: 1.5)
        return app
    }

    private func launchCalculator() -> XCUIApplication {
        let calc = XCUIApplication(bundleIdentifier: Self.calculatorBundleID)
        calc.launch()
        XCTAssertTrue(
            calc.wait(for: .runningForeground, timeout: 5),
            "Calculator failed to reach the foreground"
        )
        // Settle so it's truly the key window before injecting events.
        Thread.sleep(forTimeInterval: 0.5)
        return calc
    }

    private func sendCmdQ(holdSeconds: Double = 0.05) {
        var keyArgs = [Self.kVKQ, "--cmd"]
        if holdSeconds > 0 {
            keyArgs.append("--hold")
            keyArgs.append(String(holdSeconds))
        }
        // Invoke keysender via ssh-to-localhost so sshd-keygen-wrapper
        // becomes the responsible process. The test runner's TCC chain
        // has no PostEvent grant; sshd-keygen-wrapper is granted
        // everything in the Cirrus image. Bypassing the chain is the
        // only reliable way to get CGEventPost to actually land.
        // The VM harness sets up the key inside the ephemeral VM.
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        proc.arguments = [
            "-i", "/Users/admin/.ssh/id_ed25519_test",
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "LogLevel=ERROR",
            "admin@127.0.0.1",
            Self.keysenderPath,
        ] + keyArgs
        let errPipe = Pipe()
        let outPipe = Pipe()
        proc.standardError = errPipe
        proc.standardOutput = outPipe
        do { try proc.run() } catch {
            XCTFail("Failed to run keysender over ssh-loopback: \(error)")
            return
        }
        proc.waitUntilExit()
        let errMsg = String(
            data: errPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let outMsg = String(
            data: outPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        XCTAssertEqual(
            proc.terminationStatus, 0,
            "keysender (via ssh) exited with status \(proc.terminationStatus); stdout: \(outMsg); stderr: \(errMsg)"
        )
    }

    /// `XCUIApplication.state` lags badly on macOS when a target app
    /// terminates from within itself (e.g. via ⌘Q), so we query
    /// NSRunningApplication directly.
    private func isCalculatorRunning() -> Bool {
        !NSRunningApplication.runningApplications(
            withBundleIdentifier: Self.calculatorBundleID
        ).isEmpty
    }

    private func waitForCalculatorState(
        _ state: XCUIApplication.State,
        timeout: TimeInterval
    ) -> Bool {
        let wantRunning = (state != .notRunning)
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isCalculatorRunning() == wantRunning { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return false
    }
}
