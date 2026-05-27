#!/usr/bin/env bash
# apply-patches.sh — apply XanMod patch series to the source tree
#
# Applies patches from PATCHES_DIR to SRC_DIR using git am.
# Skips patches that are already applied (idempotent).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/lib/log.sh"

PATCHES_DIR="${PATCHES_DIR:-${REPO_ROOT}/patches}"
SRC_DIR="${SRC_DIR:-${REPO_ROOT}/build/${DISTRO:-debian}/${ARCH:-amd64}/src}"

if [[ ! -d "${PATCHES_DIR}" ]]; then
  die "Patches directory not found: ${PATCHES_DIR} — run fetch-patches.sh first"
fi

PATCH_FILES=("${PATCHES_DIR}"/*.patch)
if [[ ! -e "${PATCH_FILES[0]}" ]]; then
  die "No .patch files found in ${PATCHES_DIR} — run fetch-patches.sh first"
fi

PATCH_COUNT="${#PATCH_FILES[@]}"
log_step "apply-patches" "Applying ${PATCH_COUNT} XanMod patches to ${SRC_DIR}"

if [[ ! -d "${SRC_DIR}" ]]; then
  die "Source directory not found: ${SRC_DIR} — run fetch-base.sh first"
fi

cd "${SRC_DIR}"

# Initialise a git repo in the source tree if not already one
# (vanilla tarball extractions won't have .git)
if [[ ! -d ".git" ]]; then
  log_info "Initialising git repo in source tree for patch application"
  git init -q
  git config user.email "build@xanmod-unified-kernel"
  git config user.name "xanmod-unified-kernel build"
  git add -A
  git commit -q -m "vanilla kernel source"
fi

# Check if patches already applied by looking for a marker commit
MARKER="xanmod-patches-applied"
if git log --oneline --grep="${MARKER}" | grep -q .; then
  log_info "XanMod patches already applied — skipping"
  exit 0
fi

# Apply patches
log_info "Running git am on ${PATCH_COUNT} patches"
git am --no-gpg-sign "${PATCHES_DIR}"/*.patch

# Write marker commit so we can detect re-runs
git commit --allow-empty -q -m "${MARKER}: $(cat "${PATCHES_DIR}/VERSION" 2>/dev/null | grep kernel_version | cut -d= -f2)"

log_info "All ${PATCH_COUNT} patches applied successfully"
