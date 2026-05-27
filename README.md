# xanmod-unified-kernel

Builds [XanMod](https://xanmod.org) kernel `.deb` packages for Debian, Devuan, and Ubuntu across all supported architectures.

## Supported targets

| Tier | Arches |
|---|---|
| Tier 1 | amd64, arm64 |
| Tier 2 | armhf, riscv64, s390x |
| Tier 3 | armel, ppc64el, mips64el, loong64, i686 |

Distros: Debian, Devuan, Ubuntu.

## Quick start

```bash
# Install build dependencies
make bootstrap

# Build for debian/amd64 (default)
make build

# Build for a specific target
make build DISTRO=ubuntu ARCH=arm64

# Build all Tier 1 targets
make all-tier1
```

## Outputs

- `.deb` packages in `output/{distro}/{arch}/`
- OCI image: `ghcr.io/Interested-Deving-1896/xanmod-unified-kernel:{version}-{arch}`
- GitHub Release with all `.deb` artifacts

## Source

XanMod patches are fetched from:
- Primary: `gitlab.com/xanmod/linux` (branch: `main`)
- Fallback: `github.com/xanmod/linux`

The source tree is resolved from `{distro}-{arch}-kernel-base` repos when available, falling back to a vanilla kernel tarball from kernel.org.

## Configuration

Config fragments are layered in order:
1. `configs/{distro}/config.base`
2. `configs/{distro}/config.{arch}`
3. `configs/xanmod-fragments/config.xanmod`

See [AGENTS.md](AGENTS.md) for full build system documentation.
