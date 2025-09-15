#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/bin:$PATH"

tmpdir=$(mktemp -d)
pushd "$tmpdir" >/dev/null

out="" err="" code=0
run_cmd out err code "$ROOT/bin/zbx" config init --scope project
cfg="$out"
if [ ! -f "$tmpdir/config.sh" ]; then
  printf 'ASSERT_FILE failed: %s\n' "$tmpdir/config.sh" >&2
  exit 1
fi

run_cmd out err code "$ROOT/bin/zbx" config set FOO bar --scope project
assert_eq 0 "$code" "config set"

run_cmd out err code "$ROOT/bin/zbx" config get FOO --raw
assert_eq 0 "$code" "config get"
assert_eq "bar" "${out//$'\n'/}" "config value"

popd >/dev/null
rm -rf "$tmpdir"
echo "OK config"
