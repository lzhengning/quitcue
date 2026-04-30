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

    @State private var showingAppPicker = false
    @State private var installedApps: [InstalledApp] = []

    var body: some View {
        @Bindable var settings = settings

        VStack(spacing: 0) {
            identityHeader
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 8)

            Form {
                if !accessibility.isGranted {
                    accessibilityWarningSection
                }

                protectedAppsSection

                Section("Confirm Method") {
                    Picker("Method", selection: $settings.mode) {
                        Text("Hold ⌘Q").tag(ConfirmMode.hold)
                        Text("Press ⌘Q twice").tag(ConfirmMode.doublePress)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("confirmModePicker")
                }

                Section(settings.mode == .hold ? "Hold Duration" : "Window for 2nd Press") {
                    durationControl(settings: settings)
                }

                generalSection
            }
            .formStyle(.grouped)
        }
        .onAppear {
            if installedApps.isEmpty { installedApps = AppInventory.scan() }
        }
        .sheet(isPresented: $showingAppPicker) {
            AddProtectedAppSheet(
                candidates: installedApps.filter { !whitelist.contains($0.bundleID) },
                onAdd: { bundleID in
                    whitelist.add(bundleID)
                    showingAppPicker = false
                },
                onCancel: { showingAppPicker = false }
            )
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
        Section {
            HStack {
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
        Section {
            if whitelist.bundleIDs.isEmpty {
                Text("No protected apps yet.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("protectedAppsEmpty")
            } else {
                ForEach(whitelist.bundleIDs, id: \.self) { bundleID in
                    ProtectedAppRow(
                        bundleID: bundleID,
                        installed: installedApps.first(where: { $0.bundleID == bundleID }),
                        onRemove: { whitelist.remove(bundleID) }
                    )
                }
            }
        } header: {
            HStack {
                Text("Protected Apps")
                Spacer()
                Button {
                    showingAppPicker = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("addProtectedAppButton")
            }
        }
    }

    private var generalSection: some View {
        Section("General") {
            Toggle(
                "Launch at login",
                isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                )
            )
            .accessibilityIdentifier("launchAtLoginToggle")

            if let error = launchAtLogin.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
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
}

private struct ProtectedAppRow: View {
    let bundleID: String
    let installed: InstalledApp?
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let installed {
                AppIconView(app: installed, size: 24)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(installed?.name ?? bundleID)
                    .font(.system(size: 13, weight: .medium))
                Text(bundleID)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("whitelistRow_\(bundleID)")
            }

            Spacer()

            Button {
                onRemove()
            } label: {
                Label("Remove", systemImage: "minus.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.red)
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

            List(filtered, id: \.bundleID) { app in
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
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("addCandidate_\(app.bundleID)")
            }
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
