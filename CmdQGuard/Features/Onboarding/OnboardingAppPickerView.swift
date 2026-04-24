import SwiftUI

/// Step 2 of 2 — the 5-column app picker grid. Each tile is a toggle
/// button with the app icon + name. M6 will layer recommended categories
/// on top of this raw `AppInventory` list.
struct OnboardingAppPickerView: View {
    let flow: OnboardingFlow
    let apps: [InstalledApp]
    let onFinish: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("STEP 2 OF 2")
                .font(.system(size: 11))
                .tracking(1)
                .foregroundStyle(.secondary)

            Text("Pick what to protect")
                .font(.system(size: 20, weight: .semibold))
                .accessibilityIdentifier("appPickerTitle")

            Text("Tap to toggle.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(orderedApps, id: \.bundleID) { app in
                        tile(for: app)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 280)

            footer
        }
        .padding(28)
        .frame(minWidth: 480, minHeight: 520)
    }

    /// Selected first (alphabetized), then the rest (alphabetized).
    private var orderedApps: [InstalledApp] {
        let selected = apps.filter { flow.selectedBundleIDs.contains($0.bundleID) }
        let others = apps.filter { !flow.selectedBundleIDs.contains($0.bundleID) }
        return selected + others
    }

    private func tile(for app: InstalledApp) -> some View {
        let checked = flow.selectedBundleIDs.contains(app.bundleID)
        return Button {
            flow.toggle(app.bundleID)
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    AppIconView(app: app, size: 36)
                    if checked {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .overlay(Circle().stroke(Color(nsColor: .controlBackgroundColor), lineWidth: 1.5))
                            .offset(x: 4, y: 4)
                    }
                }
                Text(app.name)
                    .font(.system(size: 10.5, weight: checked ? .semibold : .regular))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 72)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(checked ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(checked ? Color.accentColor : .clear, lineWidth: 1)
            )
            .opacity(checked ? 1 : 0.78)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("appTile_\(app.bundleID)")
    }

    private var footer: some View {
        HStack {
            Text("\(flow.selectedBundleIDs.count) apps protected")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("appPickerCount")
            Spacer()
            Button("Clear") { flow.clearSelection() }
                .buttonStyle(.borderless)
            finishButton
                .accessibilityIdentifier("finishButton")
        }
        .padding(.top, 14)
        .overlay(Divider(), alignment: .top)
    }

    @ViewBuilder
    private var finishButton: some View {
        let button = Button("Finish →") { onFinish() }
        if #available(macOS 26, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
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
