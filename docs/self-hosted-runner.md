# Runner Strategy for Kernel Build Repos

Kernel builds (`xan-mod-linux-kernel`, `xanmod-unified-kernel`) cannot run on
standard shared runners — a full kernel compile takes 20–40 minutes on 8 cores
and produces ~15 GB of artifacts.

## Runner options

### Option A — GitLab SaaS large runners (requires Premium/Ultimate)

The current `.gitlab-ci.yml` files use:

```yaml
tags: [saas-linux-xlarge-amd64]
```

`saas-linux-xlarge-amd64` provides 8 vCPUs / 32 GB RAM and is available on
GitLab Premium and Ultimate plans. On the free plan these jobs will be stuck
in "pending" indefinitely.

**To use:** Upgrade the `openos-project` group to Premium, or use a GitLab
trial. No runner registration needed.

### Option B — Self-hosted runner (free plan compatible)

Register a GitLab Runner on a machine with sufficient resources.

**Minimum requirements:**

| Resource | Minimum | Recommended |
|---|---|---|
| CPU cores | 4 | 8–16 |
| RAM | 8 GB | 16–32 GB |
| Disk (free) | 30 GB | 60 GB |
| OS | Any Linux | Debian/Ubuntu |

**Registration steps:**

1. Install GitLab Runner:
   ```bash
   curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
   sudo apt-get install gitlab-runner
   ```

2. Get a runner token from the project:
   **Settings → CI/CD → Runners → New project runner**

3. Register:
   ```bash
   sudo gitlab-runner register \
     --url https://gitlab.com \
     --token <runner-token> \
     --executor docker \
     --docker-image debian:trixie \
     --description "kernel-builder" \
     --tag-list kernel-builder
   ```

4. Update `.gitlab-ci.yml` to use your tag instead of `saas-linux-xlarge-amd64`:
   ```yaml
   tags: [kernel-builder]
   ```

### Option C — Disable build CI, use upstream artifacts (current fallback)

If neither Premium nor a self-hosted runner is available, the CI jobs will
remain but simply won't run (they stay pending). Kernel packages can be
obtained directly from upstream:

- XanMod: https://xanmod.org
- Liquorix: https://liquorix.net

The tracking-fork CI (lint, upstream-check, security scan) runs on standard
shared runners and is unaffected.

## Current state

| Repo | CI jobs on shared runners | CI jobs needing large runner |
|---|---|---|
| `xan-mod-linux-kernel` | — | `7.0 x64v2`, `7.0 x64v3` |
| `xanmod-unified-kernel` | `lint`, `upstream-check` | `build:*` |

The `lint` and `upstream-check` jobs in `xanmod-unified-kernel` run on
`alpine:3.19` and work on the free plan today.

## Switching runner tags

To switch from SaaS large runners to a self-hosted runner, replace the `tags`
field in each build job:

```yaml
# Before (Premium required)
tags: [saas-linux-xlarge-amd64]

# After (self-hosted)
tags: [kernel-builder]
```
