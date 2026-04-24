import AppKit
import SwiftUI

/// The big centered app icon inside the Aurora Halo overlay card.
/// - Loads the real macOS app icon via `NSWorkspace` when a bundle ID is
///   known; falls back to `BrandMark` when the target app can't be
///   resolved (e.g. debug / placeholder flows).
/// - Wraps the icon in a progress-driven purple aura that intensifies
///   with `progress` and scales the icon slightly as commitment rises.
struct AppIconHero: View {
    /// Bundle identifier of the app we're about to quit, when resolvable.
    var bundleID: String?
    /// 0...1 — same scalar the state-machine feeds to the card.
    var progress: Double = 0
    var size: CGFloat = 88
    /// Hue for the aura; prototype default is 272°.
    var glowHue: Double = 272

    var body: some View {
        ZStack {
            aura
            icon
        }
        .frame(width: size, height: size)
        .scaleEffect(1 - progress * 0.08)
        .animation(.easeOut(duration: 0.2), value: progress)
    }

    private var aura: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hue: glowHue/360, saturation: 0.85, brightness: 0.65)
                            .opacity(0.15 + progress * 0.55),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size
                )
            )
            .frame(width: size * 1.9, height: size * 1.9)
            .blur(radius: 12 + progress * 24)
    }

    @ViewBuilder
    private var icon: some View {
        if let nsImage = resolvedIcon() {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        } else {
            BrandMark(size: size)
        }
    }

    private func resolvedIcon() -> NSImage? {
        guard let bundleID, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

#Preview("Idle") {
    AppIconHero(bundleID: "com.apple.Safari", progress: 0)
        .padding(50)
        .background(Color.overlayCardBase)
}

#Preview("Holding") {
    AppIconHero(bundleID: "com.apple.Safari", progress: 0.7)
        .padding(50)
        .background(Color.overlayCardBase)
}
