import AppKit
import Foundation

/// A single installed application surfaced in the onboarding picker / M6
/// scanner. Identity is the bundle ID — display fields are lazily loaded.
struct InstalledApp: Equatable, Identifiable, Sendable {
    let bundleID: String
    let name: String
    let url: URL

    var id: String { bundleID }
}

/// Enumerates user-installed macOS apps. M4 surface area: `.scan()` returns
/// a name-sorted list from `/Applications` and `/System/Applications`,
/// deduplicated by bundle ID. M6 will layer categorization + recommended
/// defaults on top of this.
enum AppInventory {
    static let defaultRoots: [URL] = [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Applications", isDirectory: true)
    ]

    static func scan(roots: [URL] = defaultRoots, fileManager: FileManager = .default) -> [InstalledApp] {
        var seen = Set<String>()
        var out: [InstalledApp] = []

        for root in roots {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents where url.pathExtension == "app" {
                guard
                    let bundle = Bundle(url: url),
                    let bundleID = bundle.bundleIdentifier,
                    !seen.contains(bundleID)
                else { continue }

                seen.insert(bundleID)

                let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent

                out.append(InstalledApp(bundleID: bundleID, name: displayName, url: url))
            }
        }

        out.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return out
    }
}
