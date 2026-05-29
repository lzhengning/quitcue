#!/usr/bin/env bash
set -euo pipefail

APP_NAME="QuitCue"
DMG_VOLUME_NAME="QuitCue Installer"
SCHEME="QuitCue"
CONFIGURATION="Release"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${ROOT}/QuitCue.xcodeproj"
OUTPUT_DIR="${ROOT}/dist"
DERIVED_DATA="${ROOT}/build/ReleaseDerivedData"
SIGNING_IDENTITY="${QUITCUE_CODESIGN_IDENTITY:-}"
DEVELOPMENT_TEAM="${QUITCUE_DEVELOPMENT_TEAM:-}"
NOTARY_PROFILE="${QUITCUE_NOTARY_PROFILE:-}"
MARKETING_VERSION_OVERRIDE="${QUITCUE_MARKETING_VERSION:-}"
BUILD_NUMBER_OVERRIDE="${QUITCUE_BUILD_NUMBER:-}"
CLEAN_STAGING=1

XCODEBUILD_BIN="${XCODEBUILD_BIN:-xcodebuild}"
CREATE_DMG_BIN="${CREATE_DMG_BIN:-create-dmg}"
SWIFT_BIN="${SWIFT_BIN:-swift}"
XCRUN_BIN="${XCRUN_BIN:-xcrun}"
PLISTBUDDY_BIN="${PLISTBUDDY_BIN:-/usr/libexec/PlistBuddy}"

usage() {
  cat <<USAGE
Usage: scripts/package-release-dmg.sh [options]

Builds the ${APP_NAME} Release app and packages it as a versioned DMG.

Options:
  --output-dir PATH          Directory for the generated DMG. Default: dist
  --derived-data PATH        DerivedData directory. Default: build/ReleaseDerivedData
  --signing-identity NAME    Override CODE_SIGN_IDENTITY for the Release build
  --development-team TEAMID  Override DEVELOPMENT_TEAM for the Release build
  --marketing-version X.Y.Z  Override MARKETING_VERSION for the Release build
  --build-number NUMBER      Override CURRENT_PROJECT_VERSION for the Release build
  --notary-profile NAME      Submit and staple the DMG with notarytool keychain profile
  --background PATH          Use a custom DMG background image
  --no-clean                 Keep the staging folder under output-dir/.staging
  -h, --help                 Show this help

Environment:
  QUITCUE_CODESIGN_IDENTITY, QUITCUE_DEVELOPMENT_TEAM, QUITCUE_NOTARY_PROFILE,
  QUITCUE_MARKETING_VERSION, QUITCUE_BUILD_NUMBER, QUITCUE_DMG_BACKGROUND
USAGE
}

log() {
  printf '\033[1;34m[release-dmg]\033[0m %s\n' "$*"
}

render_default_background() {
  local output="$1"

  "${SWIFT_BIN}" - "${output}" <<'SWIFT'
import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 680, height: 420)
let image = NSImage(size: size)

image.lockFocus()

let bounds = NSRect(origin: .zero, size: size)
NSColor(calibratedRed: 0.96, green: 0.93, blue: 0.86, alpha: 1).setFill()
bounds.fill()

if let gradient = NSGradient(
  starting: NSColor(calibratedRed: 0.99, green: 0.97, blue: 0.92, alpha: 1),
  ending: NSColor(calibratedRed: 0.86, green: 0.84, blue: 0.77, alpha: 1)
) {
  gradient.draw(in: bounds, angle: -24)
}

NSColor(calibratedWhite: 1, alpha: 0.32).setFill()
NSBezierPath(roundedRect: NSRect(x: 38, y: 34, width: 604, height: 352), xRadius: 34, yRadius: 34).fill()

let arrow = NSBezierPath()
arrow.lineWidth = 5
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.move(to: NSPoint(x: 288, y: 210))
arrow.curve(
  to: NSPoint(x: 394, y: 210),
  controlPoint1: NSPoint(x: 322, y: 228),
  controlPoint2: NSPoint(x: 360, y: 228)
)
arrow.move(to: NSPoint(x: 376, y: 229))
arrow.line(to: NSPoint(x: 398, y: 210))
arrow.line(to: NSPoint(x: 376, y: 191))
NSColor(calibratedRed: 0.39, green: 0.42, blue: 0.50, alpha: 0.30).setStroke()
arrow.stroke()

image.unlockFocus()

guard
  let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let data = bitmap.representation(using: .png, properties: [:])
else {
  fputs("Failed to render DMG background\n", stderr)
  exit(1)
}

