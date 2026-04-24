import Foundation
import Observation

/// Persisted whitelist of bundle identifiers whose ⌘Q should be intercepted.
/// Backed by `UserDefaults` under a namespaced key so it participates in the
/// same argument-domain override scheme as `OnboardingState` (tests can inject
/// a fixture array via `launchArguments`).
@Observable
final class WhitelistStore {
    static let defaultsKey = "com.cmdqguard.whitelist.bundleIDs"

    private let defaults: UserDefaults
    private(set) var bundleIDs: [String]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.bundleIDs = (defaults.array(forKey: Self.defaultsKey) as? [String]) ?? []
    }

    func contains(_ bundleID: String) -> Bool {
        bundleIDs.contains(bundleID)
    }

    func add(_ bundleID: String) {
        guard !bundleID.isEmpty, !contains(bundleID) else { return }
        bundleIDs.append(bundleID)
        persist()
    }

    func remove(_ bundleID: String) {
        guard let idx = bundleIDs.firstIndex(of: bundleID) else { return }
        bundleIDs.remove(at: idx)
        persist()
    }

    /// Reload from the backing defaults (call this when launch arguments
    /// or a cross-process write may have mutated the value).
    func reload() {
        bundleIDs = (defaults.array(forKey: Self.defaultsKey) as? [String]) ?? []
    }

    private func persist() {
        defaults.set(bundleIDs, forKey: Self.defaultsKey)
    }
}
