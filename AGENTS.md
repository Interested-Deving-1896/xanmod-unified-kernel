# AGENTS.md — xanmod-unified-kernel

Build system for XanMod kernel `.deb` packages across all supported distros and architectures.

## Repository layout

```
Makefile                        top-level build entry point
scripts/
  build.sh                      orchestrates a full build (fetch → patch → configure → deb → OCI → release)
  bootstrap.sh                  installs build dependencies (apt packages, Docker, gh CLI)
  fetch-base.sh                 resolves source tree: distro base repo if ready, else kernel.org tarball
  fetch-patches.sh              clones XanMod repo, generates patch series via git format-patch
  apply-patches.sh              applies patch series to source tree via git am
  build-oci.sh                  builds OCI image containing the .deb packages
  publish-release.sh            creates/updates GitHub Release with .deb artifacts
  lib/
    log.sh                      logging helpers (log_info, log_warn, log_error, log_step, die)
    detect.sh                   arch/distro detection: karch_for, cross_compile_for, host_arch
configs/
  xanmod-fragments/
    config.xanmod               XanMod-specific Kconfig fragments (scheduler, preemption, BBR2, etc.)
  debian/                       Debian base + per-arch config fragments
  devuan/                       Devuan config fragments (mirrors Debian)
  ubuntu/                       Ubuntu config fragments
packaging/
  debian/
    control.template            Debian control file template (@@PLACEHOLDERS@@ substituted at build time)
    changelog.template          Debian changelog template
.github/workflows/
  build.yml                     CI: builds Tier 1 on push/PR, manual dispatch for any distro/arch
  release.yml                   Release: full tier matrix build + OCI push + GitHub Release
  watch-upstream.yml            Scheduled: detects new XanMod commits, triggers release workflow
```

## Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `DISTRO` | `debian` | Target distro (`debian`, `devuan`, `ubuntu`) |
| `ARCH` | `amd64` | Target Debian arch name |
| `XANMOD_BRANCH` | `main` | XanMod git branch |
| `XANMOD_REPO` | `https://gitlab.com/xanmod/linux.git` | Primary XanMod source (GitLab) |
| `XANMOD_REPO_FB` | `https://github.com/xanmod/linux.git` | Fallback XanMod source (GitHub) |
| `JOBS` | `nproc` | Parallel make jobs |
| `SKIP_FETCH` | `0` | Skip re-fetching if cache exists |
| `SKIP_OCI` | `0` | Skip OCI image build |
| `SKIP_RELEASE` | `1` | Skip GitHub Release publish |
| `GH_TOKEN` | — | GitHub token for base repo auth + release publish |
| `GITHUB_ORG` | `Interested-Deving-1896` | GitHub org for base repo resolution |

## Arch support

| Tier | Arches |
|---|---|
| Tier 1 | `amd64`, `arm64` |
| Tier 2 | `armhf`, `riscv64`, `s390x` |
| Tier 3 | `armel`, `ppc64el`, `mips64el`, `loong64`, `i686` |

KARCH mapping (Debian arch → Linux `ARCH=`): `amd64→x86_64`, `arm64→arm64`, `armhf→arm`, `armel→arm`, `i686→i386`, `ppc64el→powerpc`, `s390x→s390`, `riscv64→riscv`, `mips64el→mips`, `loong64→loongarch`.

## Source tree resolution

`fetch-base.sh` implements a two-path strategy:

1. **Base repo path** (preferred): checks for `{distro}-{arch}-kernel-base` repo in `Interested-Deving-1896` org. If the repo contains a `READY` sentinel file, clones it as the source tree. This path activates automatically once the arch kernel base repos are populated.

2. **Fallback path**: downloads a vanilla kernel tarball from `cdn.kernel.org` matching the XanMod target version. Used until base repos are ready.

No code changes are needed to switch between paths — the `READY` sentinel file is the only trigger.

## XanMod patch extraction

`fetch-patches.sh` clones the XanMod repo (GitLab primary, GitHub fallback), finds the merge-base between the XanMod branch tip and the corresponding vanilla kernel tag, then generates a numbered patch series via `git format-patch`. The `patches/VERSION` file records kernel version, XanMod version, base tag, and patch count.

## Config layering

Configs are applied in order during `build.sh` step 4:
1. `configs/{distro}/config.base` — distro-specific defaults
2. `configs/{distro}/config.{arch}` — arch-specific settings
3. `configs/xanmod-fragments/config.xanmod` — XanMod features

`make olddefconfig` resolves any conflicts non-interactively.

## Adding a new distro

1. Create `configs/{newdistro}/config.base` and `configs/{newdistro}/config.{arch}` files.
2. Add `{newdistro}` to `DISTROS` in `Makefile`.
3. Add `{newdistro}` to the `BASE_IMAGE` case in `scripts/build-oci.sh`.
4. Add matrix entries in `.github/workflows/build.yml` and `release.yml`.

## Adding a new arch

1. Add KARCH mapping in `scripts/lib/detect.sh` (`karch_for`, `cross_compile_for`, `cross_compiler_pkg`).
2. Add to the appropriate tier in `Makefile` (`TIER1_ARCHES`, `TIER2_ARCHES`, or `TIER3_ARCHES`).
3. Add Docker platform mapping in `scripts/build-oci.sh`.
4. Add cross-compiler package to `scripts/bootstrap.sh`.
5. Add config fragment `configs/{distro}/config.{arch}` for each distro.

## Base integration layer

The shared base integration layer (`scripts/fetch-base.sh`, `scripts/build-with-base.sh`, `config/base-repos.yml`) is shared across `xanmod-unified-kernel`, `liquorix-unified-kernel`, and `liqxanmod`. See `config/base-repos.yml` for the distro+arch → base repo mapping.

## Common tasks

```bash
# Build debian/amd64
make build

# Build ubuntu/arm64
make build DISTRO=ubuntu ARCH=arm64

# Build all Tier 1 combos
make all-tier1

# Install build deps
make bootstrap

# Clean build artifacts (keep patch cache)
make clean

# Full clean including patch cache
make distclean
```
