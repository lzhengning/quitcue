import AppKit
import SwiftUI

enum ControlPanelMetrics {
    static let width: CGFloat = 520
}

struct ProtectedAppTileModel: Equatable, Identifiable {
    let bundleID: String
    let name: String
    let app: InstalledApp?

    var id: String { bundleID }

    init(app: InstalledApp) {
        self.bundleID = app.bundleID
        self.name = app.name
        self.app = app
    }

    init(bundleID: String) {
        self.bundleID = bundleID
        self.name = bundleID.split(separator: ".").last.map(String.init) ?? bundleID
        self.app = nil
    }
}

extension ProtectedAppTileModel: AppTypeAheadLocatable {}

enum ProtectedAppTileOrdering {
    static func orderedTiles(
        selectedBundleIDs: [String],
        installedApps: [InstalledApp]
    ) -> [ProtectedAppTileModel] {
        var byBundleID: [String: InstalledApp] = [:]
        for app in installedApps where byBundleID[app.bundleID] == nil {
            byBundleID[app.bundleID] = app
        }

        let selectedTiles = selectedBundleIDs
            .map { bundleID -> ProtectedAppTileModel in
                if let installed = byBundleID[bundleID] {
                    return ProtectedAppTileModel(app: installed)
                }
                return ProtectedAppTileModel(bundleID: bundleID)
            }
            .sorted(by: areInDisplayNameOrder)

        let selectedSet = Set(selectedBundleIDs)
        let remainingTiles = installedApps
            .filter { !selectedSet.contains($0.bundleID) }
            .map(ProtectedAppTileModel.init(app:))
            .sorted(by: areInDisplayNameOrder)

        return selectedTiles + remainingTiles
    }

