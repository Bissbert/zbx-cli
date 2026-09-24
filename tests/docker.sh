#!/bin/sh
# Run `make test` in a clean Debian container from a clone of this checkout.
# Uncommitted changes, including file-mode changes, are applied on top.
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
docker run --rm -v "$repo:/repo:ro" python:3.12-slim-bookworm bash -c '
set -e
apt-get update -qq >/dev/null && apt-get install -y -qq curl jq make git >/dev/null
git config --global --add safe.directory "*"
git clone -q /repo /work
git -C /repo diff --binary HEAD | git -C /work apply --index --allow-empty
cd /repo && git ls-files -o --exclude-standard -z | xargs -0 -r cp --parents -t /work
cd /work && make test
'
