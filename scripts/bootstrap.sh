#!/usr/bin/env bash
# bootstrap.sh — install build dependencies for xanmod-unified-kernel
#
# Supports Debian, Devuan, Ubuntu. Installs:
#   - kernel build tools (build-essential, flex, bison, etc.)
#   - cross-compiler toolchains for requested ARCH (or all if ARCH=all)
#   - Docker (for OCI builds) if not already present
#   - gh CLI (for release publishing) if not already present

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/detect.sh"

ARCH="${ARCH:-amd64}"
INSTALL_DOCKER="${INSTALL_DOCKER:-1}"
INSTALL_GH="${INSTALL_GH:-1}"

# ── distro check ──────────────────────────────────────────────────────────────
DISTRO_ID="$(detect_distro)"
case "${DISTRO_ID}" in
  debian|devuan|ubuntu|linuxmint|pop) ;;
  *) log_warn "Untested distro '${DISTRO_ID}' — proceeding anyway" ;;
esac

if [[ "${EUID}" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

# ── base build dependencies ───────────────────────────────────────────────────
log_step "1/4" "Installing kernel build dependencies"

BASE_PKGS=(
  build-essential
  bc
  bison
  flex
  libssl-dev
  libelf-dev
  libncurses-dev
  dwarves
  pahole
  debhelper
  dpkg-dev
  fakeroot
  rsync
  git
  curl
  wget
  cpio
  kmod
  python3
  python3-pip
  zstd
  lz4
  xz-utils
  zlib1g-dev
  libudev-dev
)

${SUDO} apt-get update -qq
${SUDO} apt-get install -y --no-install-recommends "${BASE_PKGS[@]}"

# ── cross-compiler toolchains ─────────────────────────────────────────────────
log_step "2/4" "Installing cross-compiler toolchains"

if [[ "${ARCH}" == "all" ]]; then
  CROSS_ARCHES=(arm64 armhf armel i686 ppc64el s390x riscv64 mips64el loong64)
else
  CROSS_ARCHES=("${ARCH}")
fi

HOST="$(host_arch)"
CROSS_PKGS=()
for arch in "${CROSS_ARCHES[@]}"; do
  if [[ "${arch}" != "${HOST}" ]]; then
    pkg="$(cross_compiler_pkg "${arch}")"
    [[ -n "${pkg}" ]] && CROSS_PKGS+=("${pkg}")
  fi
done

if [[ ${#CROSS_PKGS[@]} -gt 0 ]]; then
  log_info "Installing: ${CROSS_PKGS[*]}"
  ${SUDO} apt-get install -y --no-install-recommends "${CROSS_PKGS[@]}" || \
    log_warn "Some cross-compiler packages unavailable on this distro/release — skipping"
else
  log_info "No cross-compiler needed (native build)"
fi

# ── Docker ────────────────────────────────────────────────────────────────────
log_step "3/4" "Checking Docker"

if [[ "${INSTALL_DOCKER}" == "1" ]]; then
  if command -v docker &>/dev/null; then
    log_info "Docker already installed: $(docker --version)"
  else
    log_info "Installing Docker via convenience script"
    curl -fsSL https://get.docker.com | ${SUDO} sh
    ${SUDO} usermod -aG docker "${USER:-root}" || true
    log_info "Docker installed — you may need to log out and back in for group membership"
  fi
else
  log_info "Skipping Docker install (INSTALL_DOCKER=0)"
fi

# ── gh CLI ────────────────────────────────────────────────────────────────────
log_step "4/4" "Checking gh CLI"

if [[ "${INSTALL_GH}" == "1" ]]; then
  if command -v gh &>/dev/null; then
    log_info "gh already installed: $(gh --version | head -1)"
  else
    log_info "Installing gh CLI"
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | ${SUDO} dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
      https://cli.github.com/packages stable main" \
      | ${SUDO} tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    ${SUDO} apt-get update -qq
    ${SUDO} apt-get install -y gh
  fi
else
  log_info "Skipping gh install (INSTALL_GH=0)"
fi

log_info "Bootstrap complete"
