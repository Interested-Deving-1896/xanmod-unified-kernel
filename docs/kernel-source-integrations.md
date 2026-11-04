# Kernel source integration map

This document records upstream kernel source relationships for XanMod Unified Kernel and defines how additional source trees can be evaluated safely.

## Source roles

| Project | Role | Integration policy |
|---|---|---|
| [torvalds/linux](https://github.com/torvalds/linux) | Canonical upstream Linux source and vanilla baseline | Reference for kernel.org tarball fallback, version comparison, patch-base validation, and future opt-in vanilla builds. |
| [Interested-Deving-1896/linux-merge](https://github.com/Interested-Deving-1896/linux-merge) | Downstream Linux integration tree containing subsystem/development branches | Optional integration candidate. Pin a specific reviewed branch/ref and commit; do not assume its many development branches form one release-ready source. |
| [xanmod/linux](https://gitlab.com/xanmod/linux) | Existing XanMod patch/source input | Preserve as the source of XanMod-specific patch series. |
| Distro kernel base repositories | Preferred source tree when a matching base repository is populated and marked READY | Preserve existing distro/architecture base selection and readiness checks. |

## Safe integration contract

- Preserve the current distro/architecture base repository selection and kernel.org fallback.
- Preserve XanMod's existing patch source and branch selection.
- Use torvalds/linux as the canonical vanilla baseline for source comparison and patch-base validation.
- Evaluate linux-merge as an explicit opt-in source candidate, not an automatic replacement for distro kernel bases or XanMod's patch source.
- Any future source selector must require an explicit source ID and branch/ref, record the resolved commit SHA, and validate compatibility with the selected XanMod patch series.
- Before enabling package builds from either source, verify kernel version alignment, patch applicability, configuration compatibility, architecture support, packaging behavior, and reproducible provenance.
- Do not automatically merge linux-merge subsystem/development branches into the default build source.

## Current implementation status

This change records and links the source relationships only. The current build path still prefers populated distro kernel base repositories and otherwise falls back to a kernel.org vanilla tarball; XanMod patches continue to come from the existing XanMod source. No build defaults are changed.
