#!/usr/bin/env bash
# fetch-base.sh — fetch the distro kernel base source tree
#
# Checks whether a {distro}-{arch}-kernel-base repo exists and has content.
# If populated, clones it as the source tree (preferred path).
# If not yet populated, falls back to fetching a vanilla kernel tarball
# matching the XanMod target version.
#
# The base repo readiness check: looks for a sentinel file "READY" at repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/lib/log.sh"

DISTRO="${DISTRO:-debian}"
ARCH="${ARCH:-amd64}"
XANMOD_BRANCH="${XANMOD_BRANCH:-main}"
GITHUB_ORG="${GITHUB_ORG:-Interested-Deving-1896}"
GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

BUILD_DIR="${BUILD_DIR:-${REPO_ROOT}/build/${DISTRO}/${ARCH}}"
SRC_DIR="${SRC_DIR:-${BUILD_DIR}/src}"
CACHE_DIR="${CACHE_DIR:-${REPO_ROOT}/.cache}"

BASE_REPO_NAME="${DISTRO}-${ARCH}-kernel-base"
BASE_REPO_URL="https://github.com/${GITHUB_ORG}/${BASE_REPO_NAME}.git"

mkdir -p "${BUILD_DIR}" "${CACHE_DIR}"

# ── check base repo readiness ─────────────────────────────────────────────────
check_base_repo_ready() {
  local url="$1"
  # Use gh API to check for READY sentinel file (avoids full clone for readiness check)
  if [[ -n "${GH_TOKEN}" ]]; then
    local api_url="https://api.github.com/repos/${GITHUB_ORG}/${BASE_REPO_NAME}/contents/READY"
    local http_code
    http_code="$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token ${GH_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "${api_url}")"
    [[ "${http_code}" == "200" ]]
  else
    # Without token, try a shallow clone and check
    git ls-remote --exit-code "${url}" HEAD &>/dev/null
  fi
}

# ── clone base repo ───────────────────────────────────────────────────────────
clone_base_repo() {
  local url="$1"
  local dest="$2"

  if [[ -n "${GH_TOKEN}" ]]; then
    # Inject token into URL for authenticated clone
    local auth_url="${url/https:\/\//https:\/\/${GH_TOKEN}@}"
    git clone --depth=1 "${auth_url}" "${dest}"
  else
    git clone --depth=1 "${url}" "${dest}"
  fi
}

# ── fallback: fetch vanilla kernel tarball ────────────────────────────────────
fetch_vanilla_fallback() {
  local dest="$1"

  # Read target version from XanMod VERSION file if available
  local version_file="${REPO_ROOT}/patches/VERSION"
  if [[ -f "${version_file}" ]]; then
    KERNEL_VERSION="$(grep kernel_version "${version_file}" | cut -d= -f2)"
  else
    # Default to a known-good version; will be overridden by fetch-patches
    KERNEL_VERSION="${KERNEL_VERSION:-6.12.0}"
  fi

  local major_minor="${KERNEL_VERSION%.*}"
  local major="${KERNEL_VERSION%%.*}"
  local tarball_url="https://cdn.kernel.org/pub/linux/kernel/v${major}.x/linux-${KERNEL_VERSION}.tar.xz"
  local tarball_cache="${CACHE_DIR}/linux-${KERNEL_VERSION}.tar.xz"

  log_info "Fetching vanilla kernel ${KERNEL_VERSION} from kernel.org"

  if [[ ! -f "${tarball_cache}" ]]; then
    curl -fL --progress-bar "${tarball_url}" -o "${tarball_cache}" \
      || die "Failed to download ${tarball_url}"
  else
    log_info "Using cached tarball: ${tarball_cache}"
  fi

  log_info "Extracting to ${dest}"
  mkdir -p "${dest}"
  tar -xf "${tarball_cache}" --strip-components=1 -C "${dest}"
}

# ── main ──────────────────────────────────────────────────────────────────────
log_step "fetch-base" "Resolving source tree for ${DISTRO}/${ARCH}"

if [[ -d "${SRC_DIR}/.git" ]] || [[ -f "${SRC_DIR}/Makefile" ]]; then
  log_info "Source tree already present at ${SRC_DIR} — skipping fetch"
  exit 0
fi

log_info "Checking base repo: ${BASE_REPO_NAME}"

if check_base_repo_ready "${BASE_REPO_URL}"; then
  log_info "Base repo is ready — cloning ${BASE_REPO_URL}"
  clone_base_repo "${BASE_REPO_URL}" "${SRC_DIR}"
  log_info "Source tree from base repo: ${SRC_DIR}"
else
  log_warn "Base repo '${BASE_REPO_NAME}' not yet populated (READY sentinel missing)"
  log_info "Falling back to vanilla kernel tarball"
  fetch_vanilla_fallback "${SRC_DIR}"
  log_info "Source tree from kernel.org: ${SRC_DIR}"
fi