    private static func areInDisplayNameOrder(
        _ lhs: ProtectedAppTileModel,
        _ rhs: ProtectedAppTileModel
    ) -> Bool {
        switch lhs.name.localizedCaseInsensitiveCompare(rhs.name) {
        case .orderedAscending:
            return true
        case .orderedDescending:
            return false
        case .orderedSame:
            return lhs.bundleID.localizedCaseInsensitiveCompare(rhs.bundleID) == .orderedAscending
        }
    }
}

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

    @State private var appInventory: AppInventorySnapshot
    @State private var protectedAppsTypeAheadLocator = AppTypeAheadLocator()
    @State private var locatedProtectedAppBundleID: String?
    private let onQuitCueEnabledChange: @MainActor (Bool) -> Void
    private let protectedAppsColumnCount = 5
    private let protectedAppsRowHeight: CGFloat = 70
    private let protectedAppsColumnSpacing: CGFloat = 6
    private let protectedAppsRowSpacing: CGFloat = 6
    private let protectedAppsMaxFullRows = 4
    private let protectedAppsScrollableRows: CGFloat = 4.25

    private var protectedAppsVisibleTileCount: Int {
        protectedAppsColumnCount * protectedAppsMaxFullRows
    }

    init(
        installedApps: [InstalledApp] = [],
        appScanner: @escaping () -> [InstalledApp] = { AppInventory.scan() },
        onQuitCueEnabledChange: @escaping @MainActor (Bool) -> Void = { _ in }
    ) {
        _appInventory = State(initialValue: AppInventorySnapshot(apps: installedApps, scanner: appScanner))
        self.onQuitCueEnabledChange = onQuitCueEnabledChange
    }

    private var installedApps: [InstalledApp] { appInventory.apps }

    var body: some View {
        @Bindable var settings = settings

        VStack(spacing: 0) {
            if !accessibility.isGranted {
                accessibilityWarningSection
            }

            protectedAppsSection

            nativeGroup("Confirm Method") {
                confirmModeControl(settings: settings)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                nativeSeparator

                durationControl(settings: settings)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
            }

            generalSection
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .frame(width: ControlPanelMetrics.width, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .background(GlassWindowBackground())
        .background(UnifiedWindowChromeConfigurator())
        .accessibilityIdentifier("accessibilityStatus")
        .onTypeAheadCharacter(handleProtectedAppsTypeAheadCharacter)
        .onAppear {
            refreshInstalledApps()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshInstalledApps()
        }
    }

    private func nativeGroup<Content: View, Action: View>(
        _ title: String,
        @ViewBuilder action: () -> Action,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkTertiary)
                Spacer(minLength: 8)
                action()
            }
            .padding(.horizontal, 14)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.glassGroupTop,
                                Color.glassGroupBottom
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.glassGroupInnerHighlight, lineWidth: 0.5)
                    .blendMode(.screen)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.glassGroupLine, lineWidth: 0.5)
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.glassGroupTopHighlight)
                    .frame(height: 1)
                    .blendMode(.screen)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.glassGroupBottomShade)
                    .frame(height: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        }
        .padding(.bottom, 18)
    }

    private func nativeGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        nativeGroup(title, action: { EmptyView() }, content: content)
    }

    private var nativeSeparator: some View {
        Rectangle()
            .fill(Color.glassDivider)
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

    private var identityHeader: some View {
        HStack(spacing: 12) {
            BrandMark(size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("QuitCue")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.2)
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusDotColor)
                        .frame(width: 7, height: 7)
                    Text(statusSummary)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkTertiary)
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

    private var statusDotColor: Color {
        if !settings.isEnabled { return Color.inkQuaternary }
        return accessibility.isGranted ? Color.guardProtected : .orange
    }

    private var statusSummary: String {
        if !settings.isEnabled { return "QuitCue disabled" }
        return accessibility.isGranted ? guardingSummary : "Accessibility: Not granted"
    }

    private var accessibilityWarningSection: some View {
        nativeGroup("Accessibility") {
            NativeRow {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("QuitCue can't intercept ⌘Q without Accessibility access.")
                    .font(.system(size: 12))
                Spacer()
                grantButton
            }
        }
    }

    private func confirmModeControl(settings: ConfirmSettings) -> some View {
        @Bindable var settings = settings

        return HStack(spacing: 2) {
            confirmModeButton(
                title: "Hold ⌘Q",
                mode: .hold,
                selection: $settings.mode
            )
            confirmModeButton(
                title: "Press ⌘Q twice",
                mode: .doublePress,
                selection: $settings.mode
            )
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.glassWellTop,
                            Color.glassWellBottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.glassWellLine, lineWidth: 0.5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("confirmModePicker")
    }

    private func confirmModeButton(
        title: String,
        mode: ConfirmMode,
        selection: Binding<ConfirmMode>
    ) -> some View {
        let isSelected = selection.wrappedValue == mode

        return Button {
            selection.wrappedValue = mode
        } label: {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.white : Color.inkTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.guardPrimaryButton : Color.clear)
                )
                .shadow(
                    color: isSelected ? Color.guardPrimaryButton.opacity(0.25) : Color.clear,
                    radius: 2,
                    y: 1
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isSelected ? Color.white.opacity(0.2) : Color.clear, lineWidth: 0.5)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private func durationControl(settings: ConfirmSettings) -> some View {
        @Bindable var settings = settings
        let isHold = settings.mode == .hold

        VStack(spacing: 12) {
            HStack {
                Text(isHold ? "Hold Duration" : "Press Window")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkTertiary)
                Spacer()
                Text("\(String(format: "%.1f", currentDuration(settings)))s")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.glassPillBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.glassPillLine, lineWidth: 0.5)
                    )
                    .accessibilityIdentifier("confirmDurationLabel")
            }
            Slider(
                value: isHold ? $settings.holdDuration : $settings.doublePressWindow,
                in: currentRange(for: settings.mode),
                step: 0.1
            )
            .tint(.guardPrimaryButton)
            .accessibilityIdentifier("confirmDurationSlider")

        }
    }

    private var protectedAppsSection: some View {
        nativeGroup("Protected Apps") {
            NativeHeaderLink(selectAllTitle) {
                toggleAllProtectedApps()
            }
            .accessibilityIdentifier("protectedAppsSelectAllButton")
        } content: {
            let tiles = orderedProtectedAppTiles

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: protectedAppColumns, spacing: protectedAppsRowSpacing) {
                        ForEach(tiles) { tile in
                            ProtectedAppTile(
                                tile: tile,
                                checked: whitelist.contains(tile.bundleID),
                                located: locatedProtectedAppBundleID == tile.bundleID,
                                rowHeight: protectedAppsRowHeight,
                                onToggle: {
                                    if whitelist.contains(tile.bundleID) {
                                        whitelist.remove(tile.bundleID)
                                    } else {
                                        whitelist.add(tile.bundleID)
                                    }
                                }
                            )
                            .id(tile.bundleID)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 12)
                    .padding(.bottom, whitelist.bundleIDs.isEmpty ? 6 : 10)
                    .background(OverlayScrollerConfigurator())
                }
                .onChange(of: locatedProtectedAppBundleID) { _, bundleID in
                    guard let bundleID else { return }
                    withAnimation(.easeInOut(duration: 0.16)) {
                        proxy.scrollTo(bundleID, anchor: .center)
                    }
                }
            }
            .frame(height: protectedAppsGridHeight(for: tiles.count))

            if whitelist.bundleIDs.isEmpty {
                Text("Tap an app to start protecting it.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
                    .accessibilityIdentifier("protectedAppsEmpty")
            }
        }
    }

    private var selectAllTitle: String {
        let tiles = orderedProtectedAppTiles
        guard !tiles.isEmpty else { return "Select All" }
        return tiles.allSatisfy { whitelist.contains($0.bundleID) } ? "Deselect All" : "Select All"
    }

    private func toggleAllProtectedApps() {
        let tiles = orderedProtectedAppTiles
        guard !tiles.isEmpty else { return }

        let shouldDeselect = tiles.allSatisfy { whitelist.contains($0.bundleID) }
        for bundleID in Array(whitelist.bundleIDs) {
            whitelist.remove(bundleID)
        }
        guard !shouldDeselect else { return }
        for tile in tiles {
            whitelist.add(tile.bundleID)
        }
    }

    private func handleProtectedAppsTypeAheadCharacter(_ character: String) -> Bool {
        guard let match = protectedAppsTypeAheadLocator.locate(
            typedCharacter: character,
            in: orderedProtectedAppTiles,
            currentBundleID: locatedProtectedAppBundleID
        ) else {
            return false
        }

        locatedProtectedAppBundleID = match.bundleID
        clearLocatedProtectedAppBundleID(after: match.bundleID)
        return true
    }

    private func clearLocatedProtectedAppBundleID(after bundleID: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard locatedProtectedAppBundleID == bundleID else { return }
            locatedProtectedAppBundleID = nil
        }
    }

    private var protectedAppColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: protectedAppsColumnSpacing), count: protectedAppsColumnCount)
    }

    private func protectedAppsGridHeight(for count: Int) -> CGFloat {
        guard count > 0 else { return 0 }

        let rows = Int(ceil(Double(count) / Double(protectedAppsColumnCount)))
        if rows <= protectedAppsMaxFullRows {
            return CGFloat(rows) * protectedAppsRowHeight
                + CGFloat(max(rows - 1, 0)) * protectedAppsRowSpacing
                + 22
        }

        return protectedAppsScrollableRows * protectedAppsRowHeight
            + CGFloat(protectedAppsMaxFullRows) * protectedAppsRowSpacing
            + 22
    }

    private var orderedProtectedAppTiles: [ProtectedAppTileModel] {
        ProtectedAppTileOrdering.orderedTiles(
            selectedBundleIDs: whitelist.bundleIDs,
            installedApps: installedApps
        )
    }

    private struct ProtectedAppTile: View {
        let tile: ProtectedAppTileModel
        let checked: Bool
        let located: Bool
        let rowHeight: CGFloat
        let onToggle: () -> Void

        @State private var isHovered = false

        var body: some View {
            Button(action: onToggle) {
                VStack(spacing: 6) {
                    ZStack(alignment: .bottomTrailing) {
                        if let app = tile.app {
                            AppIconView(app: app, size: 32)
                        } else {
                            Image(systemName: "app.dashed")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.inkTertiary)
                                .frame(width: 32, height: 32)
                        }

                        if checked {
                            checkmarkBadge
                        }
                    }

                    Text(tile.name)
                        .font(AppTypography.tileLabel)
                        .fontWeight(checked ? .semibold : .regular)
                        .foregroundStyle(checked ? Color.inkPrimary : Color.inkSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 72)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
                .frame(height: rowHeight)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tileFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(tileStroke, lineWidth: checked ? 1 : 0.5)
                )
                .shadow(color: tileShadow, radius: isHovered || located ? 7 : 0, y: isHovered || located ? 3 : 0)
                .opacity(checked || isHovered || located ? 1 : 0.7)
                .scaleEffect(isHovered ? 1.015 : located ? 1.01 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            .accessibilityIdentifier(checked ? "whitelistRow_\(tile.bundleID)" : "appTile_\(tile.bundleID)")
            .accessibilityLabel(checked ? "Stop protecting \(tile.name)" : "Protect \(tile.name)")
            .animation(.easeInOut(duration: 0.12), value: checked)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.12), value: located)
        }

        private var tileFill: Color {
            if checked {
                return Color.guardAccentTint
            }
            return isHovered || located ? Color.glassPillBackground : Color.clear
        }

        private var tileStroke: Color {
            if checked {
                return isHovered ? Color.guardAccent.opacity(0.9) : Color.guardAccent
            }
            if located {
                return Color.guardAccent.opacity(0.75)
            }
            return isHovered ? Color.glassPillLine : Color.clear
        }

        private var tileShadow: Color {
            if located {
                return Color.guardAccent.opacity(0.14)
            }
            if checked {
                return Color.guardAccent.opacity(isHovered ? 0.18 : 0)
            }
            return Color.black.opacity(isHovered ? 0.06 : 0)
        }

        private var checkmarkBadge: some View {
            Circle()
                .fill(Color.guardAccent)
                .frame(width: 15, height: 15)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                )
                .overlay(Circle().stroke(Color.glassBadgeStroke, lineWidth: 1.5))
                .offset(x: 4, y: 4)
        }
    }

    private var generalSection: some View {
        @Bindable var settings = settings

        return nativeGroup("General") {
            NativeRow {
                Text("Enable QuitCue")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
                PillToggle(isOn: $settings.isEnabled)
                    .accessibilityLabel("Enable QuitCue")
                    .accessibilityIdentifier("enableQuitCueToggle")
                    .onChange(of: settings.isEnabled) { _, isEnabled in
                        onQuitCueEnabledChange(isEnabled)
                    }
            }

            nativeSeparator

            NativeRow {
                Text("Launch at Login")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
                PillToggle(
                    isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                )
                )
                .accessibilityLabel("Launch at Login")
                .accessibilityIdentifier("launchAtLoginToggle")
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

    private func refreshInstalledApps() {
        let apps = appInventory.refresh()
        AppIconView.prefetch(apps, startingAt: protectedAppsVisibleTileCount)
    }

}

private struct NativeHeaderLink: View {
    let title: String
    let action: () -> Void
    @State private var isHovered = false

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isHovered ? Color.guardAccentDeep : Color.guardAccent)
                .underline(isHovered, color: Color.guardAccent)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    ControlPanelView()
        .environment(WhitelistStore())
        .environment(AccessibilityPermission())
        .environment(ConfirmSettings())
        .environment(LaunchAtLoginManager(backend: SMAppServiceBackend()))
}

