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
            icon(isDouble: isDouble, remain: remain, progress: progress)
                .padding(.top, 28)

            Text(isDouble ? "Press ⌘Q again" : "Hold ⌘Q to quit")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, 20)
                .accessibilityIdentifier("overlayTitle")

            Text(isDouble ? "Or let it fade" : "Release to cancel")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.top, 6)

            Text(appName)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 18)
                .padding(.bottom, 18)
                .accessibilityIdentifier("overlayAppName")
        }
        .frame(width: 320)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(red: 20/255, green: 22/255, blue: 30/255).opacity(0.6))
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
        .shadow(
            color: Color(hue: 272/360, saturation: 0.75, brightness: 0.6)
                .opacity(haloAlpha),
            radius: haloSize
        )
        .opacity(cardOpacity)
        .scaleEffect(cardScale)
        .animation(.easeOut(duration: 0.2), value: cardOpacity)
        .animation(.easeOut(duration: 0.2), value: cardScale)
    }

    @ViewBuilder
    private func icon(isDouble: Bool, remain: Double, progress: Double) -> some View {
        // Placeholder icon — real NSWorkspace.icon(forBundle:) lookup lands
        // alongside the M5 app-picker. Uses the Aurora hue (272°) halo glow.
        let iconOpacity: Double = isDouble ? 0.6 + 0.4 * remain : 1.0

        Image(systemName: "lock.shield.fill")
            .font(.system(size: 60, weight: .regular))
            .foregroundStyle(.white.opacity(0.95))
            .padding(14)
            .background(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hue: 272/360, saturation: 0.7, brightness: 0.55).opacity(0.85),
                                Color(hue: 272/360, saturation: 0.7, brightness: 0.2).opacity(0.4)
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 44
                        )
                    )
                    .blur(radius: 6)
            )
            .opacity(iconOpacity)
    }
}

#Preview("Hold — mid progress") {
    AuroraHaloView(mode: .hold, progress: 0.6, appName: "Safari")
        .padding(60)
        .background(Color.black)
}

#Preview("DoublePress — near timeout") {
    AuroraHaloView(mode: .doublePress, progress: 0.75, appName: "Safari")
        .padding(60)
        .background(Color.black)
}
