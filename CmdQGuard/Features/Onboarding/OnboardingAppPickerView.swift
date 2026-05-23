import SwiftUI

/// Step 2 of 2 — the 5-column app picker grid. Selected tiles gain an
/// Aurora-tinted background, accent border, and a checkmark badge on the
/// icon, matching the prototype's selected-state treatment.
struct OnboardingAppPickerView: View {
    let flow: OnboardingFlow
    let apps: [InstalledApp]
    let onFinish: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Step 2 of 2").stepLabelStyle().padding(.bottom, 6)

            Text("Pick what to protect")
                .font(AppTypography.title2)
                .tracking(-0.3)
                .accessibilityIdentifier("appPickerTitle")
                .padding(.bottom, 6)

            Text("Tap to toggle. Recommended apps are pre-selected.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .padding(.bottom, 18)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(orderedApps, id: \.bundleID) { app in
                        AppPickerTile(app: app, checked: flow.selectedBundleIDs.contains(app.bundleID)) {
                            flow.toggle(app.bundleID)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 240)

            Divider().padding(.top, 20)

            HStack {
                Text("\(flow.selectedBundleIDs.count) apps protected")
                    .font(AppTypography.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("appPickerCount")
                Spacer()
                Button("Clear") { flow.clearSelection() }
                    .buttonStyle(.borderless)
                finishButton.accessibilityIdentifier("finishButton")
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 32)
        .padding(.top, 28)
        .padding(.bottom, 26)
        .frame(minWidth: 460, minHeight: 458)
    }

    private var orderedApps: [InstalledApp] {
        let selected = apps.filter { flow.selectedBundleIDs.contains($0.bundleID) }
        let others = apps.filter { !flow.selectedBundleIDs.contains($0.bundleID) }
        return selected + others
    }

    @ViewBuilder
    private var finishButton: some View {
        Button(action: onFinish) {
            Text("Finish →")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 30)
                .background(Color.guardAccent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AppPickerTile: View {
    let app: InstalledApp
    let checked: Bool
    let onToggle: () -> Void

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
                    .foregroundStyle(checked ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 72)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(checked ? Color.guardAccentTint : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(checked ? Color.guardAccent : .clear, lineWidth: 1)
            )
            .opacity(checked ? 1 : 0.78)
            .animation(.easeInOut(duration: 0.12), value: checked)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("appTile_\(app.bundleID)")
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
            .overlay(Circle().stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5))
            .offset(x: 4, y: 4)
    }
}

/// Resolves and renders the real macOS app icon via NSWorkspace.
struct AppIconView: View {
    let app: InstalledApp
    let size: CGFloat

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
    }
}
