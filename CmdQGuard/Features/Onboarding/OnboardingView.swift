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
        OnboardingShell(step: flow.step, onBack: { flow.back() }) {
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
        .frame(width: 460)
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
                if flow.selectedBundleIDs.isEmpty {
                    flow.selectedBundleIDs = Set(recommendedDefaultApps(from: apps))
                }
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

    private func recommendedDefaultApps(from apps: [InstalledApp]) -> [String] {
        let preferredBundleIDs = [
            "com.apple.Safari",
            "com.apple.dt.Xcode",
            "com.microsoft.VSCode",
            "com.openai.codex",
            "com.anthropic.claudefordesktop"
        ]
        let highSignalKeywords = [
            "xcode", "code", "codex", "cursor", "zed", "terminal", "iterm",
            "warp", "docker", "figma", "sketch", "claude", "chatgpt",
            "safari", "pages", "notes", "textedit"
        ]
        var appsByBundleID: [String: InstalledApp] = [:]
        for app in apps where appsByBundleID[app.bundleID.lowercased()] == nil {
            appsByBundleID[app.bundleID.lowercased()] = app
        }
        let preferredApps = preferredBundleIDs.compactMap { appsByBundleID[$0.lowercased()] }
        let preferredIDs = Set(preferredApps.map(\.bundleID))
        let ranked = apps
            .filter { !preferredIDs.contains($0.bundleID) }
            .map { app -> (InstalledApp, Int) in
                let haystack = "\(app.bundleID) \(app.name) \(app.url.path)".lowercased()
                let score = highSignalKeywords.enumerated().reduce(0) { partial, item in
                    haystack.contains(item.element) ? partial + (highSignalKeywords.count - item.offset) : partial
                }
                return (app, score)
            }
            .filter { $0.1 > 0 }
            .sorted {
                if $0.1 == $1.1 {
                    return $0.0.name.localizedCaseInsensitiveCompare($1.0.name) == .orderedAscending
                }
                return $0.1 > $1.1
            }
            .map(\.0)

        let recommended = (preferredApps + ranked)
            .prefix(5)
            .map(\.bundleID)

        if recommended.isEmpty {
            return apps.prefix(5).map(\.bundleID)
        }
        return Array(recommended)
    }
}

private struct OnboardingShell<Content: View>: View {
    let step: OnboardingStep
    let onBack: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            titleBar

            if step == .accessibility || step == .appPicker {
                stepper
            }

            content()
        }
        .background(
            Color(red: 246/255, green: 246/255, blue: 248/255)
                .opacity(0.94)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.10), lineWidth: 0.5)
        )
    }

    private var titleBar: some View {
        ZStack {
            Text("Setup")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(height: 38)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.5))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 0.5)
        }
    }

    private var stepper: some View {
        HStack(spacing: 18) {
            StepBubble(index: 1, title: "Accessibility", active: step == .accessibility, done: step.rawValue > OnboardingStep.accessibility.rawValue)
            StepBubble(index: 2, title: "Protected apps", active: step == .appPicker, done: step.rawValue > OnboardingStep.appPicker.rawValue)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.4))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 0.5)
        }
    }
}

private struct StepBubble: View {
    let index: Int
    let title: String
    let active: Bool
    let done: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(done ? Color.guardAccent : (active ? Color.white : Color.black.opacity(0.06)))
                    .frame(width: 22, height: 22)
                    .overlay {
                        if active && !done {
                            Circle().strokeBorder(Color.guardAccent, lineWidth: 2)
                        }
                    }
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(active ? .primary : .secondary)
                }
            }

            Text(title)
                .font(.system(size: 13, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? .primary : .secondary)
        }
    }
}
