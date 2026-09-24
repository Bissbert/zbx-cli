#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

# Require a real endpoint to be configured
if [ -z "${ZABBIX_URL:-}" ]; then
  echo "ERROR: ZABBIX_URL must be set for integration read-only tests" >&2
  exit 1
fi

ROOT="$PWD"
export PATH="$ROOT/bin:$PATH"

# Use API token if provided via env/config; otherwise user+pass is fine.
ZBX_ARGS=""
[ "${ZBX_TEST_INSECURE:-0}" = "1" ] && ZBX_ARGS="--insecure"

# 1) apiinfo.version via low-level call (read-only)
out="" err="" code=0
run_cmd out err code sh -c "printf '{}' | '$ROOT/bin/zbx' $ZBX_ARGS call apiinfo.version"
assert_eq 0 "$code" "apiinfo.version call exit"
# Expect a non-null, non-empty result (string like 7.0.0)
val="${out//$'\n'/}"
if [ -z "$val" ] || [ "$val" = "null" ]; then
  printf 'ASSERT_NON_NULL failed: apiinfo.version returned: %s\n' "$out" >&2
  exit 1
fi

# 2) host.get with limit=1 (read-only)
run_cmd out err code sh -c "printf '{\"limit\":1,\"output\":[\"hostid\",\"host\"]}' | '$ROOT/bin/zbx' $ZBX_ARGS call host.get '. | length'"
assert_eq 0 "$code" "host.get exit"

# 3) template.get with limit=1 (read-only)
run_cmd out err code sh -c "printf '{\"limit\":1,\"output\":[\"templateid\",\"name\"]}' | '$ROOT/bin/zbx' $ZBX_ARGS call template.get '. | length'"
assert_eq 0 "$code" "template.get exit"

# 4) problem.get with recent and limit=1 (read-only)
run_cmd out err code sh -c "printf '{\"recent\":true,\"limit\":1}' | '$ROOT/bin/zbx' $ZBX_ARGS call problem.get '. | type'"
assert_eq 0 "$code" "problem.get exit"

echo "OK integration readonly"
