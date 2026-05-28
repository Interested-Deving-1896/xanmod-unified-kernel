#!/usr/bin/env bash
# scripts/lkf-build.sh — lkf remix hook for xanmod-unified-kernel
#
# Called by `lkf remix` when a remix.toml contains [lkf_hook] script = "scripts/lkf-build.sh".
# Translates lkf environment variables into the xanmod-unified-kernel build pipeline.
#
# lkf sets these env vars before calling this script:
#   LKF_ARCH          target arch (x86_64, aarch64, armv7l, ...)
#   LKF_FLAVOR        kernel flavor (xanmod)
#   LKF_VERSION       kernel version string or "latest"
#   LKF_LLVM          1 if --llvm was passed
#   LKF_LTO           lto mode (none|thin|full)
#   LKF_THREADS       parallel jobs
#   LKF_OUTPUT_FORMAT output format (deb|rpm|...)
#   LKF_BUILD_DIR     build output directory
#
# [lkf_hook] env overrides are merged into the environment before this script runs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/lib/log.sh"

# ── Map lkf arch names → xanmod-unified-kernel ARCH names ────────────────────
lkf_arch="${LKF_ARCH:-${ARCH:-amd64}}"
case "${lkf_arch}" in
  x86_64|amd64)   export ARCH="amd64" ;;
  aarch64|arm64)  export ARCH="arm64" ;;
  armv7l|armhf)   export ARCH="armhf" ;;
  riscv64)        export ARCH="riscv64" ;;
  ppc64le|ppc64el) export ARCH="ppc64el" ;;
  s390x)          export ARCH="s390x" ;;
  i686|i386)      export ARCH="i386" ;;
  *)              export ARCH="${lkf_arch}" ;;
esac

# ── Propagate lkf build settings ─────────────────────────────────────────────
export JOBS="${LKF_THREADS:-${JOBS:-$(nproc)}}"
export DISTRO="${DISTRO:-debian}"
export XANMOD_BRANCH="${XANMOD_BRANCH:-main}"

# Compiler settings
if [[ "${LKF_LLVM:-0}" == "1" ]]; then
  export CC="clang"
  export LLVM=1
  export LLVM_IAS=1
fi

# LTO
if [[ "${LKF_LTO:-none}" != "none" ]]; then
  export LTO="${LKF_LTO}"
fi

# Output format
if [[ "${LKF_OUTPUT_FORMAT:-deb}" != "deb" ]]; then
  log_warn "xanmod-unified-kernel only supports deb output; ignoring format '${LKF_OUTPUT_FORMAT}'"
fi

# Build directory
if [[ -n "${LKF_BUILD_DIR:-}" ]]; then
  export BUILD_DIR="${LKF_BUILD_DIR}"
  export OUTPUT_DIR="${LKF_BUILD_DIR}/output"
fi

log_info "lkf-build.sh: DISTRO=${DISTRO} ARCH=${ARCH} BRANCH=${XANMOD_BRANCH} JOBS=${JOBS}"
[[ "${LKF_LLVM:-0}" == "1" ]] && log_info "  compiler: clang/LLVM (LTO=${LKF_LTO:-none})"

# ── Delegate to the main build pipeline ──────────────────────────────────────
exec bash "${SCRIPT_DIR}/build.sh" "$@"
