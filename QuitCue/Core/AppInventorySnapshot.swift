import Foundation

struct AppInventorySnapshot {
    private let scanner: () -> [InstalledApp]
    private(set) var apps: [InstalledApp]

    init(
        apps: [InstalledApp] = [],
        scanner: @escaping () -> [InstalledApp] = { AppInventory.scan() }
    ) {
        self.apps = apps
        self.scanner = scanner
    }

    @discardableResult
    mutating func refresh() -> [InstalledApp] {
        let scannedApps = scanner()
        apps = scannedApps
        return scannedApps
    }
}
