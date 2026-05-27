import Foundation

/// Which confirm gesture the user prefers. Stored via `UserDefaults` under
/// `com.quitcue.confirmMode`; a UI picker arrives in M5.
enum ConfirmMode: String, Sendable, CaseIterable {
    case hold
    case doublePress = "double"
}

struct ConfirmConfig: Sendable, Equatable {
    /// Seconds the user must hold ⌘Q before quit commits.
    var holdDuration: TimeInterval = 1.5
    /// Window within which the second ⌘Q must arrive.
    var doublePressWindow: TimeInterval = 1.4

    static let `default` = ConfirmConfig()
}

/// Pure value-type reducer for the confirm flow. Produces a phase; the
/// controller layer owns timers and side effects (show overlay, terminate
/// app, etc.). Time is injected to keep this unit-testable.
struct ConfirmStateMachine: Equatable {
    enum Phase: Equatable {
        case idle
        case holding(startedAt: Date)
        case awaitingSecondPress(startedAt: Date)
        case confirmed
    }

    let mode: ConfirmMode
    let config: ConfirmConfig
    private(set) var phase: Phase

    init(mode: ConfirmMode, config: ConfirmConfig = .default) {
        self.mode = mode
        self.config = config
        self.phase = .idle
    }

    mutating func cmdQDown(at now: Date) {
        switch phase {
        case .idle:
            switch mode {
            case .hold: phase = .holding(startedAt: now)
            case .doublePress: phase = .awaitingSecondPress(startedAt: now)
            }
        case .holding, .confirmed:
            // Auto-repeat keyDown while already holding, or a stray event
            // after commitment — ignore.
            break
        case .awaitingSecondPress:
            phase = .confirmed
        }
    }

    mutating func cmdQUp(at now: Date) {
        // Only hold-mode cares about release; double-press ignores it.
        if case .holding = phase { phase = .idle }
    }

    mutating func tick(at now: Date) {
        switch phase {
        case .holding(let start):
            if now.timeIntervalSince(start) >= config.holdDuration { phase = .confirmed }
        case .awaitingSecondPress(let start):
            if now.timeIntervalSince(start) >= config.doublePressWindow { phase = .idle }
        case .idle, .confirmed:
            break
        }
    }

    mutating func reset() { phase = .idle }

    /// Progress in [0, 1] of the active window, or 0 when idle/confirmed.
    func progress(at now: Date) -> Double {
        switch phase {
        case .holding(let start):
            return clamp(now.timeIntervalSince(start) / config.holdDuration)
        case .awaitingSecondPress(let start):
            return clamp(now.timeIntervalSince(start) / config.doublePressWindow)
        case .idle, .confirmed:
            return 0
        }
    }

    var isActive: Bool {
        switch phase {
        case .holding, .awaitingSecondPress: return true
        case .idle, .confirmed: return false
        }
    }
}

private func clamp(_ v: Double) -> Double { min(1, max(0, v)) }
