#!/usr/bin/env bash
# Every file in bin/ is committed executable, so a fresh clone can run the
# dispatcher and its subcommands without `make install` (issue #4).
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

if git rev-parse --git-dir >/dev/null 2>&1; then
  bad="$(git ls-files -s bin tests/mock-bin | awk '$1 != "100755" {print $1, $4}')"
  assert_eq "" "$bad" "git modes of bin/ and tests/mock-bin/ (want 100755)"
fi

for f in bin/* tests/mock-bin/*; do
  [ -x "$f" ] || { printf 'not executable: %s\n' "$f" >&2; exit 1; }
done

# The dispatcher runs each subcommand as its own executable.
out="" err="" code=0
run_cmd out err code bash bin/zbx config --help
assert_eq 0 "$code" "bash bin/zbx config --help exit"
assert_contains "$out" "Usage: zbx config" "config help"

echo "OK file modes"
