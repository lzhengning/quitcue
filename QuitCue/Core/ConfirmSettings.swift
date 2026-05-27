import Foundation
import Observation

/// Observable container for persisted confirm-gesture preferences.
/// Surface is intentionally small — the PRD calls out
/// "no per-app custom durations", so this is a single global policy.
@MainActor
@Observable
final class ConfirmSettings {
    nonisolated static let enabledKey = "com.quitcue.enabled"
    nonisolated static let modeKey = "com.quitcue.confirmMode"
    nonisolated static let holdDurationKey = "com.quitcue.holdDuration"
    nonisolated static let doublePressWindowKey = "com.quitcue.doublePressWindow"

    /// Slider bounds; exposed so the UI view and tests agree.
    static let holdDurationRange: ClosedRange<TimeInterval> = 0.5...3.0
    static let doublePressWindowRange: ClosedRange<TimeInterval> = 0.6...2.0

    nonisolated static func isProtectionEnabled(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: enabledKey).map { _ in defaults.bool(forKey: enabledKey) } ?? true
    }

    private let defaults: UserDefaults

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Self.enabledKey) }
    }
    var mode: ConfirmMode {
        didSet { defaults.set(mode.rawValue, forKey: Self.modeKey) }
    }
    var holdDuration: TimeInterval {
        didSet { defaults.set(holdDuration, forKey: Self.holdDurationKey) }
    }
    var doublePressWindow: TimeInterval {
        didSet { defaults.set(doublePressWindow, forKey: Self.doublePressWindowKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isEnabled = Self.isProtectionEnabled(in: defaults)
        self.mode = (defaults.string(forKey: Self.modeKey)
                     .flatMap(ConfirmMode.init(rawValue:))) ?? .hold
        let hd = defaults.double(forKey: Self.holdDurationKey)
        self.holdDuration = (hd > 0) ? hd : ConfirmConfig.default.holdDuration
        let dw = defaults.double(forKey: Self.doublePressWindowKey)
        self.doublePressWindow = (dw > 0) ? dw : ConfirmConfig.default.doublePressWindow
    }

    var config: ConfirmConfig {
        ConfirmConfig(holdDuration: holdDuration, doublePressWindow: doublePressWindow)
    }
}
