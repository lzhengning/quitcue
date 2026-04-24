import Foundation
import Observation

/// Step in the first-run onboarding walkthrough. The numeric steps (1, 2)
/// are surfaced as "Step 1 of 2" / "Step 2 of 2" in the header; `.welcome`
/// and `.done` are full-bleed transitions without the stepper chrome.
enum OnboardingStep: Int, CaseIterable, Equatable {
    case welcome = 0
    case accessibility = 1
    case appPicker = 2
    case done = 3
}

/// Reactive state for the onboarding scene. Holds the current step +
/// tentative picker selection; commits into `WhitelistStore` only when
/// `finish()` is called so a user who bails halfway leaves no side effects.
@MainActor
@Observable
final class OnboardingFlow {
    var step: OnboardingStep
    var selectedBundleIDs: Set<String>

    /// Launch-arg hook so UI tests can jump directly to a given step:
    /// `-CmdQGuard.onboardingStartStep 2` boots straight into the picker.
    static let startStepDefaultsKey = "CmdQGuard.onboardingStartStep"

    init(startStep: OnboardingStep? = nil, preselected: Set<String> = []) {
        let injected = Self.startStepFromDefaults()
        self.step = startStep ?? injected ?? .welcome
        self.selectedBundleIDs = preselected
    }

    static func startStepFromDefaults() -> OnboardingStep? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: startStepDefaultsKey) != nil else { return nil }
        let raw = defaults.integer(forKey: startStepDefaultsKey)
        return OnboardingStep(rawValue: raw)
    }

    func next() {
        if let nxt = OnboardingStep(rawValue: step.rawValue + 1) {
            step = nxt
        }
    }

    func back() {
        if let prev = OnboardingStep(rawValue: step.rawValue - 1) {
            step = prev
        }
    }

    func toggle(_ bundleID: String) {
        if selectedBundleIDs.contains(bundleID) {
            selectedBundleIDs.remove(bundleID)
        } else {
            selectedBundleIDs.insert(bundleID)
        }
    }

    func clearSelection() { selectedBundleIDs.removeAll() }

    /// Commit the picker selection into the whitelist and mark onboarding
    /// as complete. The scene observes `.done` to present the final view.
    func finish(into whitelist: WhitelistStore) {
        let current = Set(whitelist.bundleIDs)
        for id in selectedBundleIDs where !current.contains(id) {
            whitelist.add(id)
        }
        OnboardingState.isComplete = true
        step = .done
    }
}
