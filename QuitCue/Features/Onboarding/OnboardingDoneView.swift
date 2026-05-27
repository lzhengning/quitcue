import SwiftUI

/// Step 3 — final confirmation. Mirrors the prototype's selected-app fan
/// and Spotlight reopen hint.
struct OnboardingDoneView: View {
    let selectedApps: [InstalledApp]
    let protectedCount: Int
    let onDismiss: () -> Void

    private let fanMax = 5
    private let tileSize: CGFloat = 64
    private let iconOffset: CGFloat = 26
    private let rotationStep: Double = 3
    private let chipSize: CGFloat = 38
    private let chipGap: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            hero
                .padding(.bottom, 22)

            Text("You're on guard.")
                .font(AppTypography.title2)
                .tracking(-0.3)
                .foregroundStyle(Color.inkPrimary)
                .accessibilityIdentifier("doneTitle")
                .padding(.bottom, 6)

            bodyCopy
                .font(.system(size: 13.5))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: 340)
                .padding(.bottom, 4)

            Text("Runs silently in the background — no menu bar, no Dock.")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: 340)
                .padding(.bottom, 22)

            spotlightHint
                .padding(.bottom, 10)

            helperText
                .padding(.bottom, 24)

            doneButton
                .accessibilityIdentifier("doneCloseButton")
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 32)
        .frame(minWidth: 440, minHeight: 440)
    }

    private var displayedApps: [InstalledApp] {
        isOverflow ? Array(selectedApps.prefix(4)) : Array(selectedApps.prefix(fanMax))
    }

    private var displayedCount: Int {
        max(protectedCount, selectedApps.count)
    }

    private var isOverflow: Bool {
        displayedCount > fanMax
    }

    private var overflowCount: Int {
        max(0, displayedCount - displayedApps.count)
    }

    private var iconsWidth: CGFloat {
        tileSize + CGFloat(max(0, displayedApps.count - 1)) * iconOffset
    }

    private var stackWidth: CGFloat {
        max(tileSize, iconsWidth + (overflowCount > 0 ? chipGap + chipSize : 0))
    }

    private var haloWidth: CGFloat {
        min(260, max(180, stackWidth + 80))
    }

    private var hero: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.guardAccentTint.opacity(0.70),
                    Color.guardAccentTint.opacity(0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: haloWidth * 0.5
            )
            .frame(width: haloWidth, height: 92)

            iconFan

            checkBadge
                .offset(x: -stackWidth / 2 - 6, y: -tileSize / 2 + 15)
        }
        .frame(height: 92)
    }

    @ViewBuilder
    private var iconFan: some View {
        if displayedApps.isEmpty {
            BrandMark(size: tileSize)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 6)
        } else {
            ZStack(alignment: .leading) {
                ForEach(Array(displayedApps.enumerated()), id: \.element.bundleID) { index, app in
                    AppIconView(app: app, size: tileSize)
                        .clipShape(RoundedRectangle(cornerRadius: tileSize * 0.22, style: .continuous))
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 6)
                        .rotationEffect(.degrees(rotation(for: index)))
                        .offset(x: CGFloat(index) * iconOffset)
                        .zIndex(Double(displayedApps.count - index))
                }

                if overflowCount > 0 {
                    Text("+\(overflowCount)")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(-0.2)
                        .foregroundStyle(Color.guardAccent)
                        .frame(width: chipSize, height: chipSize)
                        .background(Color.guardAccentTint, in: Circle())
                        .overlay(Circle().strokeBorder(Color.guardAccent, lineWidth: 1))
                        .shadow(color: .black.opacity(0.10), radius: 6, y: 4)
                        .offset(x: iconsWidth + chipGap)
                        .zIndex(10)
                }
            }
            .frame(width: stackWidth, height: tileSize, alignment: .leading)
        }
    }

    private var checkBadge: some View {
        Circle()
            .fill(Color.guardProtected)
            .frame(width: 22, height: 22)
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            )
            .overlay(Circle().stroke(Color.glassShellTop, lineWidth: 2))
            .shadow(color: .black.opacity(0.20), radius: 3, y: 2)
    }

    private var bodyCopy: Text {
        if displayedCount == 1, let app = selectedApps.first {
            return Text(app.name).fontWeight(.semibold)
                + Text(" will now confirm before quitting.")
        }
        return Text("\(displayedCount) apps").fontWeight(.semibold)
            + Text(" will now confirm before quitting.")
    }

    private var spotlightHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkTertiary)
                .frame(width: 14, height: 14)

            HStack(spacing: 1) {
                Text("QuitCue")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkPrimary)
                Rectangle()
                    .fill(Color.guardAccent)
                    .frame(width: 1.5, height: 13)
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Spotlight")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.inkTertiary.opacity(0.8))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.glassWellTop, .glassWellBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.glassWellLine, lineWidth: 0.5)
        )
    }

    private var helperText: some View {
        (Text("Search ")
            + Text("QuitCue").fontWeight(.semibold)
            + Text(" in Spotlight to reopen settings."))
            .font(.system(size: 12))
            .foregroundStyle(Color.inkTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 320)
    }

    private var doneButton: some View {
        Button(action: onDismiss) {
            Text("Done")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
        .buttonStyle(OnboardingPrimaryButtonStyle(height: 32, horizontalPadding: 28, minWidth: 120))
    }

    private func rotation(for index: Int) -> Double {
        (Double(index) - Double(displayedApps.count - 1) / 2) * rotationStep
    }
}

#Preview {
    OnboardingDoneView(
        selectedApps: [],
        protectedCount: 6,
        onDismiss: {}
    )
    .frame(width: 480, height: 560)
}
