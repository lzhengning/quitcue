import SwiftUI

@main
struct QuitCueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Onboarding window — presented on first run by AppDelegate,
        // also reachable by the `onboarding` window id.
        Window("QuitCue", id: WindowID.onboarding.rawValue) {
            OnboardingView()
                .environment(appDelegate.whitelist)
                .environment(appDelegate.accessibility)
                .environment(appDelegate.settings)
                .environment(appDelegate.launchAtLogin)
                .frame(width: 460, height: 540)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About QuitCue") {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
            }
            CommandGroup(replacing: .appTermination) {
                Button("Close Control Panel") {
                    appDelegate.hideControlPanel()
                }
                .keyboardShortcut("q")
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
        }
        .windowResizability(.contentSize)
    }
}

enum WindowID: String {
    case onboarding
}
