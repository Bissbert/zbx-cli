#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"
export ZABBIX_URL="https://example.local/api_jsonrpc.php"

out="" err="" code=0
run_cmd out err code "$ROOT/bin/zbx" doctor --json
assert_eq 0 "$code" "doctor --json exit"

# Basic JSON structure
if ! jq -e '.checks | type == "array"' >/dev/null 2>&1 <<<"$out"; then
  echo "Invalid JSON structure from doctor" >&2
  exit 1
fi

# apiinfo.version should be present and ok
status=$(jq -r '.checks[] | select(.name == "apiinfo.version") | .status' <<<"$out" || true)
assert_eq "ok" "$status" "apiinfo.version status"

echo "OK doctor json"

