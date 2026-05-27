import SwiftUI

/// Container for the four-step first-run flow. Owns an `OnboardingFlow`
/// and routes into the step-specific view. If onboarding was already
/// completed on a prior run the window auto-dismisses; AppDelegate owns
/// opening the Control Panel for test/debug launch arguments.
struct OnboardingView: View {
    @Environment(WhitelistStore.self) private var whitelist
    @Environment(AccessibilityPermission.self) private var accessibility
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var flow = OnboardingFlow()
    @State private var apps: [InstalledApp] = []

    var body: some View {
        OnboardingShell(step: flow.step, onBack: { flow.back() }) {
            switch flow.step {
            case .welcome:
                OnboardingWelcomeView(onNext: { flow.next() })
            case .accessibility:
                OnboardingAccessibilityView(
                    accessibility: accessibility,
                    onBack: { flow.back() },
                    onContinue: { flow.next() }
                )
            case .appPicker:
                OnboardingAppPickerView(
                    flow: flow,
                    apps: apps,
                    onBack: { flow.back() },
                    onFinish: { flow.finish(into: whitelist) }
                )
            case .done:
                OnboardingDoneView(
                    selectedApps: selectedAppsForDone,
                    protectedCount: flow.selectedBundleIDs.count,
                    onBack: { flow.back() },
                    onDismiss: finishAndOpenSettings
                )
            }
        }
        .frame(width: 460, height: 540)
        .background(UnifiedWindowChromeConfigurator())
        .onAppear {
            if OnboardingState.isComplete {
                dismissSelf()
                return
            }
            if apps.isEmpty {
                let scannedApps = AppInventory.scan()
                apps = scannedApps
                AppIconView.prefetch(scannedApps, startingAt: OnboardingAppPickerView.visibleTileCount)
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

    private var selectedAppsForDone: [InstalledApp] {
        let selected = flow.selectedBundleIDs
        let selectedApps = apps.filter { selected.contains($0.bundleID) }
        return selectedApps.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

private struct OnboardingShell<Content: View>: View {
    let step: OnboardingStep
    let onBack: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            if step == .accessibility || step == .appPicker {
                stepper
            }

            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GlassWindowBackground())
    }

    private var stepper: some View {
        HStack(spacing: 18) {
            StepBubble(index: 1, title: "Accessibility", active: step == .accessibility, done: step.rawValue > OnboardingStep.accessibility.rawValue)
            StepBubble(index: 2, title: "Protected Apps", active: step == .appPicker, done: step.rawValue > OnboardingStep.appPicker.rawValue)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(GlassTitlebarBackground())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.glassDivider)
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
                    .fill(done ? Color.guardPrimaryButton : (active ? Color.glassPillBackground : Color.glassWellTop))
                    .frame(width: 22, height: 22)
                    .overlay {
                        if active && !done {
                            Circle().strokeBorder(Color.guardPrimaryButton, lineWidth: 2)
                            Circle().strokeBorder(Color.glassPillLine, lineWidth: 0.5)
                        } else if !done {
                            Circle().strokeBorder(Color.glassWellLine, lineWidth: 0.5)
                        }
                    }
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(active ? Color.inkPrimary : Color.inkTertiary)
                }
            }

            Text(title)
                .font(.system(size: 13, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? Color.inkPrimary : Color.inkTertiary)
        }
    }
}

struct GlassTitlebarBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.glassTitlebarTop,
                Color.glassTitlebarBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct OnboardingPrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 30
    var horizontalPadding: CGFloat = 18
    var minWidth: CGFloat?

    func makeBody(configuration: Configuration) -> some View {
        OnboardingPrimaryButtonBody(
            configuration: configuration,
            height: height,
            horizontalPadding: horizontalPadding,
            minWidth: minWidth
        )
    }
}

private struct OnboardingPrimaryButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let height: CGFloat
    let horizontalPadding: CGFloat
    let minWidth: CGFloat?

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .frame(minWidth: minWidth)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .background(background)
            .scaleEffect(configuration.isPressed ? 0.985 : (isHovered && isEnabled ? 1.015 : 1))
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: isEnabled)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(isHovered && isEnabled ? Color.guardAccentDeep : Color.guardPrimaryButton)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(isHovered && isEnabled ? 0.10 : 0))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(isHovered && isEnabled ? 0.18 : 0), lineWidth: 0.5)
            }
            .shadow(
                color: Color.guardPrimaryButton.opacity(isHovered && isEnabled ? 0.28 : 0.14),
                radius: isHovered && isEnabled ? 8 : 3,
                y: isHovered && isEnabled ? 4 : 2
            )
    }
}

struct OnboardingTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OnboardingTextButtonBody(configuration: configuration)
    }
}

private struct OnboardingTextButtonBody: View {
    let configuration: ButtonStyle.Configuration

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isEnabled ? (isHovered ? Color.guardAccent : Color.inkTertiary) : Color.inkQuaternary.opacity(0.55))
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isHovered && isEnabled ? Color.glassPillBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(isHovered && isEnabled ? Color.glassPillLine : Color.clear, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
