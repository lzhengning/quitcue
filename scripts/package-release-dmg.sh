#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CmdQGuard"
SCHEME="CmdQGuard"
CONFIGURATION="Release"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${ROOT}/CmdQGuard.xcodeproj"
OUTPUT_DIR="${ROOT}/dist"
DERIVED_DATA="${ROOT}/build/ReleaseDerivedData"
SIGNING_IDENTITY="${CMDQGUARD_CODESIGN_IDENTITY:-}"
DEVELOPMENT_TEAM="${CMDQGUARD_DEVELOPMENT_TEAM:-}"
NOTARY_PROFILE="${CMDQGUARD_NOTARY_PROFILE:-}"
CLEAN_STAGING=1

XCODEBUILD_BIN="${XCODEBUILD_BIN:-xcodebuild}"
HDIUTIL_BIN="${HDIUTIL_BIN:-hdiutil}"
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
  --notary-profile NAME      Submit and staple the DMG with notarytool keychain profile
  --no-clean                 Keep the staging folder under output-dir/.staging
  -h, --help                 Show this help

Environment:
  CMDQGUARD_CODESIGN_IDENTITY, CMDQGUARD_DEVELOPMENT_TEAM, CMDQGUARD_NOTARY_PROFILE
USAGE
}

log() {
  printf '\033[1;34m[release-dmg]\033[0m %s\n' "$*"
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
    --notary-profile)
      NOTARY_PROFILE="$2"
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
RELEASE_ID="${APP_NAME}-${VERSION}+${BUILD_NUMBER}"

mkdir -p "${OUTPUT_DIR}"
STAGING_ROOT="${OUTPUT_DIR}/.staging"
STAGING_DIR="${STAGING_ROOT}/${RELEASE_ID}"
DMG_PATH="${OUTPUT_DIR}/${RELEASE_ID}.dmg"

log "Staging ${APP_NAME}.app..."
rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}"
ditto "${APP_PATH}" "${STAGING_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGING_DIR}/Applications"

log "Creating ${DMG_PATH}..."
"${HDIUTIL_BIN}" create \
  -volname "${RELEASE_ID}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

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
