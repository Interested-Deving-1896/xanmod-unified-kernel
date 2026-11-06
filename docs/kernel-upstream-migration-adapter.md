# XanMod Unified Kernel KUMBE provider adapter

This document records the actual XanMod source-resolution and patch-generation boundaries for a future KUMBE adapter. It is a read-only integration contract, not an implementation of migration or backport execution.

## Provider source paths

XanMod currently has two related but distinct source paths:

- `kernel/fetch.sh` resolves MAIN/EDGE/LTS/RT labels to XanMod GitLab branches and clones/updates `kernel/src`.
- `scripts/fetch-base.sh` resolves a distro/architecture kernel-base repository when available, otherwise falls back to a kernel.org vanilla tarball.
- `scripts/fetch-patches.sh` clones the XanMod source (GitLab primary, GitHub fallback), derives a patch series relative to a vanilla base tag, and writes `patches/VERSION`.
- `scripts/apply-patches.sh` applies generated patches with `git am`.
- `build.sh` coordinates the build; it defaults to installation unless explicitly disabled.

These are not interchangeable source trees. The adapter must identify which path and exact source tree produced a candidate.

## Adapter requirements

1. Preserve the requested MAIN/EDGE/LTS/RT lane and resolve it to an actual upstream ref and immutable commit. Never silently replace a missing lane with another.
2. Record the distro/architecture base repository (including its READY/version metadata) or the exact kernel.org tarball and digest.
3. Record the XanMod patch source repository, ref, commit, merge-base/base tag, generated patch count, and per-patch digest from `patches/VERSION` plus the patch files.
4. Treat the shallow-history fallback in `scripts/fetch-patches.sh` as an unresolved provenance limitation: if the vanilla base tag and reliable merge-base cannot be established, block a reproducible migration plan rather than treating the oldest shallow commit as a verified base.
5. Preserve generated patch queues. The current fetcher removes existing `*.patch` files before regenerating; KUMBE must inventory and preserve the prior queue before any refresh.
6. Never call the normal build path for discovery. If a later build is authorized, use explicit no-install behavior and isolated worktrees.

## Initial adapter stages

- **Stage 0 — inventory:** lane/ref/commit, base source identity, generated patch metadata, patch hashes, config fragments, distro, architecture, and build options.
- **Stage 1 — dry run:** dependency, applicability, Kconfig, ABI, and risk analysis with no writes.
- **Stage 2 — isolated apply:** preserve the original queue, pin both source inputs, preflight patches, and stop on provenance gaps or conflicts.
- **Stage 3 — validation:** kernel config resolution, architecture/toolchain builds, module builds, package checks, and boot/runtime evidence where available.

No kernel source, patch queue, configuration, or installation state is changed by this documentation.