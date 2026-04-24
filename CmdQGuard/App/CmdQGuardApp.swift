import SwiftUI

@main
struct CmdQGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Onboarding window — presented on first run by AppDelegate,
        // also reachable by the `onboarding` window id.
        Window("Welcome to CmdQGuard", id: WindowID.onboarding.rawValue) {
            OnboardingView()
                .environment(appDelegate.whitelist)
                .environment(appDelegate.accessibility)
                .environment(appDelegate.settings)
                .environment(appDelegate.launchAtLogin)
                .frame(minWidth: 480, minHeight: 560)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About CmdQGuard") {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
            }
        }

        // Control Panel lives as the Settings scene — users reopen it via
        // Spotlight / Launchpad (the launch re-activates the app and triggers
        // the settings window) or Cmd+Comma while any app window is frontmost.
        Settings {
            ControlPanelView()
                .environment(appDelegate.whitelist)
                .environment(appDelegate.accessibility)
                .environment(appDelegate.settings)
                .environment(appDelegate.launchAtLogin)
                .frame(minWidth: 520, minHeight: 620)
        }
    }
}

enum WindowID: String {
    case onboarding
}
