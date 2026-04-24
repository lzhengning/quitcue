import XCTest
@testable import CmdQGuard

final class ConfirmStateMachineTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 100)

    // MARK: Hold mode

    func testHoldEnterOnCmdQDown() {
        var m = ConfirmStateMachine(mode: .hold)
        m.cmdQDown(at: t0)
        XCTAssertTrue(m.isActive)
    }

    func testHoldReleaseBeforeDurationCancels() {
        var m = ConfirmStateMachine(mode: .hold, config: ConfirmConfig(holdDuration: 1.5, doublePressWindow: 1.4))
        m.cmdQDown(at: t0)
        m.cmdQUp(at: t0.addingTimeInterval(0.5))
        XCTAssertFalse(m.isActive)
        XCTAssertEqual(m.phase, .idle)
    }

    func testHoldCompletesAtDuration() {
        var m = ConfirmStateMachine(mode: .hold, config: ConfirmConfig(holdDuration: 1.5, doublePressWindow: 1.4))
        m.cmdQDown(at: t0)
        m.tick(at: t0.addingTimeInterval(1.6))
        XCTAssertEqual(m.phase, .confirmed)
    }

    func testHoldTickBeforeDurationStaysHolding() {
        var m = ConfirmStateMachine(mode: .hold)
        m.cmdQDown(at: t0)
        m.tick(at: t0.addingTimeInterval(1.0))
        XCTAssertTrue(m.isActive)
    }

    func testHoldProgressMonotonic() {
        var m = ConfirmStateMachine(mode: .hold, config: ConfirmConfig(holdDuration: 1.0, doublePressWindow: 1.0))
        m.cmdQDown(at: t0)
        XCTAssertEqual(m.progress(at: t0), 0, accuracy: 0.01)
        XCTAssertEqual(m.progress(at: t0.addingTimeInterval(0.5)), 0.5, accuracy: 0.01)
        XCTAssertEqual(m.progress(at: t0.addingTimeInterval(2.0)), 1.0, accuracy: 0.01)
    }

    // MARK: Double-press mode

    func testDoublePressEnterOnFirstCmdQ() {
        var m = ConfirmStateMachine(mode: .doublePress)
        m.cmdQDown(at: t0)
        XCTAssertTrue(m.isActive)
    }

    func testDoublePressConfirmsOnSecondCmdQ() {
        var m = ConfirmStateMachine(mode: .doublePress, config: ConfirmConfig(holdDuration: 1.5, doublePressWindow: 1.4))
        m.cmdQDown(at: t0)
        m.cmdQDown(at: t0.addingTimeInterval(0.7))
        XCTAssertEqual(m.phase, .confirmed)
    }

    func testDoublePressTimeoutReturnsToIdle() {
        var m = ConfirmStateMachine(mode: .doublePress, config: ConfirmConfig(holdDuration: 1.5, doublePressWindow: 1.4))
        m.cmdQDown(at: t0)
        m.tick(at: t0.addingTimeInterval(1.5))
        XCTAssertEqual(m.phase, .idle)
    }

    func testDoublePressIgnoresKeyUp() {
        var m = ConfirmStateMachine(mode: .doublePress)
        m.cmdQDown(at: t0)
        m.cmdQUp(at: t0.addingTimeInterval(0.1))
        XCTAssertTrue(m.isActive)
    }

    // MARK: Reset

    func testResetFromAnyPhase() {
        var m = ConfirmStateMachine(mode: .hold)
        m.cmdQDown(at: t0)
        m.reset()
        XCTAssertEqual(m.phase, .idle)
    }
}
