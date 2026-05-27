import Foundation
import Observation
import ServiceManagement

/// Abstracts `SMAppService.mainApp` so the Control Panel can bind to a
/// Boolean toggle and tests can substitute a fake without hitting TCC.
@MainActor
protocol LaunchAtLoginBackend: AnyObject {
    var isEnabled: Bool { get }
    func register() throws
    func unregister() throws
}

@MainActor
final class SMAppServiceBackend: LaunchAtLoginBackend {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    func register() throws { try SMAppService.mainApp.register() }
    func unregister() throws { try SMAppService.mainApp.unregister() }
}

@MainActor
@Observable
final class LaunchAtLoginManager {
    private let backend: LaunchAtLoginBackend
    private(set) var isEnabled: Bool
    private(set) var lastError: String?

    init(backend: LaunchAtLoginBackend) {
        self.backend = backend
        self.isEnabled = backend.isEnabled
    }

    convenience init() {
        self.init(backend: SMAppServiceBackend())
    }

    func refresh() {
        isEnabled = backend.isEnabled
    }

    /// Toggle target state. SMAppService surfaces errors (e.g. TCC denial,
    /// unsigned bundle) which we surface through `lastError` rather than
    /// throwing — the view binds to the observed state.
    func setEnabled(_ target: Bool) {
        do {
            if target {
                try backend.register()
            } else {
                try backend.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        isEnabled = backend.isEnabled
    }
}
