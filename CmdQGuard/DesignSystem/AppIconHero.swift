import AppKit
import SwiftUI

/// Resolves and renders the real macOS app icon via NSWorkspace.
struct AppIconView: View {
    let app: InstalledApp
    let size: CGFloat

    var body: some View {
        Image(nsImage: AppIconCache.icon(for: app))
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
    }

    static func prefetch(_ apps: [InstalledApp], startingAt startIndex: Int = 0) {
        AppIconCache.prefetch(apps, startingAt: startIndex)
    }
}

@MainActor
private enum AppIconCache {
    private static let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 512
        return cache
    }()
    private static var prefetchTask: Task<Void, Never>?

    static func icon(for app: InstalledApp) -> NSImage {
        let key = app.url.path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let icon = NSWorkspace.shared.icon(forFile: app.url.path)
        icon.size = NSSize(width: 64, height: 64)
        cache.setObject(icon, forKey: key)
        return icon
    }

    static func prefetch(_ apps: [InstalledApp], startingAt startIndex: Int = 0) {
        prefetchTask?.cancel()
        prefetchTask = Task { @MainActor in
            for (index, app) in apps.enumerated() where index >= startIndex {
                guard !Task.isCancelled else { return }
                _ = icon(for: app)
                if index.isMultiple(of: 8) {
                    await Task.yield()
                }
            }
        }
    }
}

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
    /// Hue for the aura; prototype default is 285°.
    var glowHue: Double = 285

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
                        Color(hue: glowHue/360, saturation: 0.72, brightness: 0.94)
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
        if let nsImage = Self.resolvedIcon(bundleID: bundleID, size: size) {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        } else {
            BrandMark(size: size)
        }
    }

    static func resolvedIcon(bundleID: String?, size: CGFloat) -> NSImage? {
        guard let bundleID, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: size, height: size)
        return icon
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
