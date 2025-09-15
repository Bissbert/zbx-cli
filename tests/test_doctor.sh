#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"

out="" err="" code=0
run_cmd out err code "$ROOT/bin/zbx" doctor
assert_eq 0 "$code" "doctor exit"
assert_contains "$out" "apiinfo.version" "doctor includes apiinfo.version"
assert_contains "$out" "7.0.0" "doctor shows api version"
assert_contains "$out" "ping" "doctor includes ping"
assert_contains "$out" "pong" "doctor ping pong"
assert_contains "$out" "version" "doctor includes version"
assert_contains "$out" "api.version:" "doctor version shows api.version"

echo "OK doctor"

