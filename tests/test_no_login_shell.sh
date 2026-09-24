#!/usr/bin/env bash
# Tests must not start login shells: /etc/profile on Debian resets PATH and
# drops tests/mock-bin, so the real curl would run (issue #5).
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

hits="$(grep -nE '\b(bash|sh|zsh) +-[a-zA-Z]*l' tests/*.sh | grep -v '^tests/test_no_login_shell.sh:' || true)"
assert_eq "" "$hits" "login shells in tests"

# A child shell started the way test_search.sh does still sees the mock.
ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
seen="$(bash -c 'command -v curl')"
assert_eq "$ROOT/tests/mock-bin/curl" "$seen" "curl seen by a child shell"

echo "OK no login shell"
