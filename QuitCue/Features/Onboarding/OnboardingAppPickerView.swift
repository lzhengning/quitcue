import SwiftUI

/// Step 2 of 2 — the 5-column app picker grid. Selected tiles gain an
/// Aurora-tinted background, accent border, and a checkmark badge on the
/// icon, matching the prototype's selected-state treatment.
struct OnboardingAppPickerView: View {
    let flow: OnboardingFlow
    let apps: [InstalledApp]
    let onBack: () -> Void
    let onFinish: () -> Void

    static let visibleTileCount = 20

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    @State private var typeAheadLocator = AppTypeAheadLocator()
    @State private var locatedBundleID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Step 2 of 2").stepLabelStyle().padding(.bottom, 6)

            Text("Pick What to Protect")
                .font(AppTypography.title2)
                .tracking(-0.3)
                .foregroundStyle(Color.inkPrimary)
                .accessibilityIdentifier("appPickerTitle")
                .padding(.bottom, 6)

            Text("Recommended apps are pre-selected.")
                .font(AppTypography.body)
                .foregroundStyle(Color.inkTertiary)
                .padding(.bottom, 14)

            HStack(alignment: .firstTextBaseline) {
                Text("\(flow.selectedBundleIDs.count) of \(apps.count) selected")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkTertiary)
                    .accessibilityIdentifier("appPickerSelectedSummary")
                Spacer()
                Button(selectAllTitle, action: toggleAll)
                    .buttonStyle(OnboardingInlineLinkButtonStyle())
                    .accessibilityIdentifier("appPickerSelectAllButton")
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 8)

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(orderedApps, id: \.bundleID) { app in
                            AppPickerTile(
                                app: app,
                                checked: flow.selectedBundleIDs.contains(app.bundleID),
                                located: locatedBundleID == app.bundleID
                            ) {
                                flow.toggle(app.bundleID)
                            }
                            .id(app.bundleID)
                        }
                    }
                    .padding(.vertical, 4)
                    .background(OverlayScrollerConfigurator())
                }
                .onChange(of: locatedBundleID) { _, bundleID in
                    guard let bundleID else { return }
                    withAnimation(.easeInOut(duration: 0.16)) {
                        proxy.scrollTo(bundleID, anchor: .center)
                    }
                }
            }
            .frame(minHeight: 240)

            Divider().padding(.top, 20)

            HStack {
                Text("\(flow.selectedBundleIDs.count) apps protected")
                    .font(AppTypography.footnote)
                    .foregroundStyle(Color.inkTertiary)
                    .accessibilityIdentifier("appPickerCount")
                Spacer()
                Button("← Back", action: onBack)
                    .buttonStyle(OnboardingTextButtonStyle())
                    .accessibilityIdentifier("appPickerBackButton")
                Button("Clear") { flow.clearSelection() }
                    .buttonStyle(OnboardingTextButtonStyle())
                finishButton
                    .disabled(flow.selectedBundleIDs.isEmpty)
                    .accessibilityIdentifier("finishButton")
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 32)
        .padding(.top, 28)
        .padding(.bottom, 26)
        .frame(minWidth: 460, minHeight: 458)
        .onTypeAheadCharacter(handleTypeAheadCharacter)
    }

    private var orderedApps: [InstalledApp] {
        let selected = apps.filter { flow.selectedBundleIDs.contains($0.bundleID) }
        let others = apps.filter { !flow.selectedBundleIDs.contains($0.bundleID) }
        return selected + others
    }

    private var selectAllTitle: String {
        guard !apps.isEmpty else { return "Select All" }
        return apps.allSatisfy { flow.selectedBundleIDs.contains($0.bundleID) } ? "Deselect All" : "Select All"
    }

    private func toggleAll() {
        guard !apps.isEmpty else { return }
        if apps.allSatisfy({ flow.selectedBundleIDs.contains($0.bundleID) }) {
            flow.clearSelection()
        } else {
            flow.selectAll(apps.map(\.bundleID))
        }
    }

    private func handleTypeAheadCharacter(_ character: String) -> Bool {
        guard let match = typeAheadLocator.locate(
            typedCharacter: character,
            in: orderedApps,
            currentBundleID: locatedBundleID
        ) else {
            return false
        }

        locatedBundleID = match.bundleID
        clearLocatedBundleID(after: match.bundleID)
        return true
    }

    private func clearLocatedBundleID(after bundleID: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard locatedBundleID == bundleID else { return }
            locatedBundleID = nil
        }
    }

    @ViewBuilder
    private var finishButton: some View {
        Button(action: onFinish) {
            Text("Finish →")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
        .buttonStyle(OnboardingPrimaryButtonStyle())
    }
}

struct OnboardingInlineLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OnboardingInlineLinkButtonBody(configuration: configuration)
    }
}

private struct OnboardingInlineLinkButtonBody: View {
    let configuration: ButtonStyle.Configuration
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isHovered ? Color.guardAccentDeep : Color.guardAccent)
            .underline(isHovered, color: Color.guardAccent)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

private struct AppPickerTile: View {
    let app: InstalledApp
    let checked: Bool
    let located: Bool
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    AppIconView(app: app, size: 36)
                    if checked { checkmarkBadge }
                }
                Text(app.name)
                    .font(AppTypography.tileLabel)
                    .fontWeight(checked ? .semibold : .regular)
                    .foregroundStyle(checked ? Color.inkPrimary : Color.inkSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 72)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tileFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(tileStroke, lineWidth: checked ? 1 : 0.5)
            )
            .shadow(color: tileShadow, radius: isHovered || located ? 7 : 0, y: isHovered || located ? 3 : 0)
            .opacity(checked || isHovered || located ? 1 : 0.78)
            .scaleEffect(isHovered ? 1.015 : located ? 1.01 : 1)
            .animation(.easeInOut(duration: 0.12), value: checked)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.12), value: located)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onHover { isHovered = $0 }
        .accessibilityIdentifier("appTile_\(app.bundleID)")
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
            .frame(width: 14, height: 14)
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            )
            .overlay(Circle().stroke(Color.glassBadgeStroke, lineWidth: 1.5))
            .offset(x: 4, y: 4)
    }
}
