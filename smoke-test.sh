#!/usr/bin/env bash
set -euo pipefail
image=${1:?Usage: bash smoke-test.sh IMAGE}
trap 'docker logs 9router-smoke 2>&1 || true; docker rm -f -v 9router-smoke >/dev/null 2>&1 || true' EXIT
docker run -d --name 9router-smoke --init --cap-drop ALL \
  --security-opt no-new-privileges:true -p 127.0.0.1::20128 "$image"
port=$(docker port 9router-smoke 20128/tcp)
ready=false
for attempt in {1..60}; do
  if curl -fsS "http://$port/api/health"; then ready=true; break; fi
  sleep 2
done
"$ready"
curl -fsSL "http://$port/dashboard" >/dev/null
docker exec 9router-smoke node -e '
const assert = require("node:assert/strict");
assert.equal(process.getuid(), 65532);
const Database = require("better-sqlite3");
const db = new Database(":memory:");
assert.equal(db.prepare("select 1 as ok").get().ok, 1);
db.close();
for (const name of ["wreq-js", "playwright-core", "sharp"]) require(name);
const fs = require("node:fs");
for (const dir of ["/app/data", "/app/data-home"]) {
  fs.writeFileSync(dir + "/smoke-test", "persistent");
}
console.log("Native modules, non-root user and data permissions: OK");'
docker restart 9router-smoke
ready=false
for attempt in {1..60}; do
  if curl -fsS "http://$port/api/health"; then ready=true; break; fi
  sleep 2
done
"$ready"
docker exec 9router-smoke node -e '
const assert = require("node:assert/strict");
const fs = require("node:fs");
for (const dir of ["/app/data", "/app/data-home"]) {
  assert.equal(fs.readFileSync(dir + "/smoke-test", "utf8"), "persistent");
}
console.log("Restart persistence: OK");'
