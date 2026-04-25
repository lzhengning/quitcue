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
                OnboardingDoneView(onDismiss: finishAndOpenSettings)
            }
        }
        .onAppear {
            if OnboardingState.isComplete {
                if UserDefaults.standard.bool(forKey: "CmdQGuard.showSettingsOnLaunch") {
                    // Use the SwiftUI action here because the AppKit
                    // selector (`showSettingsWindow:`) silently fails when
                    // sent before the responder chain is ready, and
                    // `onAppear` is exactly that moment. From a button
                    // action later in the lifecycle the AppKit path is
                    // safe — that's what `finishAndOpenSettings` uses.
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

    /// Called from the Done step's Close button. Hands the user off to
    /// the Control Panel so they can see their new protected-apps list
    /// and tweak the confirm method / duration.
    ///
    /// We route through the AppKit selector (`showSettingsWindow:`) rather
    /// than `@Environment(\.openSettings)` because the SwiftUI action is
    /// deprecated in macOS 14+ and emits a runtime warning telling callers
    /// to use `SettingsLink` instead — which doesn't fit a "open + then
    /// dismiss the current window" flow.
    private func finishAndOpenSettings() {
        OpenWindowBridge.openSettings()
        dismissSelf()
    }
}
