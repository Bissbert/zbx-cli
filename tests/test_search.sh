#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"

out="" err="" code=0
run_cmd out err code "$ROOT/bin/zbx" search hosts web
assert_eq 0 "$code" "search hosts exit"
assert_contains "$out" $'10101	web01' "search hosts match"

run_cmd out err code bash -lc "printf '{}' | '$ROOT/bin/zbx' call apiinfo.version"
assert_eq 0 "$code" "zbx call exit"
assert_contains "$out" '7.0.0' "api version"

echo "OK search"
