#!/usr/bin/env bash
# Commands that change Zabbix: the exact API method and parameters they send.
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"
export MOCK_CURL_LOG="$(mktemp)"
trap 'rm -f "$MOCK_CURL_LOG"' EXIT

out="" err="" code=0

run_cmd out err code "$ROOT/bin/zbx" host-create web03 192.0.2.10
assert_eq 0 "$code" "host-create exit"
assert_eq '{"host":"web03","interfaces":[{"type":1,"main":1,"useip":1,"ip":"192.0.2.10","dns":"","port":"10050"}],"groups":[{"groupid":"2001"}]}' \
  "$(last_request host.create)" "host-create params"

reset_requests
run_cmd out err code "$ROOT/bin/zbx" host-create web04 192.0.2.11 "New group"
assert_eq 0 "$code" "host-create new group exit"
assert_eq '{"name":"New group"}' "$(last_request hostgroup.create)" "group created"
assert_eq '[{"groupid":"2002"}]' "$(last_request host.create .params.groups)" "host uses new group"

run_cmd out err code "$ROOT/bin/zbx" host-disable web01
assert_eq 0 "$code" "host-disable exit"
assert_eq "ok hostid=10101" "$out" "host-disable output"
assert_eq '{"hostid":"10101","status":1}' "$(last_request host.update)" "host-disable params"

run_cmd out err code "$ROOT/bin/zbx" host-enable web01
assert_eq 0 "$code" "host-enable exit"
assert_eq '{"hostid":"10101","status":0}' "$(last_request host.update)" "host-enable params"

run_cmd out err code "$ROOT/bin/zbx" host-del web01
assert_eq 0 "$code" "host-del exit"
assert_eq "deleted hostid=10101" "$out" "host-del output"
assert_eq '{"hostids":["10101"]}' "$(last_request host.delete)" "host-del params"

run_cmd out err code "$ROOT/bin/zbx" macro-set web01 '{ENV}' staging
assert_eq 0 "$code" "macro-set exit"
assert_eq '{"hostid":"10101","macros":[{"macro":"{ENV}","value":"staging"}]}' "$(last_request host.update)" "macro-set params"

run_cmd out err code "$ROOT/bin/zbx" macro-del web01 '{ENV}'
assert_eq 0 "$code" "macro-del exit"
assert_eq '{"hostmacroids":["8001"]}' "$(last_request usermacro.delete)" "macro-del params"

run_cmd out err code "$ROOT/bin/zbx" macro-del web01 '{NOPE}'
assert_eq 1 "$code" "macro-del unknown macro exit"
assert_contains "$err" "Macro not found on host: {NOPE}" "macro-del unknown macro message"

reset_requests
run_cmd out err code bash -c "printf 'web01\t{A}\t1\nmissing\t{B}\t2\n\ndb01\t{C}\t3\n' | '$ROOT/bin/zbx' macro-bulk-set"
assert_eq 0 "$code" "macro-bulk-set exit"
assert_eq $'ok web01 {A}\nok db01 {C}' "$out" "macro-bulk-set output"
assert_contains "$err" "skip: host not found: missing" "macro-bulk-set skip warning"
assert_eq 2 "$(requests | jq -r 'select(.method == "host.update") | .method' | wc -l | tr -d ' ')" "macro-bulk-set updates"

run_cmd out err code "$ROOT/bin/zbx" template-link web01 "Template OS Linux"
assert_eq 0 "$code" "template-link exit"
assert_eq '{"hostid":"10101","templates":[{"templateid":"3001"}]}' "$(last_request host.update)" "template-link params"

run_cmd out err code "$ROOT/bin/zbx" template-unlink web01 "Template OS Linux"
assert_eq 0 "$code" "template-unlink exit"
assert_eq '{"hostid":"10101","templates_clear":[{"templateid":"3001"}]}' "$(last_request host.update)" "template-unlink params"

run_cmd out err code "$ROOT/bin/zbx" trigger-disable 5001
assert_eq 0 "$code" "trigger-disable exit"
assert_eq "ok triggerid=5001" "$out" "trigger-disable output"
assert_eq '{"triggerid":5001,"status":1}' "$(last_request trigger.update)" "trigger-disable params"

run_cmd out err code "$ROOT/bin/zbx" trigger-enable 5001
assert_eq 0 "$code" "trigger-enable exit"
assert_eq '{"triggerid":5001,"status":0}' "$(last_request trigger.update)" "trigger-enable params"

run_cmd out err code "$ROOT/bin/zbx" maint-create Patch web01 1700000000 1700003600
assert_eq 0 "$code" "maint-create exit"
assert_eq '{"name":"Patch","active_since":1700000000,"active_till":1700003600,"hostids":["10101"]}' \
  "$(last_request maintenance.create)" "maint-create params"

run_cmd out err code "$ROOT/bin/zbx" maint-del 7001
assert_eq 0 "$code" "maint-del exit"
assert_eq '{"maintenanceids":[7001]}' "$(last_request maintenance.delete)" "maint-del params"

run_cmd out err code "$ROOT/bin/zbx" ack 6001
assert_eq 0 "$code" "ack without message exit"
assert_eq '{"eventids":[6001],"action":2}' "$(last_request event.acknowledge)" "ack action 2"

run_cmd out err code "$ROOT/bin/zbx" ack 6001 "On it"
assert_eq '{"eventids":[6001],"action":6,"message":"On it"}' "$(last_request event.acknowledge)" "ack with message adds action 4"

echo "OK write commands"
