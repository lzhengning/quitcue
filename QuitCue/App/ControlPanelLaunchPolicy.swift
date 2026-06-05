enum ControlPanelLaunchPolicy {
    static func shouldShowControlPanel(
        onboardingComplete: Bool,
        showSettingsOnLaunch: Bool,
        isQuitCueEnabled: Bool
    ) -> Bool {
        showSettingsOnLaunch || (onboardingComplete && !isQuitCueEnabled)
    }

    static func shouldHideDockAfterLaunch(
        onboardingComplete: Bool,
        showSettingsOnLaunch: Bool,
        isQuitCueEnabled: Bool
    ) -> Bool {
        onboardingComplete && !showSettingsOnLaunch && isQuitCueEnabled
    }
}
