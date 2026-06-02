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

## License

QuitCue is released under the [MIT License](LICENSE).
