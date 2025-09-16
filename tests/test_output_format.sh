#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
export ZABBIX_API_TOKEN="dummy"

out="" err="" code=0

# search hosts with CSV and headers
run_cmd out err code "$ROOT/bin/zbx" search hosts web --format csv --headers
assert_eq 0 "$code" "search csv exit"
hdr=$(printf '%s\n' "$out" | sed -n '1p')
first=$(printf '%s\n' "$out" | sed -n '2p')
assert_contains "$hdr" '"hostid","host","name"' "csv header"
assert_contains "$first" 'web01' "csv row"

# template-list json
run_cmd out err code "$ROOT/bin/zbx" template-list --format json
assert_eq 0 "$code" "template-list json exit"
assert_contains "$out" 'Template OS Linux' "template name"

# problems tsv with headers
run_cmd out err code "$ROOT/bin/zbx" problems --format tsv --headers
assert_eq 0 "$code" "problems tsv exit"
hdr=$(printf '%s\n' "$out" | sed -n '1p')
first=$(printf '%s\n' "$out" | sed -n '2p')
assert_contains "$hdr" $'eventid	name	severity	acknowledged	clock' "tsv header"
assert_contains "$first" 'CPU high' "tsv row"

echo "OK output format"
