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

/// Enumerates user-installed and system macOS apps. `.scan()` returns a
/// name-sorted list from common app roots, deduplicated by bundle ID.
enum AppInventory {
    static let defaultRoots: [URL] = [
        URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Applications", isDirectory: true),
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Library/CoreServices/Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Volumes/Preboot/Cryptexes/App/System/Applications", isDirectory: true)
    ]

    static func scan(roots: [URL] = defaultRoots, fileManager: FileManager = .default) -> [InstalledApp] {
        var seen = Set<String>()
        var out: [InstalledApp] = []

        for root in roots {
            collectApps(in: root, fileManager: fileManager, seen: &seen, output: &out)
        }

        out.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return out
    }

    private static func collectApps(
        in root: URL,
        fileManager: FileManager,
        seen: inout Set<String>,
        output: inout [InstalledApp]
    ) {
        if isAppBundle(root) {
            appendApp(root, seen: &seen, output: &output)
            return
        }

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return }

        for case let url as URL in enumerator {
            if url.lastPathComponent.hasPrefix(".") {
                enumerator.skipDescendants()
                continue
            }

            guard isAppBundle(url) else { continue }
            appendApp(url, seen: &seen, output: &output)
            enumerator.skipDescendants()
        }
    }

    private static func appendApp(_ url: URL, seen: inout Set<String>, output: inout [InstalledApp]) {
        guard
            let bundle = Bundle(url: url),
            let bundleID = bundle.bundleIdentifier,
            !seen.contains(bundleID)
        else { return }

        seen.insert(bundleID)

        let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent

        output.append(InstalledApp(bundleID: bundleID, name: displayName, url: url))
    }

    private static func isAppBundle(_ url: URL) -> Bool {
        url.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame
    }
}
