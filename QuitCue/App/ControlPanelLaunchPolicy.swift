enum ControlPanelLaunchPolicy {
    static func shouldShowControlPanel(
        showSettingsOnLaunch: Bool,
        isQuitCueEnabled: Bool
    ) -> Bool {
        showSettingsOnLaunch || !isQuitCueEnabled
    }

    static func shouldHideDockAfterLaunch(
        onboardingComplete: Bool,
        showSettingsOnLaunch: Bool,
        isQuitCueEnabled: Bool
    ) -> Bool {
        onboardingComplete && !showSettingsOnLaunch && isQuitCueEnabled
    }
}
