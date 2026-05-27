import Foundation

/// Persisted first-run gate. Stored in `UserDefaults` under a namespaced key so
/// a reset during development is a single `defaults delete` away.
enum OnboardingState {
    private static let completedKey = "com.quitcue.onboarding.completed"

    static var isComplete: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    static var shouldPresentOnLaunch: Bool {
        !isComplete
    }
}
