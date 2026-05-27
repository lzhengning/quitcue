#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_YML="${ROOT}/project.yml"
GIT_BIN="${GIT_BIN:-git}"
PERL_BIN="${PERL_BIN:-perl}"

usage() {
  cat <<USAGE
Usage: scripts/prepare-release.sh X.Y.Z

Updates project.yml, creates a release commit, and tags it as vX.Y.Z.
The script does not push; review the result, then push the branch and tag.
USAGE
}

log() {
  printf '\033[1;34m[prepare-release]\033[0m %s\n' "$*"
}

VERSION="${1:-}"
if [[ -z "${VERSION}" || "${VERSION}" == "-h" || "${VERSION}" == "--help" ]]; then
  usage
  [[ -n "${VERSION}" ]] && exit 0
  exit 2
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must use x.y.z, for example 0.1.0" >&2
  exit 2
fi

TAG="v${VERSION}"

cd "${ROOT}"

[[ -f "${PROJECT_YML}" ]] || {
  echo "Missing project.yml at ${PROJECT_YML}" >&2
  exit 1
}

if [[ -n "$("${GIT_BIN}" status --porcelain)" ]]; then
  echo "Working tree must be clean before preparing a release." >&2
  exit 1
fi

if "${GIT_BIN}" rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
  echo "Tag ${TAG} already exists." >&2
  exit 1
fi

if ! grep -Eq '^[[:space:]]*MARKETING_VERSION:[[:space:]]*"' "${PROJECT_YML}"; then
  echo "Could not find MARKETING_VERSION in project.yml." >&2
  exit 1
fi

log "Updating project.yml to ${VERSION}..."
"${PERL_BIN}" -0pi -e \
  "s/(^[ \\t]*MARKETING_VERSION:[ \\t]*\")[^\"]*(\")/\${1}${VERSION}\${2}/m" \
  "${PROJECT_YML}"

if ! "${GIT_BIN}" diff --quiet -- "${PROJECT_YML}"; then
  "${GIT_BIN}" add "${PROJECT_YML}"
  "${GIT_BIN}" commit -m "Bump version to ${VERSION}"
else
  log "project.yml already uses ${VERSION}; tagging current commit."
fi

log "Creating annotated tag ${TAG}..."
"${GIT_BIN}" tag -a "${TAG}" -m "QuitCue ${VERSION}"

BRANCH="$("${GIT_BIN}" rev-parse --abbrev-ref HEAD)"
if [[ "${BRANCH}" == "HEAD" ]]; then
  BRANCH="main"
fi

log "Prepared ${TAG}."
printf 'Review the release commit, then run:\n'
printf '  git push origin %s %s\n' "${BRANCH}" "${TAG}"
