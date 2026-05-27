#!/usr/bin/env bash
# fetch-patches.sh — fetch XanMod patch series from upstream
#
# Strategy:
#   1. Clone/update gitlab.com/xanmod/linux (primary)
#   2. Fall back to github.com/xanmod/linux if GitLab is unreachable
#   3. Find the merge-base between the XanMod branch and the vanilla base tag
#   4. Generate a patch series via git format-patch
#   5. Write VERSION metadata

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/lib/log.sh"

XANMOD_BRANCH="${XANMOD_BRANCH:-main}"
XANMOD_REPO="${XANMOD_REPO:-https://gitlab.com/xanmod/linux.git}"
XANMOD_REPO_FB="${XANMOD_REPO_FB:-https://github.com/xanmod/linux.git}"

CACHE_DIR="${CACHE_DIR:-${REPO_ROOT}/.cache}"
XANMOD_CACHE="${CACHE_DIR}/xanmod-linux"
PATCHES_DIR="${PATCHES_DIR:-${REPO_ROOT}/patches}"

mkdir -p "${CACHE_DIR}" "${PATCHES_DIR}"

# ── clone or update XanMod repo ───────────────────────────────────────────────
clone_or_update() {
  local url="$1"
  local dest="$2"
  local branch="$3"

  if [[ -d "${dest}/.git" ]]; then
    log_info "Updating XanMod cache from ${url}"
    git -C "${dest}" remote set-url origin "${url}"
    git -C "${dest}" fetch --depth=200 origin "${branch}" 2>&1 | tail -3
    git -C "${dest}" checkout -B "${branch}" "origin/${branch}"
  else
    log_info "Cloning XanMod from ${url} (branch: ${branch})"
    git clone --depth=200 --branch "${branch}" "${url}" "${dest}"
  fi
}

log_step "fetch-patches" "Fetching XanMod branch '${XANMOD_BRANCH}'"

if clone_or_update "${XANMOD_REPO}" "${XANMOD_CACHE}" "${XANMOD_BRANCH}"; then
  log_info "Fetched from primary: ${XANMOD_REPO}"
else
  log_warn "Primary fetch failed, trying fallback: ${XANMOD_REPO_FB}"
  clone_or_update "${XANMOD_REPO_FB}" "${XANMOD_CACHE}" "${XANMOD_BRANCH}" \
    || die "Both primary and fallback XanMod repos unreachable"
  log_info "Fetched from fallback: ${XANMOD_REPO_FB}"
fi

# ── extract kernel version from XanMod Makefile ───────────────────────────────
log_info "Extracting kernel version"
cd "${XANMOD_CACHE}"

KERNEL_VERSION_MAJOR="$(grep -m1 '^VERSION\s*=' Makefile | awk '{print $3}')"
KERNEL_VERSION_MINOR="$(grep -m1 '^PATCHLEVEL\s*=' Makefile | awk '{print $3}')"
KERNEL_VERSION_PATCH="$(grep -m1 '^SUBLEVEL\s*=' Makefile | awk '{print $3}')"
KERNEL_VERSION="${KERNEL_VERSION_MAJOR}.${KERNEL_VERSION_MINOR}.${KERNEL_VERSION_PATCH}"

# XanMod appends its own version suffix to EXTRAVERSION
XANMOD_EXTRAVERSION="$(grep -m1 '^EXTRAVERSION\s*=' Makefile | awk '{print $3}' || echo "")"
# Extract numeric XanMod version (e.g. "-xanmod1" → "1")
XANMOD_VERSION="$(echo "${XANMOD_EXTRAVERSION}" | grep -oP '(?<=xanmod)\d+' || echo "1")"

log_info "Kernel version: ${KERNEL_VERSION}, XanMod version: ${XANMOD_VERSION}"

# ── find vanilla base tag ─────────────────────────────────────────────────────
# XanMod branches are based on vanilla kernel tags (v6.x.y or v6.x)
# Try exact patch tag first, then minor-only tag
BASE_TAG="v${KERNEL_VERSION}"
if ! git tag -l "${BASE_TAG}" | grep -q .; then
  BASE_TAG="v${KERNEL_VERSION_MAJOR}.${KERNEL_VERSION_MINOR}"
fi

if git tag -l "${BASE_TAG}" | grep -q .; then
  log_info "Found base tag: ${BASE_TAG}"
  MERGE_BASE="$(git merge-base HEAD "${BASE_TAG}" 2>/dev/null || git rev-parse "${BASE_TAG}")"
else
  # No tag available in shallow clone — use the oldest commit in the shallow history
  log_warn "Base tag ${BASE_TAG} not in shallow clone — using oldest reachable commit"
  MERGE_BASE="$(git log --oneline | tail -1 | awk '{print $1}')"
fi

# ── generate patch series ─────────────────────────────────────────────────────
log_info "Generating patch series from ${MERGE_BASE:0:12} to HEAD"

# Clear old patches
rm -f "${PATCHES_DIR}"/*.patch

PATCH_COUNT="$(git format-patch \
  --output-directory="${PATCHES_DIR}" \
  --no-signature \
  --zero-commit \
  "${MERGE_BASE}..HEAD" | wc -l)"

log_info "Generated ${PATCH_COUNT} patches in ${PATCHES_DIR}/"

# ── write VERSION metadata ────────────────────────────────────────────────────
cat > "${PATCHES_DIR}/VERSION" << EOF
xanmod_branch=${XANMOD_BRANCH}
kernel_version=${KERNEL_VERSION}
xanmod_version=${XANMOD_VERSION}
base_tag=${BASE_TAG}
merge_base=${MERGE_BASE}
patch_count=${PATCH_COUNT}
generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

log_info "Version metadata written to ${PATCHES_DIR}/VERSION"
cat "${PATCHES_DIR}/VERSION"
