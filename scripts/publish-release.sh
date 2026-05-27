#!/usr/bin/env bash
# publish-release.sh — create or update a GitHub Release with kernel .deb artifacts
#
# Creates a release tagged as xanmod-{kernel_version}+xanmod{n}~{distro}1
# Uploads all .deb and .changes files from OUTPUT_DIR.
# If the release already exists, uploads any missing assets.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/lib/log.sh"

DISTRO="${DISTRO:-debian}"
ARCH="${ARCH:-amd64}"
GITHUB_ORG="${GITHUB_ORG:-Interested-Deving-1896}"
GITHUB_REPO="${GITHUB_REPO:-xanmod-unified-kernel}"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/output/${DISTRO}/${ARCH}}"

VERSION_FILE="${REPO_ROOT}/patches/VERSION"
if [[ ! -f "${VERSION_FILE}" ]]; then
  die "VERSION file not found: ${VERSION_FILE} — run fetch-patches.sh first"
fi

KERNEL_VERSION="$(grep kernel_version "${VERSION_FILE}" | cut -d= -f2)"
XANMOD_VERSION="$(grep xanmod_version "${VERSION_FILE}" | cut -d= -f2)"
PKG_VERSION="${KERNEL_VERSION}+xanmod${XANMOD_VERSION}~${DISTRO}1"
RELEASE_TAG="xanmod-${PKG_VERSION}"

log_step "publish-release" "Publishing GitHub Release ${RELEASE_TAG}"

if ! command -v gh &>/dev/null; then
  die "gh CLI not found — run bootstrap.sh first"
fi

# Collect artifacts
ARTIFACTS=()
while IFS= read -r -d '' f; do
  ARTIFACTS+=("$f")
done < <(find "${OUTPUT_DIR}" -maxdepth 1 \( -name "*.deb" -o -name "*.changes" \) -print0)

if [[ ${#ARTIFACTS[@]} -eq 0 ]]; then
  die "No artifacts found in ${OUTPUT_DIR}"
fi

log_info "Artifacts to upload:"
for f in "${ARTIFACTS[@]}"; do
  log_info "  $(basename "${f}") ($(du -sh "${f}" | cut -f1))"
done

RELEASE_NOTES="## XanMod Kernel ${KERNEL_VERSION}+xanmod${XANMOD_VERSION}

**Distro:** ${DISTRO}  
**Architecture:** ${ARCH}  
**Package version:** \`${PKG_VERSION}\`

### Packages
$(for f in "${ARTIFACTS[@]}"; do echo "- \`$(basename "${f}")\`"; done)

### Install
\`\`\`bash
dpkg -i linux-image-*.deb linux-headers-*.deb
\`\`\`
"

# Create release if it doesn't exist
if gh release view "${RELEASE_TAG}" \
    --repo "${GITHUB_ORG}/${GITHUB_REPO}" &>/dev/null; then
  log_info "Release ${RELEASE_TAG} already exists — uploading missing assets"
  gh release upload "${RELEASE_TAG}" \
    --repo "${GITHUB_ORG}/${GITHUB_REPO}" \
    --clobber \
    "${ARTIFACTS[@]}"
else
  log_info "Creating release ${RELEASE_TAG}"
  gh release create "${RELEASE_TAG}" \
    --repo "${GITHUB_ORG}/${GITHUB_REPO}" \
    --title "XanMod ${PKG_VERSION}" \
    --notes "${RELEASE_NOTES}" \
    "${ARTIFACTS[@]}"
fi

log_info "Release published: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/tag/${RELEASE_TAG}"
