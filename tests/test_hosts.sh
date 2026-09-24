#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"

out="" err="" code=0
run_cmd out err code "$ROOT/bin/zbx" hosts-list
assert_eq 0 "$code" "hosts-list exit"
assert_contains "$out" $'10101	web01' "hosts-list contains web01"

run_cmd out err code "$ROOT/bin/zbx" host-get web01
assert_eq 0 "$code" "host-get exit"
assert_contains "$out" '"hostid": "10101"' "host-get json"

echo "OK hosts"
