import SwiftUI

/// Aurora Halo overlay — the floating glass card that appears when an
/// intercepted ⌘Q needs confirmation. Two visual modes per the approved
/// "Aurora Halo" prototype (hue 272°):
///
/// - `.hold`: halo intensifies with progress (commitment rising).
/// - `.doublePress`: halo starts soft, then softly shrinks + fades as the
///   window elapses. In the last 35 % of the window the whole card dissolves.
struct AuroraHaloView: View {
    let mode: ConfirmMode
    /// 0...1 — time elapsed in the current confirm window.
    let progress: Double
    let appName: String
    /// Optional bundle ID so the hero can load the real app icon.
    var bundleID: String? = nil

    var body: some View {
        let isDouble = mode == .doublePress
        let remain = max(0, 1 - progress)

        let haloAlpha: Double = isDouble ? 0.22 * remain : progress * 0.4
        let haloSize: CGFloat = isDouble ? 30 + 45 * remain : 40 + progress * 80
        let cardOpacity: Double = isDouble
            ? (progress < 0.65 ? 1 : max(0, (1 - progress) / 0.35))
            : 1
        let cardScale: Double = isDouble ? 1 - progress * 0.03 : 1

        VStack(spacing: 0) {
            heroIcon(isDouble: isDouble, remain: remain, progress: progress)
                .padding(.top, 28)

            Text(isDouble ? "Press ⌘Q again" : "Hold ⌘Q to quit")
                .font(AppTypography.title3)
                .tracking(-0.2)
                .foregroundStyle(.white)
                .padding(.top, 20)
                .accessibilityIdentifier("overlayTitle")

            Text(isDouble ? "Or let it fade" : "Release to cancel")
                .font(AppTypography.caption)
                .foregroundStyle(.white.opacity(0.45))
                .padding(.top, 6)

            Text(appName)
                .font(AppTypography.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 14)
                .accessibilityIdentifier("overlayAppName")

            protectedBadge
                .padding(.top, 16)
                .padding(.bottom, 18)
        }
        .frame(width: 320)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.overlayCardBase.opacity(0.6))
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 20)
        .shadow(color: Color.auroraHalo.opacity(haloAlpha), radius: haloSize)
        .opacity(cardOpacity)
        .scaleEffect(cardScale)
        .animation(.easeOut(duration: 0.2), value: cardOpacity)
        .animation(.easeOut(duration: 0.2), value: cardScale)
    }

    @ViewBuilder
    private func heroIcon(isDouble: Bool, remain: Double, progress: Double) -> some View {
        let iconOpacity: Double = isDouble ? 0.6 + 0.4 * remain : 1.0
        AppIconHero(
            bundleID: bundleID,
            progress: isDouble ? 0.2 * remain : progress,
            size: 88
        )
        .opacity(iconOpacity)
    }

    private var protectedBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hue: 272/360, saturation: 0.56, brightness: 0.70),
                            Color(hue: 272/360, saturation: 0.60, brightness: 0.50)
                        ],
                        center: .center
                    )
                )
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.overlayCardBase.opacity(0.6), lineWidth: 1.5))
            Text("Protected by CmdQGuard")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(0.3)
        }
        .padding(.top, 12)
        .overlay(
            Divider()
                .background(Color.white.opacity(0.12))
                .padding(.horizontal, -4),
            alignment: .top
        )
    }
}

#Preview("Hold — mid progress") {
    AuroraHaloView(mode: .hold, progress: 0.6, appName: "Safari", bundleID: "com.apple.Safari")
        .padding(60)
        .background(Color.black)
}

#Preview("DoublePress — near timeout") {
    AuroraHaloView(mode: .doublePress, progress: 0.75, appName: "Safari", bundleID: "com.apple.Safari")
        .padding(60)
        .background(Color.black)
}
