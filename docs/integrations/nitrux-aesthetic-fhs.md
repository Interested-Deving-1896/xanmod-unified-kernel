## Current status

No verified Nitrux Aesthetic FHS kernel implementation or `CONFIG_NITRUX_AESTHETIC_FHS` integration is present in this repository. The inspected upstream `aesthetic-fhs` project is a userspace Generic Netlink controller; it does not provide the kernel-side implementation.

## Required design

- Preserve existing XanMod defaults and build behavior.
- Do not claim support by adding a Kconfig fragment alone.
- Add an opt-in config/build path only after a pinned, authoritative kernel patch/source tree is available and reviewed for applicability to the XanMod base.
- Validate the `aesthetic_fhs` Generic Netlink family, ABI, permissions, and runtime behavior before enabling the `afhs` userspace package.
- Treat Nitrux Standard as an optional userspace profile. Its metapackage is `Architecture: all`, but its dependency set must still be resolved per distro release and target architecture.
- Preserve source provenance and file-level license notices. Do not vendor `afhs` until the repository BSD-3-Clause declaration and GPL-2.0 SPDX identifiers on source/header files are reconciled.

## Acceptance gates

1. Pin and review kernel implementation and licensing.
2. Verify patch applicability against each supported XanMod kernel source version.
3. Build enabled/disabled configurations for supported architectures.
4. Boot-test Generic Netlink family discovery and controller operations.
5. Confirm clean fallback when the kernel capability is absent.

Upstream: https://github.com/Nitrux/aesthetic-fhs ; https://github.com/Nitrux/nitrux-standard

Documentation only; no runtime support is claimed.