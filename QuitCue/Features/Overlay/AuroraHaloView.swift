import SwiftUI

/// Aurora Halo overlay — the floating glass card that appears when an
/// intercepted ⌘Q needs confirmation. Two visual modes per the approved
/// "Aurora Halo" prototype (hue 285°):
///
/// - `.hold`: halo intensifies with progress (commitment rising).
/// - `.doublePress`: halo starts soft, then softly shrinks + fades as the
///   window elapses. In the last 35 % of the window the whole card dissolves.
struct AuroraHaloView: View {
    private let cardWidth: CGFloat = 320
    private let cardHorizontalPadding: CGFloat = 24
    private let cardTopPadding: CGFloat = 28
    private let cardBottomPadding: CGFloat = 18
    private let cardCornerRadius: CGFloat = 28

    let mode: ConfirmMode
    /// 0...1 — time elapsed in the current confirm window.
    let progress: Double
    let appName: String
    /// Optional bundle ID so the hero can load the real app icon.
    var bundleID: String? = nil

    var body: some View {
        let isDouble = mode == .doublePress
        let remain = max(0, 1 - progress)

        let ambientAlpha: Double = isDouble ? 0.04 * remain : 0.03 + progress * 0.06
        let ambientBlur: CGFloat = isDouble ? 18 + 14 * remain : 20 + progress * 20
        let cardOpacity: Double = isDouble
            ? (progress < 0.65 ? 1 : max(0, (1 - progress) / 0.35))
            : 1
        let cardScale: Double = isDouble ? 1 - progress * 0.03 : 1 + progress * 0.008
        let borderColor = isDouble ? Color.white.opacity(0.14) : accentColor(progress: progress, opacity: 0.14 + progress * 0.32)

        VStack(spacing: 0) {
            heroIcon(isDouble: isDouble, remain: remain, progress: progress)
                .padding(.top, cardTopPadding)

            title(isDouble: isDouble)
                .padding(.top, 22)

            if isDouble {
                tapDots(progress: progress)
                    .padding(.top, 12)
            }

            cardFooter
                .padding(.top, 18)
                .padding(.bottom, cardBottomPadding)
        }
        .frame(width: cardWidth - cardHorizontalPadding * 2)
        .padding(.horizontal, cardHorizontalPadding)
        .background {
            RoundedRectangle(cornerRadius: cardCornerRadius + 6, style: .continuous)
                .fill(accentColor(progress: progress, opacity: ambientAlpha))
                .frame(width: cardWidth + 20, height: cardHeight(isDouble: isDouble) + 18)
                .blur(radius: ambientBlur)
        }
        .background {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.16))
                .offset(y: 14)
                .blur(radius: 22)
        }
        .background {
            cardSurface
        }
        .overlay(
            cardShape
                .strokeBorder(borderColor, lineWidth: 0.5)
        )
        .overlay(
            cardShape
                .strokeBorder(accentColor(progress: progress, opacity: 0.12), lineWidth: CGFloat(0.5 * progress))
        )
        .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 10)
        .opacity(cardOpacity)
        .scaleEffect(cardScale)
        .animation(.easeOut(duration: 0.2), value: cardOpacity)
        .animation(.easeOut(duration: 0.2), value: cardScale)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
    }

    private var cardSurface: some View {
        cardShape
            .fill(Color.overlayCardBase.opacity(0.52))
            .liquidGlass(
                in: cardShape,
                tint: Color.overlayCardBase.opacity(0.20)
            )
    }

    private func title(isDouble: Bool) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Text(isDouble ? "Press" : "Hold")
                .font(AppTypography.title3)
                .tracking(-0.2)

            KbdHint()

            Text(isDouble ? "Again" : "to Quit")
                .font(AppTypography.title3)
                .tracking(-0.2)
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isDouble ? "Press Command Q Again" : "Hold Command Q to Quit")
        .accessibilityIdentifier("overlayTitle")
    }

    @ViewBuilder
    private func heroIcon(isDouble: Bool, remain: Double, progress: Double) -> some View {
        let iconOpacity: Double = isDouble ? 0.6 + 0.4 * remain : 1.0
        if isDouble {
            AppIconHero(
                bundleID: bundleID,
                progress: 0.2 * remain,
                size: 88
            )
            .opacity(iconOpacity)
        } else {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 3)
                    .frame(width: 156, height: 156)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        accentColor(progress: progress, opacity: 0.9),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .frame(width: 156, height: 156)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accentColor(progress: progress, opacity: 0.45), radius: CGFloat(3 + 6 * progress))
                    .animation(.easeOut(duration: 0.2), value: progress)

                AppIconHero(
                    bundleID: bundleID,
                    progress: progress,
                    size: 88
                )
            }
            .frame(width: 156, height: 156)
        }
    }

    private var cardFooter: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accentColor(progress: progress, opacity: 0.8))
                .frame(width: 7, height: 7)
                .shadow(color: accentColor(progress: progress, opacity: 0.55), radius: 4)

            Text("Protected by QuitCue")
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

    private func tapDots(progress: Double) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accentColor(progress: 0, opacity: 1))
                .frame(width: 8, height: 8)
                .shadow(color: accentColor(progress: 0, opacity: 0.6), radius: 4)

            Circle()
                .strokeBorder(Color.white.opacity(0.6 * max(0.35, 1 - progress)), lineWidth: 1.2)
                .frame(width: 8, height: 8)
                .scaleEffect(1 + 0.18 * sin(progress * .pi * 8))
        }
    }

    private func accentColor(progress: Double, opacity: Double = 1) -> Color {
        Color(
            hue: 285/360,
            saturation: 0.58 + min(max(progress, 0), 1) * 0.18,
            brightness: 0.86 + min(max(progress, 0), 1) * 0.06
        )
        .opacity(opacity)
    }

    private func cardHeight(isDouble: Bool) -> CGFloat {
        let iconHeight: CGFloat = isDouble ? 88 : 156
        let dotsHeight: CGFloat = isDouble ? 20 : 0
        let dotsSpacing: CGFloat = isDouble ? 12 : 0
        return cardTopPadding
            + iconHeight
            + 22
            + 24
            + dotsSpacing
            + dotsHeight
            + 18
            + 23
            + cardBottomPadding
    }
}

private struct KbdHint: View {
    var body: some View {
        HStack(spacing: 4) {
            KbdKey("⌘")
            KbdKey("Q")
        }
    }
}

private struct KbdKey: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.16), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
    }
}

#Preview("Hold — mid progress") {
    AuroraHaloView(mode: .hold, progress: 0.6, appName: "Safari", bundleID: "com.apple.Safari")
        .padding(80)
        .background(.clear)
}

#Preview("DoublePress — near timeout") {
    AuroraHaloView(mode: .doublePress, progress: 0.75, appName: "Safari", bundleID: "com.apple.Safari")
        .padding(80)
        .background(.clear)
}
