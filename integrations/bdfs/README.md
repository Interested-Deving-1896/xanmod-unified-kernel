# Btrfs-DwarFS Framework (BDFS) integration

This directory documents the optional external-module build path for
[Btrfs-DwarFS Framework](https://github.com/Interested-Deving-1896/btrfs-dwarfs-framework).

## Current status and scope

BDFS currently builds as an **out-of-tree kernel module** named
`btrfs_dwarfs.ko`. Its Kconfig symbol is `CONFIG_BTRFS_DWARFS`, and its
registered filesystem type is `bdfs_blend`. The module does not currently
provide an in-tree `fs/bdfs/` implementation or establish that `bdfs` can
be used as a standalone root filesystem.

The former `bdfs-profile` recipe attempted to call a BDFS installer under
`kernels/bdfs-kconfig/` and compile from `fs/btrfs_dwarfs`. Those paths do
not exist in the current BDFS repository, so that recipe was not compatible
with the actual external-module layout. The legacy
`integrations/bdfs/Kconfig.fragment` is retained as a warning-only stub; do
not merge it into the kernel config.

## Build the module

Prerequisites:
- Build and configure the XanMod kernel tree first, including generated
  headers and `.config`.
- Check out the BDFS integration branch that provides
  `integrations/kernels/build-module.sh`, or use a BDFS revision where that
  helper has been merged.
- Do not use `make install` or load the module as part of this build target.

Example after the kernel source tree is configured/built:

```sh
make bdfs-module \
  DISTRO=debian ARCH=amd64 \
  BDFS_DIR=/path/to/btrfs-dwarfs-framework
```

The default kernel build tree is
`build/<distro>/<arch>/src`; override it with `KERNEL_BUILD_DIR=/path/to/tree`
if the configured tree lives elsewhere. The output is staged at
`output/<distro>/<arch>/bdfs/btrfs_dwarfs.ko` by default. This target builds
and stages the module only: it does not install it, load it, modify kernel
boot parameters, or package it into the generated kernel `.deb` files.

`make bdfs-module-only` remains as a compatibility alias for
`make bdfs-module`.

## Validation still required

- Compile against each supported XanMod kernel version and architecture.
- Package the module separately with correct kernel-version dependencies and
  signing policy; do not silently insert it into the kernel package.
- Test load/unload and `bdfs_blend` mount/unmount on disposable VMs.
- Test initramfs behavior separately. Do not change default boot/rootfs
  configuration until runtime and recovery tests pass.

## Kernel priority in the BDFS project

1. `liqxanmod` — intended primary/default kernel
2. `xanmod-unified-kernel` — intended secondary fallback
3. `liquorix-unified-kernel` — intended secondary fallback
4. Custom kernel — user/developer hook

This priority is project intent, not evidence that the kernels have passed
BDFS build, package, or boot validation.
