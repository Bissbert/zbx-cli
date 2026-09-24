#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"

out="" err="" code=0
run_cmd out err code "$ROOT/bin/zbx" problems
assert_eq 0 "$code" "problems exit"
assert_contains "$out" "CPU high" "problem contains"

run_cmd out err code "$ROOT/bin/zbx" ack 6001 "Investigating"
assert_eq 0 "$code" "ack exit"
assert_contains "$out" '"eventids"' "ack result"

echo "OK problems"
