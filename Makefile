# xanmod-unified-kernel — build XanMod kernel .deb packages for all supported distros/arches
#
# Usage:
#   make build                        # build for DISTRO=debian ARCH=amd64
#   make build DISTRO=ubuntu ARCH=arm64
#   make all-tier1                    # build all Tier 1 distro+arch combos
#   make oci                          # build OCI image after .deb build
#   make release                      # publish GitHub Release
#   make bootstrap                    # install build dependencies

SHELL := /bin/bash
.DEFAULT_GOAL := help

# ── defaults ──────────────────────────────────────────────────────────────────
DISTRO         ?= debian
ARCH           ?= amd64
XANMOD_BRANCH  ?= main
XANMOD_REPO    ?= https://gitlab.com/xanmod/linux.git
XANMOD_REPO_FB ?= https://github.com/xanmod/linux.git

# ── tier definitions ──────────────────────────────────────────────────────────
TIER1_ARCHES   := amd64 arm64
TIER2_ARCHES   := armhf riscv64 s390x
TIER3_ARCHES   := armel ppc64el mips64el loong64 i686
ALL_ARCHES     := $(TIER1_ARCHES) $(TIER2_ARCHES) $(TIER3_ARCHES)
DISTROS        := debian devuan ubuntu

# ── paths ─────────────────────────────────────────────────────────────────────
BUILD_DIR      := build
CACHE_DIR      := .cache
PATCHES_DIR    := patches
OUTPUT_DIR     := output

# ── targets ───────────────────────────────────────────────────────────────────

.PHONY: build
build: ## Build kernel .deb for DISTRO+ARCH (defaults: debian, amd64)
	@bash scripts/build.sh

.PHONY: install
install: ## Install built .deb packages onto the current system
	@dpkg -i $(OUTPUT_DIR)/$(DISTRO)/$(ARCH)/*.deb

.PHONY: oci
oci: ## Build OCI image containing the kernel .deb packages
	@bash scripts/build-oci.sh

.PHONY: release
release: ## Publish GitHub Release with .deb artifacts
	@bash scripts/publish-release.sh

.PHONY: fetch-base
fetch-base: ## Fetch distro kernel base repo (source tree)
	@bash scripts/fetch-base.sh

.PHONY: fetch-patches
fetch-patches: ## Fetch XanMod patch series from upstream
	@bash scripts/fetch-patches.sh

.PHONY: apply-patches
apply-patches: ## Apply XanMod patches to source tree
	@bash scripts/apply-patches.sh

.PHONY: bootstrap
bootstrap: ## Install build dependencies
	@bash scripts/bootstrap.sh

.PHONY: clean
clean: ## Remove build artifacts (keeps .cache)
	@rm -rf $(BUILD_DIR) $(OUTPUT_DIR) $(PATCHES_DIR)

.PHONY: distclean
distclean: clean ## Remove build artifacts and patch cache
	@rm -rf $(CACHE_DIR)

# ── tier matrix targets ───────────────────────────────────────────────────────

.PHONY: all-tier1
all-tier1: ## Build all Tier 1 arches (amd64, arm64) for all distros
	@for distro in $(DISTROS); do \
	  for arch in $(TIER1_ARCHES); do \
	    echo "==> $$distro/$$arch"; \
	    DISTRO=$$distro ARCH=$$arch bash scripts/build.sh || exit 1; \
	  done; \
	done

.PHONY: all-tier2
all-tier2: ## Build all Tier 2 arches (armhf, riscv64, s390x) for all distros
	@for distro in $(DISTROS); do \
	  for arch in $(TIER2_ARCHES); do \
	    echo "==> $$distro/$$arch"; \
	    DISTRO=$$distro ARCH=$$arch bash scripts/build.sh || exit 1; \
	  done; \
	done

.PHONY: all-tier3
all-tier3: ## Build all Tier 3 arches for all distros
	@for distro in $(DISTROS); do \
	  for arch in $(TIER3_ARCHES); do \
	    echo "==> $$distro/$$arch"; \
	    DISTRO=$$distro ARCH=$$arch bash scripts/build.sh || exit 1; \
	  done; \
	done

.PHONY: all
all: all-tier1 all-tier2 all-tier3 ## Build all tiers

# ── help ──────────────────────────────────────────────────────────────────────

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} \
	  /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