enum UnifiedWindowChrome {
    private static let titleViewIdentifier = NSUserInterfaceItemIdentifier("QuitCueUnifiedTitleView")
    private static let titleBackgroundIdentifier = NSUserInterfaceItemIdentifier("QuitCueUnifiedTitleBackground")

    @MainActor
    static func apply(to window: NSWindow?, title: String = "QuitCue") {
        guard let window else { return }

        window.title = title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.backgroundColor = windowBaseColor()
        window.isOpaque = false
        if #available(macOS 11.0, *) {
            window.titlebarSeparatorStyle = .none
        }
        installTitlebarBackground(in: window)
        installCenteredTitle(in: window, title: title)
    }

    @MainActor
    private static func installTitlebarBackground(in window: NSWindow) {
        guard let titlebarView = window.standardWindowButton(.closeButton)?.superview else { return }

        titlebarView.subviews
            .filter { $0.identifier == titleBackgroundIdentifier }
            .forEach { $0.removeFromSuperview() }

        let backgroundView = DraggableTitlebarHostingView(rootView: TitlebarBackground())
        backgroundView.identifier = titleBackgroundIdentifier
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        titlebarView.addSubview(backgroundView, positioned: .below, relativeTo: titlebarView.subviews.first)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: titlebarView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: titlebarView.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: titlebarView.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: titlebarView.bottomAnchor)
        ])
    }

    @MainActor
    private static func installCenteredTitle(in window: NSWindow, title: String) {
        guard let titlebarView = window.standardWindowButton(.closeButton)?.superview else { return }

        titlebarView.subviews
            .filter { $0.identifier == titleViewIdentifier }
            .forEach { $0.removeFromSuperview() }

        let hostingView = DraggableTitlebarHostingView(rootView: TitlebarIdentity(title: title))
        hostingView.identifier = titleViewIdentifier
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.setContentHuggingPriority(.required, for: .horizontal)
        hostingView.setContentCompressionResistancePriority(.required, for: .horizontal)

        titlebarView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.centerXAnchor.constraint(equalTo: titlebarView.centerXAnchor),
            hostingView.centerYAnchor.constraint(equalTo: titlebarView.centerYAnchor)
        ])
    }

    private static func windowBaseColor() -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if isDark {
                return NSColor(calibratedRed: 26/255, green: 26/255, blue: 29/255, alpha: 1)
            }
            return NSColor(calibratedRed: 240/255, green: 238/255, blue: 233/255, alpha: 1)
        }
    }

    private struct TitlebarIdentity: View {
        let title: String

        var body: some View {
            HStack(spacing: 6) {
                BrandMark(size: 16, shadow: false)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkPrimary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private struct TitlebarBackground: View {
        var body: some View {
            ZStack {
                GlassWindowBackground()
                GlassTitlebarBackground()
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.glassTitlebarLine)
                    .frame(height: 0.5)
            }
        }
    }
}

private final class DraggableTitlebarHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { true }
}

struct UnifiedWindowChromeConfigurator: NSViewRepresentable {
    var title = "QuitCue"

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            UnifiedWindowChrome.apply(to: view.window, title: title)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            UnifiedWindowChrome.apply(to: nsView.window, title: title)
        }
    }
}
