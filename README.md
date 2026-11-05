# 9router-wolfi

Build 9Router with Wolfi (glibc), Node.js 22 and a non-root runtime.

Upstream: https://github.com/decolua/9router

Pinned source: `1fe586bb1cf35e1ed0cb2150a8ef7d1db040b21d` (9Router 0.5.112).
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
git -C upstream checkout 1fe586bb1cf35e1ed0cb2150a8ef7d1db040b21d
docker build -f Dockerfile -t 9router-wolfi:local upstream
bash smoke-test.sh 9router-wolfi:local
```

## GitHub Actions

- Push to `main`, manual dispatch and a weekly schedule build and smoke-test
  linux/amd64, then publish the exact tested image to GHCR.
- Pull requests build and test without registry login or publishing.
- Tags: `latest`, `sha-<packaging commit>` and `run-<run id>-<attempt>`.
  Scheduled rebuilds can change a SHA tag because package repositories change;
  use the run tag or registry digest for a specific build.
- Smoke checks cover HTTP health, dashboard response, native module loading,
  non-root permissions and restart persistence, not live provider calls or
  browser automation. No vulnerability scan is currently configured.
- Weekly builds refresh OS/npm dependency resolution, not upstream source or
  the pinned Wolfi base digest. Update the upstream ref, Dockerfile labels and
  README together to change the application version.
- GHCR package visibility is separate from repository visibility. If anonymous
  pulls fail, set the package to Public in GitHub package settings.
