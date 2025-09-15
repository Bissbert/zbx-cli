#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

# Require a real endpoint to be configured
if [ -z "${ZABBIX_URL:-}" ]; then
  echo "ERROR: ZABBIX_URL must be set for integration connectivity tests" >&2
  exit 1
fi

ROOT="$PWD"
export PATH="$ROOT/bin:$PATH"

out="" err="" code=0
ZBX_ARGS=""
[ "${ZBX_TEST_INSECURE:-0}" = "1" ] && ZBX_ARGS="--insecure"

run_cmd out err code "$ROOT/bin/zbx" $ZBX_ARGS ping
assert_eq 0 "$code" "zbx ping exit"
assert_eq "pong" "${out//$'\n'/}" "zbx ping output"

run_cmd out err code "$ROOT/bin/zbx" $ZBX_ARGS version
assert_eq 0 "$code" "zbx version exit"
assert_contains "$out" "api.version:" "zbx version includes api version"

echo "OK integration connectivity"
