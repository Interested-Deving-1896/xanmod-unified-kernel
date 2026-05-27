#!/usr/bin/env bash
# build.sh — orchestrate a full XanMod kernel .deb build
#
# Environment variables (all optional, have defaults):
#   DISTRO          target distro (debian|devuan|ubuntu)  default: debian
#   ARCH            target arch                           default: amd64
#   XANMOD_BRANCH   XanMod git branch                    default: main
#   XANMOD_REPO     primary XanMod git URL               default: gitlab.com/xanmod/linux.git
#   XANMOD_REPO_FB  fallback XanMod git URL              default: github.com/xanmod/linux.git
#   JOBS            parallel make jobs                   default: nproc
#   SKIP_FETCH      skip re-fetching if cache exists     default: 0
#   SKIP_OCI        skip OCI image build                 default: 0
#   SKIP_RELEASE    skip GitHub Release publish          default: 1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/detect.sh
source "${SCRIPT_DIR}/lib/detect.sh"

# ── configuration ─────────────────────────────────────────────────────────────
DISTRO="${DISTRO:-debian}"
ARCH="${ARCH:-amd64}"
XANMOD_BRANCH="${XANMOD_BRANCH:-main}"
XANMOD_REPO="${XANMOD_REPO:-https://gitlab.com/xanmod/linux.git}"
XANMOD_REPO_FB="${XANMOD_REPO_FB:-https://github.com/xanmod/linux.git}"
JOBS="${JOBS:-$(nproc)}"
SKIP_FETCH="${SKIP_FETCH:-0}"
SKIP_OCI="${SKIP_OCI:-0}"
SKIP_RELEASE="${SKIP_RELEASE:-1}"

BUILD_DIR="${REPO_ROOT}/build/${DISTRO}/${ARCH}"
OUTPUT_DIR="${REPO_ROOT}/output/${DISTRO}/${ARCH}"
PATCHES_DIR="${REPO_ROOT}/patches"
CACHE_DIR="${REPO_ROOT}/.cache"
SRC_DIR="${BUILD_DIR}/src"

export DISTRO ARCH XANMOD_BRANCH XANMOD_REPO XANMOD_REPO_FB
export BUILD_DIR OUTPUT_DIR PATCHES_DIR CACHE_DIR SRC_DIR

# ── arch mapping ──────────────────────────────────────────────────────────────
KARCH="$(karch_for "${ARCH}")"
export KARCH

# cross-compilation setup
if [[ "${ARCH}" != "$(host_arch)" ]]; then
  CROSS_COMPILE="$(cross_compile_for "${ARCH}")"
  export CROSS_COMPILE
  log_info "Cross-compiling for ${ARCH} (KARCH=${KARCH}, CROSS_COMPILE=${CROSS_COMPILE})"
else
  log_info "Native build for ${ARCH} (KARCH=${KARCH})"
fi

# ── step 1: fetch base source tree ────────────────────────────────────────────
log_step "1/6" "Fetching distro kernel base"
if [[ "${SKIP_FETCH}" == "0" ]] || [[ ! -d "${SRC_DIR}" ]]; then
  bash "${SCRIPT_DIR}/fetch-base.sh"
else
  log_info "Skipping fetch-base (SKIP_FETCH=1 and ${SRC_DIR} exists)"
fi

# ── step 2: fetch XanMod patches ─────────────────────────────────────────────
log_step "2/6" "Fetching XanMod patch series (branch: ${XANMOD_BRANCH})"
if [[ "${SKIP_FETCH}" == "0" ]] || [[ ! -d "${PATCHES_DIR}" ]]; then
  bash "${SCRIPT_DIR}/fetch-patches.sh"
else
  log_info "Skipping fetch-patches (SKIP_FETCH=1 and ${PATCHES_DIR} exists)"
fi

# ── step 3: apply patches ─────────────────────────────────────────────────────
log_step "3/6" "Applying XanMod patches"
bash "${SCRIPT_DIR}/apply-patches.sh"

# ── step 4: configure kernel ──────────────────────────────────────────────────
log_step "4/6" "Configuring kernel for ${DISTRO}/${ARCH}"
mkdir -p "${SRC_DIR}"
cd "${SRC_DIR}"

# merge distro config fragments
CONFIG_BASE="${REPO_ROOT}/configs/${DISTRO}/config.base"
CONFIG_ARCH="${REPO_ROOT}/configs/${DISTRO}/config.${ARCH}"
CONFIG_XANMOD="${REPO_ROOT}/configs/xanmod-fragments/config.xanmod"

if [[ -f "${CONFIG_BASE}" ]]; then
  cat "${CONFIG_BASE}" >> .config
fi
if [[ -f "${CONFIG_ARCH}" ]]; then
  cat "${CONFIG_ARCH}" >> .config
fi
if [[ -f "${CONFIG_XANMOD}" ]]; then
  cat "${CONFIG_XANMOD}" >> .config
fi

# resolve config (olddefconfig is non-interactive)
make ARCH="${KARCH}" ${CROSS_COMPILE:+CROSS_COMPILE="${CROSS_COMPILE}"} olddefconfig

# ── step 5: build .deb packages ───────────────────────────────────────────────
log_step "5/6" "Building kernel .deb packages"

# derive package version: upstream_version+xanmod1~distro1
KERNEL_VERSION="$(make -s kernelversion)"
XANMOD_VERSION="$(cat "${PATCHES_DIR}/VERSION" 2>/dev/null | grep xanmod_version | cut -d= -f2 || echo "1")"
KDEB_PKGVERSION="${KERNEL_VERSION}+xanmod${XANMOD_VERSION}~${DISTRO}1"
export KDEB_PKGVERSION

mkdir -p "${OUTPUT_DIR}"

make -j"${JOBS}" \
  ARCH="${KARCH}" \
  ${CROSS_COMPILE:+CROSS_COMPILE="${CROSS_COMPILE}"} \
  KDEB_PKGVERSION="${KDEB_PKGVERSION}" \
  DPKG_FLAGS="-d" \
  bindeb-pkg

# move .deb files to output dir
find "${BUILD_DIR}" -maxdepth 1 -name "*.deb" -exec mv {} "${OUTPUT_DIR}/" \;
find "${BUILD_DIR}" -maxdepth 1 -name "*.changes" -exec mv {} "${OUTPUT_DIR}/" \;

log_info "Packages written to ${OUTPUT_DIR}/"
ls -lh "${OUTPUT_DIR}/"*.deb

# ── step 6: OCI image ─────────────────────────────────────────────────────────
if [[ "${SKIP_OCI}" == "0" ]]; then
  log_step "6/6" "Building OCI image"
  bash "${SCRIPT_DIR}/build-oci.sh"
else
  log_info "Skipping OCI build (SKIP_OCI=1)"
fi

# ── step 7: publish release ───────────────────────────────────────────────────
if [[ "${SKIP_RELEASE}" == "0" ]]; then
  log_step "7/7" "Publishing GitHub Release"
  bash "${SCRIPT_DIR}/publish-release.sh"
else
  log_info "Skipping release publish (SKIP_RELEASE=1)"
fi

log_info "Build complete: ${DISTRO}/${ARCH} — ${KDEB_PKGVERSION}"
