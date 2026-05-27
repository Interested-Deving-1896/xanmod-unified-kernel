#!/usr/bin/env bash
# build-oci.sh — build an OCI image containing the kernel .deb packages
#
# The image is a minimal Debian/Ubuntu base with the .deb files installed,
# tagged as ghcr.io/{org}/xanmod-unified-kernel:{version}-{distro}-{arch}

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/lib/log.sh"

DISTRO="${DISTRO:-debian}"
ARCH="${ARCH:-amd64}"
GITHUB_ORG="${GITHUB_ORG:-Interested-Deving-1896}"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/output/${DISTRO}/${ARCH}}"
REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAME="${REGISTRY}/${GITHUB_ORG}/xanmod-unified-kernel"

# Read version from built packages
VERSION_FILE="${REPO_ROOT}/patches/VERSION"
if [[ -f "${VERSION_FILE}" ]]; then
  KERNEL_VERSION="$(grep kernel_version "${VERSION_FILE}" | cut -d= -f2)"
  XANMOD_VERSION="$(grep xanmod_version "${VERSION_FILE}" | cut -d= -f2)"
  PKG_VERSION="${KERNEL_VERSION}+xanmod${XANMOD_VERSION}~${DISTRO}1"
else
  PKG_VERSION="unknown"
fi

IMAGE_TAG="${PKG_VERSION}-${ARCH}"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

log_step "build-oci" "Building OCI image ${FULL_IMAGE}"

if [[ ! -d "${OUTPUT_DIR}" ]] || ! ls "${OUTPUT_DIR}"/*.deb &>/dev/null; then
  die "No .deb files found in ${OUTPUT_DIR} — run build.sh first"
fi

# Map Debian arch to Docker platform
case "${ARCH}" in
  amd64)   PLATFORM="linux/amd64"   ;;
  arm64)   PLATFORM="linux/arm64"   ;;
  armhf)   PLATFORM="linux/arm/v7"  ;;
  armel)   PLATFORM="linux/arm/v6"  ;;
  i686)    PLATFORM="linux/386"     ;;
  ppc64el) PLATFORM="linux/ppc64le" ;;
  s390x)   PLATFORM="linux/s390x"   ;;
  riscv64) PLATFORM="linux/riscv64" ;;
  *)       PLATFORM="linux/${ARCH}" ;;
esac

# Map distro to base image
case "${DISTRO}" in
  ubuntu)  BASE_IMAGE="ubuntu:22.04"  ;;
  devuan)  BASE_IMAGE="devuan/devuan:daedalus" ;;
  *)       BASE_IMAGE="debian:bookworm-slim"   ;;
esac

# Build context: copy .deb files into a temp dir
BUILD_CTX="$(mktemp -d)"
trap 'rm -rf "${BUILD_CTX}"' EXIT

cp "${OUTPUT_DIR}"/*.deb "${BUILD_CTX}/"

cat > "${BUILD_CTX}/Dockerfile" << DOCKERFILE
FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.source="https://github.com/${GITHUB_ORG}/xanmod-unified-kernel"
LABEL org.opencontainers.image.version="${PKG_VERSION}"
LABEL org.opencontainers.image.description="XanMod kernel packages for ${DISTRO}/${ARCH}"

COPY *.deb /tmp/kernel-debs/
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends /tmp/kernel-debs/*.deb \
 && rm -rf /tmp/kernel-debs /var/lib/apt/lists/*
DOCKERFILE

log_info "Building image for platform ${PLATFORM}"
docker buildx build \
  --platform "${PLATFORM}" \
  --tag "${FULL_IMAGE}" \
  --tag "${IMAGE_NAME}:latest-${ARCH}" \
  --load \
  "${BUILD_CTX}"

log_info "OCI image built: ${FULL_IMAGE}"

# Push if PUSH_OCI=1
if [[ "${PUSH_OCI:-0}" == "1" ]]; then
  log_info "Pushing ${FULL_IMAGE}"
  docker push "${FULL_IMAGE}"
  docker push "${IMAGE_NAME}:latest-${ARCH}"
fi
