# QuitCue

<p align="center">
  <img src="docs/assets/quitcue-icon.png" width="120" alt="QuitCue app icon">
</p>

<h3 align="center">A small macOS guard for Command-Q.</h3>

<p align="center">
  QuitCue asks for confirmation before selected apps quit. Unprotected apps keep the normal macOS behavior.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-111111?logo=apple&logoColor=white" alt="macOS 14+">
  <img src="https://img.shields.io/badge/SwiftUI-native-0A84FF?logo=swift&logoColor=white" alt="SwiftUI native">
  <img src="https://img.shields.io/badge/status-MVP-2F855A" alt="MVP status">
  <a href="https://github.com/lzhengning/quitcue/actions/workflows/ci.yml">
    <img src="https://github.com/lzhengning/quitcue/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
</p>

<p align="center">
  <a href="https://quitcue.app">quitcue.app</a>
</p>

## QuitCue in Action

After an app is protected, <kbd>Command-Q</kbd> shows a confirmation overlay instead of quitting immediately.

![QuitCue demo video](docs/assets/quitcue-demo.gif)

## What It Does

- Protect apps by Bundle ID.
- Confirm quits by holding <kbd>Command-Q</kbd> or pressing it twice.
- Adjust the hold duration and double-press window.
- Manage protected apps, confirmation mode, launch at login, and core settings from one control panel.
- Keep QuitCue running after its window closes, so protection stays active in the background.
- Intercept plain <kbd>Command-Q</kbd> with a system event tap while leaving other shortcuts alone.

## Development

Before development, install:

- Xcode 26 or later
- XcodeGen
- create-dmg, used for local installer packaging
- Tart, used for isolated UI and EventTap tests

Open the generated Xcode project:

```bash
xcodegen generate
open QuitCue.xcodeproj
```

`project.yml` is the source of truth for the project structure. The generated Xcode project is treated as a build artifact. Use Tart for full UI and EventTap checks.

## Release

`project.yml` is the source of truth for the public version. Prepare a release locally, review the generated commit and tag, then push both:

```bash
scripts/prepare-release.sh 0.1.3
git push origin main v0.1.3
```

Pushing a `vX.Y.Z` tag triggers the GitHub Release workflow. In the default `developer-id` mode, the workflow builds the Release app, signs it with Developer ID, notarizes and staples the DMG, verifies the app and DMG with macOS security tools, then uploads `QuitCue-X.Y.Z.dmg` to the GitHub Release.

Configure these GitHub Actions secrets before pushing a public release tag:

- `DEVELOPER_ID_APPLICATION_P12_BASE64`
- `DEVELOPER_ID_APPLICATION_P12_PASSWORD`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `QUITCUE_CODESIGN_IDENTITY`

For a temporary pipeline rehearsal, set the repository variable `QUITCUE_RELEASE_SIGNING_MODE` to `apple-development` and configure:

- `APPLE_DEVELOPMENT_P12_BASE64`
- `APPLE_DEVELOPMENT_P12_PASSWORD`
- `APPLE_TEAM_ID`
- `QUITCUE_CODESIGN_IDENTITY`

The `apple-development` mode signs the app with an Apple Development certificate, skips notarization and Gatekeeper assessment, and marks the GitHub Release as a prerelease. Use it only to exercise the Release pipeline, not for public distribution.

Full UI and EventTap verification still belongs in Tart before publishing a release.

## License

QuitCue is released under the [MIT License](LICENSE).
