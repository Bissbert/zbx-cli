#!/usr/bin/env bash
# Usage errors, unknown hosts and API errors.
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"
export MOCK_CURL_LOG="$(mktemp)"
trap 'rm -f "$MOCK_CURL_LOG"' EXIT

out="" err="" code=0

# Missing arguments exit 2 with a usage line and send nothing.
for cmd in host-get host-del host-disable host-enable host-create macro-get \
    macro-set macro-del maint-create maint-del template-link template-unlink \
    trigger-enable trigger-disable triggers item-find discovery history trends \
    ack call; do
  reset_requests
  run_cmd out err code "$ROOT/bin/zbx" "$cmd"
  assert_eq 2 "$code" "$cmd without arguments exit"
  assert_contains "$out$err" "Usage" "$cmd usage"
  assert_eq "" "$(requests)" "$cmd sends no request"
done

# Commands that resolve a host stop when it does not exist.
for cmd in "host-del missing" "host-disable missing" "host-enable missing" \
    "macro-get missing" "macro-set missing {X} 1" "macro-del missing {X}" \
    "maint-create M missing 1 2" "template-link missing T" \
    "template-unlink missing T" "triggers missing" "item-find missing k" \
    "discovery missing"; do
  reset_requests
  # shellcheck disable=SC2086
  run_cmd out err code "$ROOT/bin/zbx" $cmd
  assert_eq 1 "$code" "$cmd exit"
  assert_contains "$err" "Host not found: missing" "$cmd message"
  assert_eq "host.get" "$(requests | jq -r .method | sort -u)" "$cmd only looks the host up"
done

run_cmd out err code "$ROOT/bin/zbx" host-get missing
assert_eq 0 "$code" "host-get missing exit"
assert_eq "" "$out" "host-get missing prints nothing"

# A JSON-RPC error is reported and fails the command.
MOCK_API_ERROR=host.get run_cmd out err code "$ROOT/bin/zbx" hosts-list
assert_eq 1 "$code" "hosts-list API error exit"
assert_contains "$err" 'API error: {"code":-32602,"message":"Invalid params.","data":"mock error"}' "API error message"

MOCK_API_ERROR=event.acknowledge run_cmd out err code "$ROOT/bin/zbx" ack 6001
assert_eq 1 "$code" "ack API error exit"

MOCK_API_ERROR=apiinfo.version run_cmd out err code "$ROOT/bin/zbx" ping
assert_eq 1 "$code" "ping API error exit"
assert_not_contains "$out" "pong" "no pong on error"

run_cmd out err code "$ROOT/bin/zbx" no-such-command
assert_eq 2 "$code" "unknown subcommand exit"
assert_contains "$err" "Unknown command: no-such-command" "unknown subcommand message"

echo "OK errors"
