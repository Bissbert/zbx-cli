#!/usr/bin/env bash
# Read-only subcommands: request parameters and table output.
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"
export MOCK_CURL_LOG="$(mktemp)"
trap 'rm -f "$MOCK_CURL_LOG"' EXIT

out="" err="" code=0

reset_requests
run_cmd out err code "$ROOT/bin/zbx" ping
assert_eq 0 "$code" "ping exit"
assert_eq "pong" "$out" "ping output"
assert_eq '""' "$(last_request apiinfo.version ._authorization)" "apiinfo.version has no Authorization header"

run_cmd out err code "$ROOT/bin/zbx" version
assert_eq 0 "$code" "version exit"
assert_eq $'api.version: 7.0.0\nuser: tester (Test User)' "$out" "version output"
assert_eq '"Bearer dummy"' "$(last_request user.get ._authorization)" "API token sent as Bearer header"

run_cmd out err code "$ROOT/bin/zbx" host-groups --headers
assert_eq 0 "$code" "host-groups exit"
assert_eq $'groupid\tname\n2001\tLinux servers' "$out" "host-groups table"

run_cmd out err code "$ROOT/bin/zbx" maint-list --format csv
assert_eq 0 "$code" "maint-list exit"
assert_eq '"7001","Window",1700000000,1700003600' "$out" "maint-list csv"

run_cmd out err code "$ROOT/bin/zbx" inventory
assert_eq 0 "$code" "inventory exit"
assert_contains "$out" '"10101","web01","Web 01"' "inventory csv row (csv with headers is the default)"
assert_eq '"extend"' "$(last_request host.get .params.selectInventory)" "inventory selects inventory"

reset_requests
run_cmd out err code "$ROOT/bin/zbx" triggers web01
assert_eq 0 "$code" "triggers exit"
assert_contains "$out" $'5001\t0\t4\tCPU load high' "triggers row"
assert_eq '["10101"]' "$(last_request trigger.get .params.hostids)" "triggers hostids"

run_cmd out err code "$ROOT/bin/zbx" item-find web01 'proc.num[nginx]'
assert_eq 0 "$code" "item-find exit"
assert_contains "$out" $'4001\t3\tproc.num[nginx]\tNginx processes' "item-find row"
assert_eq '{"key_":"proc.num[nginx]"}' "$(last_request item.get .params.search)" "item-find search"

run_cmd out err code "$ROOT/bin/zbx" discovery --format json web01
assert_eq 0 "$code" "discovery exit"
assert_eq '2' "$(jq length <<<"$out")" "discovery json items"

run_cmd out err code "$ROOT/bin/zbx" macro-get web01
assert_eq 0 "$code" "macro-get exit"
assert_eq $'{ENV}\tprod' "$out" "macro-get row"

run_cmd out err code "$ROOT/bin/zbx" history 4001 1700000000 1700003600
assert_eq 0 "$code" "history exit"
assert_eq $'1700000000\t3\n1700000060\t4' "$out" "history rows"
assert_eq '{"itemids":[4001],"time_from":1700000000,"time_till":1700003600}' \
  "$(last_request history.get '.params | {itemids,time_from,time_till}')" "history params are numbers"

run_cmd out err code "$ROOT/bin/zbx" trends --format json 4001 1699999200 1700003600
assert_eq 0 "$code" "trends exit"
assert_eq '"3.5"' "$(jq -c '.[0].avg' <<<"$out")" "trends avg"

run_cmd out err code bash -c "printf '{\"output\":[\"host\"]}' | '$ROOT/bin/zbx' call host.get '.[].host'"
assert_eq 0 "$code" "call with filter exit"
assert_eq $'web01\ndb01' "$out" "call with filter output"
assert_eq '{"output":["host"]}' "$(last_request host.get)" "call passes stdin as params"

echo "OK read commands"
