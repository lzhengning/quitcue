import SwiftUI

/// Settings surface reopened via Spotlight or Cmd+Comma.
/// Per design canvas: identity header → Protected Apps → Confirm Method →
/// Hold Duration → General. Accessibility surfaces only as a warning row
/// when permission isn't granted; the identity header otherwise carries a
/// quiet "Accessibility on" status line so users still have a single place
/// to verify the daemon is healthy.
struct ControlPanelView: View {
    @Environment(WhitelistStore.self) private var whitelist
    @Environment(AccessibilityPermission.self) private var accessibility
    @Environment(ConfirmSettings.self) private var settings
    @Environment(LaunchAtLoginManager.self) private var launchAtLogin

    @State private var installedApps: [InstalledApp] = []
    @State private var appPickerPresentation: AppPickerPresentation?

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(spacing: 0) {
                if !accessibility.isGranted {
                    accessibilityWarningSection
                }

                protectedAppsSection

                nativeGroup("Confirm method") {
                    NativeRow {
                        Picker("Method", selection: $settings.mode) {
                            Text("Hold ⌘Q").tag(ConfirmMode.hold)
                            Text("Press ⌘Q twice").tag(ConfirmMode.doublePress)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("confirmModePicker")
                    }
                }

                nativeGroup(settings.mode == .hold ? "Hold duration" : "Window for 2nd press") {
                    NativeRow {
                        durationControl(settings: settings)
                    }
                }

                generalSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))
        .accessibilityIdentifier("accessibilityStatus")
        .onAppear {
            loadInstalledAppsIfNeeded()
        }
        .sheet(item: $appPickerPresentation) { presentation in
            AddProtectedAppSheet(
                candidates: presentation.candidates,
                onAdd: { bundleID in
                    whitelist.add(bundleID)
                    appPickerPresentation = nil
                },
                onCancel: { appPickerPresentation = nil }
            )
        }
    }

    private func nativeGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.bottom, 18)
    }

    private var nativeSeparator: some View {
        Rectangle()
            .fill(Color.black.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 40)
    }

    private struct NativeRow<Content: View>: View {
        var dense = false
        @ViewBuilder var content: () -> Content

        var body: some View {
            HStack(spacing: 10) {
                content()
            }
            .padding(.horizontal, dense ? 12 : 14)
            .padding(.vertical, dense ? 7 : 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private struct IconBubble: View {
        let systemName: String
        var body: some View {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    private var identityHeader: some View {
        HStack(spacing: 12) {
            BrandMark(size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("CmdQGuard")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.2)
                HStack(spacing: 5) {
                    Circle()
                        .fill(accessibility.isGranted ? Color.guardProtected : .orange)
                        .frame(width: 7, height: 7)
                    Text(accessibility.isGranted
                         ? guardingSummary
                         : "Accessibility: Not granted")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("accessibilityStatus")
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var guardingSummary: String {
        let n = whitelist.bundleIDs.count
        return "Guarding \(n) \(n == 1 ? "app" : "apps")"
    }

    private var accessibilityWarningSection: some View {
        nativeGroup("Accessibility") {
            NativeRow {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("CmdQGuard can't intercept ⌘Q without Accessibility access.")
                    .font(.system(size: 12))
                Spacer()
                grantButton
            }
        }
    }

    @ViewBuilder
    private func durationControl(settings: ConfirmSettings) -> some View {
        @Bindable var settings = settings
        let isHold = settings.mode == .hold

        VStack(spacing: 8) {
            HStack {
                Text(activeTickLabel(for: settings))
                    .font(.system(size: 13))
                Spacer()
                Text("\(String(format: "%.1f", currentDuration(settings))) s")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("confirmDurationLabel")
            }
            Slider(
                value: isHold ? $settings.holdDuration : $settings.doublePressWindow,
                in: currentRange(for: settings.mode),
                step: 0.1
            )
            .accessibilityIdentifier("confirmDurationSlider")

            if isHold {
                HStack {
                    ForEach(holdTicks, id: \.label) { tick in
                        let active = abs(settings.holdDuration - tick.at) < 0.25
                        Text(tick.label)
                            .font(.system(size: 11, weight: active ? .semibold : .regular))
                            .foregroundStyle(active ? Color.accentColor : .secondary)
                            .frame(maxWidth: .infinity, alignment: tick.alignment)
                    }
                }
            }
        }
    }

    private func activeTickLabel(for settings: ConfirmSettings) -> String {
        guard settings.mode == .hold else { return "Window" }
        for tick in holdTicks where abs(settings.holdDuration - tick.at) < 0.25 {
            return tick.label
        }
        return "Custom"
    }

    private var holdTicks: [HoldTick] {
        [
            HoldTick(at: 1.0, label: "Fast", alignment: .leading),
            HoldTick(at: 1.5, label: "Standard", alignment: .center),
            HoldTick(at: 2.5, label: "Safe", alignment: .trailing)
        ]
    }

    private struct HoldTick {
        let at: TimeInterval
        let label: String
        let alignment: Alignment
    }

    private var protectedAppsSection: some View {
        nativeGroup("Protected apps") {
            if whitelist.bundleIDs.isEmpty {
                Text("No protected apps yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .accessibilityIdentifier("protectedAppsEmpty")
            } else {
                ForEach(Array(whitelist.bundleIDs.enumerated()), id: \.element) { index, bundleID in
                    if index > 0 { nativeSeparator }
                    NativeRow(dense: true) {
                        ProtectedAppRow(
                            bundleID: bundleID,
                            installed: installedApps.first(where: { $0.bundleID == bundleID }),
                            onRemove: { whitelist.remove(bundleID) }
                        )
                    }
                }
            }

            nativeSeparator

            Button {
                presentAppPicker()
            } label: {
                NativeRow(dense: true) {
                    IconBubble(systemName: "plus")
                    Text("Add app…")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.accentColor)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("addProtectedAppButton")
        }
    }

    private var generalSection: some View {
        nativeGroup("General") {
            NativeRow {
                Text("Launch at login")
                    .font(.system(size: 13))
                Spacer()
                PillToggle(
                    isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                )
                )
                .accessibilityIdentifier("launchAtLoginToggle")
            }

            nativeSeparator

            NativeRow {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Ghost mode")
                        .font(.system(size: 13))
                    Text("Hide menu bar icon and Dock tile")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                PillToggle(isOn: .constant(false))
                    .disabled(true)
                    .opacity(0.45)
            }

            if let error = launchAtLogin.lastError {
                nativeSeparator
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private var grantButton: some View {
        let button = Button("Grant…") { accessibility.requestIfNeeded() }
        if #available(macOS 26, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }

    private func currentDuration(_ settings: ConfirmSettings) -> TimeInterval {
        settings.mode == .hold ? settings.holdDuration : settings.doublePressWindow
    }

    private func currentRange(for mode: ConfirmMode) -> ClosedRange<TimeInterval> {
        mode == .hold ? ConfirmSettings.holdDurationRange : ConfirmSettings.doublePressWindowRange
    }

    @discardableResult
    private func loadInstalledAppsIfNeeded() -> [InstalledApp] {
        guard installedApps.isEmpty else { return installedApps }
        installedApps = AppInventory.scan()
        return installedApps
    }

    private func presentAppPicker() {
        let apps = loadInstalledAppsIfNeeded()
        let candidates = apps.filter { !whitelist.contains($0.bundleID) }
        appPickerPresentation = AppPickerPresentation(candidates: candidates)
    }

    private struct AppPickerPresentation: Identifiable {
        let id = UUID()
        let candidates: [InstalledApp]
    }
}

private struct ProtectedAppRow: View {
    let bundleID: String
    let installed: InstalledApp?
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let installed {
                AppIconView(app: installed, size: 22)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
            }

            Text(installed?.name ?? bundleID)
                .font(.system(size: 13))
                .lineLimit(1)
                .accessibilityIdentifier("whitelistRow_\(bundleID)")

            Spacer()

            Button {
                onRemove()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(Color.black.opacity(0.06), in: Circle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove \(installed?.name ?? bundleID)")
            .accessibilityIdentifier("removeProtectedApp_\(bundleID)")
        }
    }
}

private struct AddProtectedAppSheet: View {
    let candidates: [InstalledApp]
    let onAdd: (String) -> Void
    let onCancel: () -> Void

    @State private var filter: String = ""

    private var filtered: [InstalledApp] {
        guard !filter.isEmpty else { return candidates }
        return candidates.filter { $0.name.localizedCaseInsensitiveContains(filter) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Add protected app")
                    .font(.title3).fontWeight(.semibold)
                Spacer()
                Button("Cancel", action: onCancel)
            }

            TextField("Search", text: $filter)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("addProtectedAppSearch")

            ScrollView {
                LazyVStack(spacing: 0) {
                    if filtered.isEmpty {
                        Text("No apps found.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else {
                        ForEach(filtered, id: \.bundleID) { app in
                            Button {
                                onAdd(app.bundleID)
                            } label: {
                                HStack(spacing: 10) {
                                    AppIconView(app: app, size: 28)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(app.name).font(.system(size: 13, weight: .medium))
                                        Text(app.bundleID).font(.caption.monospaced()).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 7)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addCandidate_\(app.bundleID)")

                            Divider()
                        }
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(20)
        .frame(minWidth: 460, minHeight: 440)
    }
}

#Preview {
    ControlPanelView()
        .environment(WhitelistStore())
        .environment(AccessibilityPermission())
        .environment(ConfirmSettings())
        .environment(LaunchAtLoginManager(backend: SMAppServiceBackend()))
        .frame(width: 540, height: 620)
}
