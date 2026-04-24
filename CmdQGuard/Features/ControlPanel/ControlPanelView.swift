import SwiftUI

/// Settings surface reopened via Spotlight or Cmd+Comma.
/// M5 expands the M2 stub into the full per-section layout:
/// Accessibility · Confirm Method · Protected Apps · General.
struct ControlPanelView: View {
    @Environment(WhitelistStore.self) private var whitelist
    @Environment(AccessibilityPermission.self) private var accessibility
    @Environment(ConfirmSettings.self) private var settings
    @Environment(LaunchAtLoginManager.self) private var launchAtLogin

    @State private var showingAppPicker = false
    @State private var installedApps: [InstalledApp] = []

    var body: some View {
        @Bindable var settings = settings

        Form {
            accessibilitySection

            Section("Confirm Method") {
                Picker("Method", selection: $settings.mode) {
                    Text("Hold ⌘Q").tag(ConfirmMode.hold)
                    Text("Press twice").tag(ConfirmMode.doublePress)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("confirmModePicker")

                HStack {
                    Text(settings.mode == .hold ? "Hold duration" : "Window for 2nd press")
                    Spacer()
                    Text("\(String(format: "%.1f", currentDuration(settings))) s")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("confirmDurationLabel")
                }
                Slider(
                    value: settings.mode == .hold ? $settings.holdDuration : $settings.doublePressWindow,
                    in: currentRange(for: settings.mode),
                    step: 0.1
                )
                .accessibilityIdentifier("confirmDurationSlider")
            }

            protectedAppsSection
            generalSection
        }
        .formStyle(.grouped)
        .scenePadding()
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

    private var accessibilitySection: some View {
        Section("Accessibility") {
            HStack {
                Image(systemName: accessibility.isGranted
                      ? "checkmark.circle.fill"
                      : "exclamationmark.triangle.fill")
                    .foregroundStyle(accessibility.isGranted ? .green : .orange)
                Text(accessibility.isGranted
                     ? "Accessibility: Granted"
                     : "Accessibility: Not granted")
                    .accessibilityIdentifier("accessibilityStatus")
                Spacer()
                if !accessibility.isGranted {
                    grantButton
                }
            }
        }
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
