# xanmod-unified-kernel

[![Built with Ona](https://ona.com/build-with-ona.svg)](https://app.ona.com/#https://github.com/Interested-Deving-1896/xanmod-unified-kernel)

<!-- AI:start:what-it-does -->
This project provides a build system for creating XanMod Linux kernel packages in a distribution-agnostic and architecture-agnostic manner. It allows users to compile `.deb` packages for various Linux distributions (e.g., Debian, Ubuntu) and architectures (e.g., amd64, arm64). It is intended for developers, maintainers, and advanced users who need a streamlined way to build and distribute custom XanMod kernels.
<!-- AI:end:what-it-does -->

## Architecture

<!-- AI:start:architecture -->
The project consists of a build system for creating XanMod Linux kernel `.deb` packages across multiple distributions and architectures. It uses a `Makefile` to define build targets, default configurations, and tiered architecture support. The build process fetches the XanMod kernel source from a Git repository, applies patches, and produces distribution-specific packages. The directory structure organizes build artifacts, patches, and configuration files.

Key components:
- `Makefile`: Central build logic, including targets for building, releasing, and dependency management.
- `build.sh`: Helper script for build automation.
- `patches/`: Contains kernel patches applied during the build process.
- `configs/`: Stores kernel configuration files for different architectures and distributions.
- `output/`: Directory where built `.deb` packages are stored.
- `.github/workflows/`: Contains CI/CD workflows for automated builds and repository maintenance.

Directory structure:
```plaintext
.
├── Makefile
├── build.sh
├── patches/
├── configs/
├── output/
├── .github/
│   └── workflows/
├── docs/
└── LICENSE
```
<!-- AI:end:architecture -->

## Install

<!-- Add installation instructions here. This section is yours — the AI will not modify it. -->

```bash
git clone https://github.com/Interested-Deving-1896/xanmod-unified-kernel.git
cd xanmod-unified-kernel
```

## Usage

<!-- Add usage examples here. This section is yours — the AI will not modify it. -->

## Configuration


Config fragments are layered in order:
1. `configs/{distro}/config.base`
2. `configs/{distro}/config.{arch}`
3. `configs/xanmod-fragments/config.xanmod`

See [AGENTS.md](AGENTS.md) for full build system documentation.

## CI

<!-- AI:start:ci -->
The repository uses GitHub Actions for continuous integration and automation. Below are the relevant workflows:

- **build.yml**: Builds the XanMod kernel for specified distributions and architectures. No secrets required.
- **release.yml**: Publishes built kernel packages as a GitHub Release. Requires `GITHUB_TOKEN`.
- **lint.yml**: Runs shellcheck and other linters on scripts and configurations. No secrets required.
- **cleanup-pollution.yml**: Cleans up temporary files and artifacts from previous runs. No secrets required.
- **mirror-artifacts.yml**: Mirrors build artifacts to external storage. Requires `STORAGE_ACCESS_KEY` and `STORAGE_SECRET_KEY`.
- **sync-to-gitlab.yml**: Syncs the repository to a GitLab mirror. Requires `GITLAB_TOKEN`.
- **token-health.yml**: Monitors the health and expiration of API tokens. Requires `GITHUB_TOKEN` and `GITLAB_TOKEN`.

Refer to `.github/workflows/` for additional workflows and their configurations.
<!-- AI:end:ci -->

## Mirror chain

<!-- AI:start:mirror-chain -->
This repo is maintained in [`Interested-Deving-1896/xanmod-unified-kernel`](https://github.com/Interested-Deving-1896/xanmod-unified-kernel) and mirrored through:

```
Interested-Deving-1896/xanmod-unified-kernel  ──►  OpenOS-Project-OSP/xanmod-unified-kernel  ──►  OpenOS-Project-Ecosystem-OOC/xanmod-unified-kernel
```

Changes flow downstream automatically via the hourly mirror chain in
[`fork-sync-all`](https://github.com/Interested-Deving-1896/fork-sync-all).
Direct commits to OSP or OOC are detected and opened as PRs back to `Interested-Deving-1896`.
<!-- AI:end:mirror-chain -->

## Contributors

<!-- AI:start:contributors -->
_Contributors pending._
<!-- AI:end:contributors -->

## Origins

<!-- AI:start:origins -->
_Original project — no upstream fork._
<!-- AI:end:origins -->

## Resources

<!-- AI:start:resources -->
_No additional resource files found._
<!-- AI:end:resources -->

## License

<!-- AI:start:license -->
[MIT](https://github.com/Interested-Deving-1896/xanmod-unified-kernel/blob/main/LICENSE) © 2026 [Interested-Deving-1896](https://github.com/Interested-Deving-1896)
<!-- AI:end:license -->
