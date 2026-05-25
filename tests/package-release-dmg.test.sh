#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

LOG="${TMP}/commands.log"
BIN="${TMP}/bin"
mkdir -p "${BIN}"

cat > "${BIN}/xcodebuild" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'xcodebuild %s\n' "$*" >> "${CMDQGUARD_TEST_LOG}"

DERIVED_DATA=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -derivedDataPath)
      DERIVED_DATA="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

APP="${DERIVED_DATA}/Build/Products/Release/CmdQGuard.app"
mkdir -p "${APP}/Contents/MacOS"
cat > "${APP}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleShortVersionString</key>
  <string>9.8.7</string>
  <key>CFBundleVersion</key>
  <string>42</string>
</dict>
</plist>
PLIST
touch "${APP}/Contents/MacOS/CmdQGuard"
STUB

cat > "${BIN}/create-dmg" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'create-dmg %s\n' "$*" >> "${CMDQGUARD_TEST_LOG}"
OUT="${@: -2:1}"
mkdir -p "$(dirname "${OUT}")"
printf 'fake dmg\n' > "${OUT}"
STUB

cat > "${BIN}/swift" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'swift %s\n' "$*" >> "${CMDQGUARD_TEST_LOG}"
OUT="${2:?missing background output path}"
mkdir -p "$(dirname "${OUT}")"
printf 'fake png\n' > "${OUT}"
STUB

chmod +x "${BIN}/xcodebuild" "${BIN}/create-dmg" "${BIN}/swift"

OUT_DIR="${TMP}/dist"
DERIVED_DATA="${TMP}/DerivedData"
CMDQGUARD_TEST_LOG="${LOG}" \
  XCODEBUILD_BIN="${BIN}/xcodebuild" \
  CREATE_DMG_BIN="${BIN}/create-dmg" \
  SWIFT_BIN="${BIN}/swift" \
  "${ROOT}/scripts/package-release-dmg.sh" \
    --output-dir "${OUT_DIR}" \
    --derived-data "${DERIVED_DATA}" \
    --no-clean

DMG="${OUT_DIR}/CmdQGuard-9.8.7+42.dmg"
[[ -f "${DMG}" ]] || {
  echo "Expected DMG at ${DMG}" >&2
  exit 1
}

grep -F -- "-configuration Release" "${LOG}" >/dev/null
grep -F -- "-scheme CmdQGuard" "${LOG}" >/dev/null
grep -F -- "create-dmg --volname CmdQGuard" "${LOG}" >/dev/null
grep -F -- "--window-size 680 420" "${LOG}" >/dev/null
grep -F -- "--icon CmdQGuard.app 180 210" "${LOG}" >/dev/null
grep -F -- "--app-drop-link 500 210" "${LOG}" >/dev/null
grep -F -- "CmdQGuard-9.8.7+42" "${LOG}" >/dev/null

STAGE="${OUT_DIR}/.staging/CmdQGuard-9.8.7+42"
[[ -d "${STAGE}/CmdQGuard.app" ]] || {
  echo "Expected staged app at ${STAGE}/CmdQGuard.app" >&2
  exit 1
}
[[ -f "${OUT_DIR}/.staging/CmdQGuard-9.8.7+42-background.png" ]] || {
  echo "Expected rendered DMG background" >&2
  exit 1
}

echo "package-release-dmg.test.sh: ok"