try data.write(to: output)
SWIFT
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --derived-data)
      DERIVED_DATA="$2"
      shift 2
      ;;
    --signing-identity)
      SIGNING_IDENTITY="$2"
      shift 2
      ;;
    --development-team)
      DEVELOPMENT_TEAM="$2"
      shift 2
      ;;
    --marketing-version)
      MARKETING_VERSION_OVERRIDE="$2"
      shift 2
      ;;
    --build-number)
      BUILD_NUMBER_OVERRIDE="$2"
      shift 2
      ;;
    --notary-profile)
      NOTARY_PROFILE="$2"
      shift 2
      ;;
    --background)
      QUITCUE_DMG_BACKGROUND="$2"
      shift 2
      ;;
    --no-clean)
      CLEAN_STAGING=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

BUILD_ARGS=(
  -project "${PROJECT}"
  -scheme "${SCHEME}"
  -configuration "${CONFIGURATION}"
  -destination "generic/platform=macOS"
  -derivedDataPath "${DERIVED_DATA}"
  clean build
)

if [[ -n "${SIGNING_IDENTITY}" ]]; then
  BUILD_ARGS+=(
    CODE_SIGN_STYLE=Manual
    "CODE_SIGN_IDENTITY=${SIGNING_IDENTITY}"
  )
fi

if [[ -n "${DEVELOPMENT_TEAM}" ]]; then
  BUILD_ARGS+=("DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM}")
fi

if [[ -n "${MARKETING_VERSION_OVERRIDE}" ]]; then
  BUILD_ARGS+=("MARKETING_VERSION=${MARKETING_VERSION_OVERRIDE}")
fi

if [[ -n "${BUILD_NUMBER_OVERRIDE}" ]]; then
  BUILD_ARGS+=("CURRENT_PROJECT_VERSION=${BUILD_NUMBER_OVERRIDE}")
fi

log "Building ${APP_NAME} (${CONFIGURATION})..."
"${XCODEBUILD_BIN}" "${BUILD_ARGS[@]}"

APP_PATH="${DERIVED_DATA}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
INFO_PLIST="${APP_PATH}/Contents/Info.plist"

[[ -d "${APP_PATH}" ]] || {
  echo "Build did not produce ${APP_PATH}" >&2
  exit 1
}

VERSION="$("${PLISTBUDDY_BIN}" -c "Print :CFBundleShortVersionString" "${INFO_PLIST}")"
BUILD_NUMBER="$("${PLISTBUDDY_BIN}" -c "Print :CFBundleVersion" "${INFO_PLIST}")"
RELEASE_ID="${APP_NAME}-${VERSION}"

mkdir -p "${OUTPUT_DIR}"
STAGING_ROOT="${OUTPUT_DIR}/.staging"
STAGING_DIR="${STAGING_ROOT}/${RELEASE_ID}"
BACKGROUND_PATH="${QUITCUE_DMG_BACKGROUND:-${STAGING_ROOT}/${RELEASE_ID}-background.png}"
DMG_PATH="${OUTPUT_DIR}/${RELEASE_ID}.dmg"
log "Resolved ${APP_NAME} ${VERSION} (build ${BUILD_NUMBER})"

log "Staging ${APP_NAME}.app..."
rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}"
ditto "${APP_PATH}" "${STAGING_DIR}/${APP_NAME}.app"

if [[ -z "${QUITCUE_DMG_BACKGROUND:-}" ]]; then
  log "Rendering default DMG background..."
  render_default_background "${BACKGROUND_PATH}"
fi

CREATE_DMG_ARGS=(
  --volname "${DMG_VOLUME_NAME}"
  --background "${BACKGROUND_PATH}"
  --window-pos 200 120
  --window-size 680 452
  --text-size 12
  --icon-size 128
  --icon "${APP_NAME}.app" 180 210
  --hide-extension "${APP_NAME}.app"
  --app-drop-link 500 210
  --format UDZO
  --no-internet-enable
)

for icon_name in "${APP_NAME}.icns" AppIcon.icns; do
  if [[ -f "${APP_PATH}/Contents/Resources/${icon_name}" ]]; then
    CREATE_DMG_ARGS+=(--volicon "${APP_PATH}/Contents/Resources/${icon_name}")
    break
  fi
done

log "Creating ${DMG_PATH} with create-dmg..."
"${CREATE_DMG_BIN}" "${CREATE_DMG_ARGS[@]}" "${DMG_PATH}" "${STAGING_DIR}"

if [[ -n "${NOTARY_PROFILE}" ]]; then
  log "Submitting DMG for notarization with profile '${NOTARY_PROFILE}'..."
  "${XCRUN_BIN}" notarytool submit "${DMG_PATH}" \
    --keychain-profile "${NOTARY_PROFILE}" \
    --wait
  log "Stapling notarization ticket..."
  "${XCRUN_BIN}" stapler staple "${DMG_PATH}"
fi

if [[ "${CLEAN_STAGING}" == "1" ]]; then
  rm -rf "${STAGING_ROOT}"
fi

log "Done: ${DMG_PATH}"
