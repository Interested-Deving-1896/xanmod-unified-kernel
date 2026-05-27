#!/usr/bin/env bash
# build-with-base.sh — wrapper around build.sh that substitutes the distro
# kernel base repo as the source tree when it is available.
#
# This script is the entry point for base-integrated builds. It:
#   1. Calls fetch-base.sh to resolve the source tree (base repo or fallback)
#   2. Exports SRC_DIR so build.sh uses the resolved tree
#   3. Delegates to build.sh for the rest of the build
#
# Environment variables:
#   DISTRO, ARCH, XANMOD_BRANCH, etc. — same as build.sh
#   FORCE_FALLBACK=1 — skip base repo check, always use kernel.org tarball
#   BASE_REPO_OVERRIDE — use a specific base repo URL instead of auto-resolving

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# lib/ may be at scripts/lib/ (xanmod) or lib/ (liquorix) — try both
if [[ -f "${SCRIPT_DIR}/lib/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/log.sh"
elif [[ -f "${REPO_ROOT}/lib/log.sh" ]]; then
  source "${REPO_ROOT}/lib/log.sh"
else
  # Minimal fallback logging
  log_info()  { echo "[INFO]  $*"; }
  log_warn()  { echo "[WARN]  $*" >&2; }
  log_error() { echo "[ERROR] $*" >&2; }
  log_step()  { echo "==> Step $1: $2"; }
  die()       { log_error "$*"; exit 1; }
fi

DISTRO="${DISTRO:-debian}"
ARCH="${ARCH:-amd64}"
FORCE_FALLBACK="${FORCE_FALLBACK:-0}"

BUILD_DIR="${REPO_ROOT}/build/${DISTRO}/${ARCH}"
SRC_DIR="${BUILD_DIR}/src"
export BUILD_DIR SRC_DIR

log_step "build-with-base" "Resolving source tree for ${DISTRO}/${ARCH}"

if [[ "${FORCE_FALLBACK}" == "1" ]]; then
  log_info "FORCE_FALLBACK=1 — skipping base repo check"
  export SKIP_BASE_REPO=1
fi

# Override base repo URL if specified
if [[ -n "${BASE_REPO_OVERRIDE:-}" ]]; then
  log_info "Using BASE_REPO_OVERRIDE: ${BASE_REPO_OVERRIDE}"
  export BASE_REPO_URL="${BASE_REPO_OVERRIDE}"
fi

# Fetch source tree (base repo or fallback)
bash "${SCRIPT_DIR}/fetch-base.sh"

# Delegate to the main build script
log_info "Source tree ready at ${SRC_DIR} — delegating to build.sh"
exec bash "${SCRIPT_DIR}/build.sh"
