# 9router-wolfi

Build 9Router with Wolfi (glibc), Node.js 22 and a non-root runtime.

Upstream: https://github.com/decolua/9router

Pinned source: `cebc72e3438dca5aad69b2828cb0d0f2e54b168d` (9Router 0.4.41).
This repository contains packaging only, not a copy of the application.
Upstream application licensing remains applicable.

## Run

Choose your own initial password (do not commit it):

```sh
read -rsp 'Initial password: ' INITIAL_PASSWORD; echo
export INITIAL_PASSWORD
docker compose pull
docker compose up -d --wait
```

Open http://localhost:20128. Data is stored in the `data` and `home` Docker
volumes. The listener is localhost-only; do not expose it publicly without
reviewing authentication and TLS. Change the initial password in the dashboard.

```sh
docker compose logs -f
docker compose down # preserves data; do not add -v unless deleting data
```

## Build locally

```sh
git clone https://github.com/decolua/9router.git upstream
git -C upstream checkout cebc72e3438dca5aad69b2828cb0d0f2e54b168d
docker build -f Dockerfile -t 9router-wolfi:local upstream
bash smoke-test.sh 9router-wolfi:local
```

## GitHub Actions

- Push to `0.4.41` or manual dispatch builds and smoke-tests
  linux/amd64, then publish the exact tested image to GHCR.
- Pull requests build and test without registry login or publishing.
- Tags: `0.4.41`, `sha-<packaging commit>` and `run-<run id>-<attempt>`.
  Rebuilds can change a SHA tag because package repositories change;
  use the run tag or registry digest for a specific build.
- Smoke checks cover HTTP health, dashboard response, native module loading,
  non-root permissions and restart persistence, not live provider calls or
  browser automation.
- Grype scans the exact image before publication and saves a JSON report as a
  workflow artifact. Vulnerability findings do not block publication; scanner
  errors do. The report includes fixed and unfixed findings.
- Docker build summaries show duration and cache utilization for both the Wolfi
  build and the pinned upstream Dockerfile, rebuilt for linux/amd64 on the same
  runner with separate caches. The job summary compares unpacked local image
  sizes. These are not historical upstream build times or compressed registry
  sizes; cache state and build order can affect timings. The upstream release
  run is https://github.com/decolua/9router/actions/runs/25841384476 (the
  original release built both amd64 and arm64; its logs have expired).
- Rebuilds refresh OS/npm dependency resolution, not upstream source or
  the pinned Wolfi base digest. Update the upstream ref, Dockerfile labels and
  README together to change the application version.
- GHCR package visibility is separate from repository visibility. If anonymous
  pulls fail, set the package to Public in GitHub package settings.
