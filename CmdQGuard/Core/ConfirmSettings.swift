import Foundation
import Observation

/// Observable container for persisted confirm-gesture preferences.
/// Surface is intentionally small — the PRD calls out
/// "no per-app custom durations", so this is a single global policy.
@MainActor
@Observable
final class ConfirmSettings {
    static let modeKey = OverlayController.modeDefaultsKey
    static let holdDurationKey = "com.cmdqguard.holdDuration"
    static let doublePressWindowKey = "com.cmdqguard.doublePressWindow"

    /// Slider bounds; exposed so the UI view and tests agree.
    static let holdDurationRange: ClosedRange<TimeInterval> = 0.5...3.0
    static let doublePressWindowRange: ClosedRange<TimeInterval> = 0.6...2.0

    private let defaults: UserDefaults

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
