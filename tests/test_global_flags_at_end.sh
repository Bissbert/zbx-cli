#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"

out="" err="" code=0
run_cmd out err code "$ROOT/bin/zbx" search hosts web --insecure
assert_eq 0 "$code" "search accepts --insecure at end"
assert_contains "$out" $'10101	web01' "search output ok"

echo "OK global flags at end"

