## Current status

The kernel-side implementation is no longer considered unavailable: Nitrux publishes [patch 0009-aesthetic-fhs.patch](https://github.com/Nitrux/linux-kernel/blob/linux-nitrux/patches/0009-aesthetic-fhs.patch) in its `linux-nitrux` branch, and includes it in the patch series for a kernel source version identified as 7.3.1. This does not establish that the patch applies cleanly to the kernel bases supported here.

## Required design

- Preserve existing XanMod defaults and build behavior.
- Do not claim support by adding a Kconfig fragment alone; the implementation must be applied and validated.
- Review and pin the Nitrux kernel patch, then test its applicability against every supported XanMod kernel base/version before adding an opt-in config/build path.
- Review namespace and inode lifetime handling, directory enumeration hooks, Generic Netlink permissions, command/attribute ABI, and graceful behavior when the family is absent.
- Validate the `aesthetic_fhs` Generic Netlink family and runtime behavior before enabling the `afhs` userspace package.
- Treat Nitrux Standard as an optional userspace profile. Its metapackage is `Architecture: all`, but its dependency set must still be resolved per distro release and target architecture.
- Preserve source provenance and file-level license notices. Do not vendor `afhs` until the repository BSD-3-Clause declaration and GPL-2.0 SPDX identifiers on source/header files are reconciled.

## Acceptance gates

1. Pin the kernel patch and source version.
2. Review licensing, patch correctness, and applicability against supported XanMod kernel versions.
3. Build enabled/disabled configurations for supported architectures.
4. Boot-test Generic Netlink family discovery and controller operations.
5. Confirm clean fallback when the kernel capability is absent.

Upstream: https://github.com/Nitrux/aesthetic-fhs ; https://github.com/Nitrux/nitrux-standard ; https://github.com/Nitrux/linux-kernel/blob/linux-nitrux/patches/0009-aesthetic-fhs.patch

Documentation only; no runtime support is claimed.