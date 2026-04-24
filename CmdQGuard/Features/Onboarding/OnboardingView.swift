import SwiftUI

/// Container for the four-step first-run flow. Owns an `OnboardingFlow`
/// and routes into the step-specific view. If onboarding was already
/// completed on a prior run the window auto-dismisses and — when a UI
/// test has requested it via `-CmdQGuard.showSettingsOnLaunch` — opens
/// the Settings (Control Panel) scene before closing.
struct OnboardingView: View {
    @Environment(WhitelistStore.self) private var whitelist
    @Environment(AccessibilityPermission.self) private var accessibility
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openSettings) private var openSettings

    @State private var flow = OnboardingFlow()
    @State private var apps: [InstalledApp] = []

    var body: some View {
        Group {
            switch flow.step {
            case .welcome:
                OnboardingWelcomeView(onNext: { flow.next() })
            case .accessibility:
                OnboardingAccessibilityView(accessibility: accessibility, onContinue: { flow.next() })
            case .appPicker:
                OnboardingAppPickerView(
                    flow: flow,
                    apps: apps,
                    onFinish: { flow.finish(into: whitelist) }
                )
            case .done:
                OnboardingDoneView(onDismiss: dismissSelf)
            }
        }
        .onAppear {
            if OnboardingState.isComplete {
                if UserDefaults.standard.bool(forKey: "CmdQGuard.showSettingsOnLaunch") {
                    openSettings()
                }
                dismissSelf()
                return
            }
            if apps.isEmpty {
                apps = AppInventory.scan()
            }
        }
    }

    private func dismissSelf() {
        dismissWindow(id: WindowID.onboarding.rawValue)
    }
}
