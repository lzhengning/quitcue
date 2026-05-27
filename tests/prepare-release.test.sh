#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

WORK="${TMP}/repo"
mkdir -p "${WORK}/scripts"
cp "${ROOT}/scripts/prepare-release.sh" "${WORK}/scripts/prepare-release.sh"
chmod +x "${WORK}/scripts/prepare-release.sh"

cd "${WORK}"
git init -q
git config user.email "release-test@example.com"
git config user.name "Release Test"

cat > project.yml <<'YAML'
name: QuitCue
settings:
  base:
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
YAML

git add project.yml scripts/prepare-release.sh
git commit -q -m "Initial project"

./scripts/prepare-release.sh 1.2.3 >"${TMP}/prepare.log"

grep -F 'MARKETING_VERSION: "1.2.3"' project.yml >/dev/null
git diff --exit-code >/dev/null
git diff --cached --exit-code >/dev/null

LATEST_SUBJECT="$(git log -1 --format=%s)"
[[ "${LATEST_SUBJECT}" == "Bump version to 1.2.3" ]] || {
  echo "Unexpected release commit subject: ${LATEST_SUBJECT}" >&2
  exit 1
}

TAG_COMMIT="$(git rev-parse v1.2.3^{commit})"
HEAD_COMMIT="$(git rev-parse HEAD)"
[[ "${TAG_COMMIT}" == "${HEAD_COMMIT}" ]] || {
  echo "Expected v1.2.3 to point at HEAD" >&2
  exit 1
}

TAG_MESSAGE="$(git tag -l v1.2.3 --format='%(contents:subject)')"
[[ "${TAG_MESSAGE}" == "QuitCue 1.2.3" ]] || {
  echo "Unexpected tag message: ${TAG_MESSAGE}" >&2
  exit 1
}

grep -F "git push origin" "${TMP}/prepare.log" >/dev/null
grep -F "v1.2.3" "${TMP}/prepare.log" >/dev/null

set +e
./scripts/prepare-release.sh 1.2 >"${TMP}/invalid.log" 2>&1
INVALID_STATUS=$?
set -e
[[ "${INVALID_STATUS}" -ne 0 ]] || {
  echo "Expected invalid version to fail" >&2
  exit 1
}
grep -F "Version must use x.y.z" "${TMP}/invalid.log" >/dev/null

echo "prepare-release.test.sh: ok"
