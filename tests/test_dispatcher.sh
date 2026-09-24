#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/bin:$PATH"

out=""; err=""; code=0
run_cmd out err code "$ROOT/bin/zbx" --where hosts-list
assert_eq 0 "$code" "zbx --where"
assert_contains "$out" "bin/zbx-hosts-list" "where path"

run_cmd out err code "$ROOT/bin/zbx" help hosts-list
assert_eq 0 "$code" "zbx help sub"
assert_contains "$out" "Usage:" "help shows usage"

echo "OK dispatcher"
