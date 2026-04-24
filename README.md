# CmdQGuard

A silent macOS utility that guards ⌘Q on whitelisted apps. Built with SwiftUI for macOS 14+, with Liquid Glass surfaces on macOS 26 Tahoe and graceful material fallback on earlier releases.

## Status

Milestone 1 — project skeleton. Onboarding, overlay, and control-panel views are scaffolded; the real logic lands in M2–M6.

## Prerequisites

- Xcode 26 (for macOS 26 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Generate the Xcode project

```bash
xcodegen generate
open CmdQGuard.xcodeproj
```

The generated `.xcodeproj` is git-ignored; `project.yml` is the source of truth.

## Roadmap

- **M1** Skeleton: XcodeGen, Ghost mode (`LSUIElement`), Settings scene, design tokens, Liquid Glass modifier with fallback ← *you are here*
- **M2** Core: `CGEventTap` quit interceptor, Accessibility permission bridge, whitelist persistence
- **M3** Overlay: Aurora Halo `NSPanel` with hold / double-press state machines
- **M4** Onboarding: three-step flow (Welcome → Accessibility → App Picker)
- **M5** Control Panel: protected apps, hold duration slider, launch-at-login (`SMAppService`)
- **M6** App Scanner: `/Applications` scan with category-based default whitelist
