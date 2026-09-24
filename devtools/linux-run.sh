#!/bin/sh
# Run every check in docs/measurement.md inside a Linux container.
#
#   sh devtools/linux-run.sh > docs/captures/linux-run.txt
#
# The repository is mounted read-only and copied inside the container with the
# file modes git records. No Zabbix endpoint is contacted: the mock tests use
# tests/mock-bin/curl, the token-error check replaces curl with a shell
# function, and the doctor probe points at a closed local port.
set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
IMAGE=python:3.12-slim-bookworm

docker pull -q "$IMAGE" >/dev/null
docker run --rm -v "$REPO":/repo:ro "$IMAGE" bash -c '
set -u
section() { printf "\n=== %s\n" "$*"; }

apt-get -qq update >/dev/null 2>&1
apt-get -qq install -y --no-install-recommends curl jq make git >/dev/null 2>&1
git config --global --add safe.directory "*"
git clone -q /repo /tmp/zbx && cd /tmp/zbx
# The clone has the committed files and modes; overlay the working tree so
# uncommitted docs and devtools changes are measured too, keeping git modes.
(cd /repo && git ls-files -m -o --exclude-standard) | while read -r f; do
  [ -f "/repo/$f" ] && mkdir -p "$(dirname "$f")" && cat "/repo/$f" > "$f"
done

section "environment"
uname -srm
bash --version | head -1
curl --version | head -1
jq --version

section "devtools/measure.sh"
bash devtools/measure.sh

section "command table matches docs/commands.md"
bash devtools/generate-command-table.sh > /tmp/table.md
grep "^|" /tmp/table.md > /tmp/rows.md
missing=$(grep -vxF -f docs/commands.md /tmp/rows.md | wc -l)
echo "generated table rows: $(wc -l < /tmp/rows.md), missing from docs/commands.md: $missing"

section "file modes as committed"
git ls-files -s bin tests/mock-bin | awk "{print \$1, \$4}" | sort | uniq -c -w6 | awk "{print \$2, \$1 \" files, e.g.\", \$3}"

section "bug 6: bash bin/zbx from the clone (committed modes)"
echo "--list lines: $(bash bin/zbx --list | wc -l)"
bash bin/zbx config --help >/dev/null 2>/tmp/e.txt; echo "bash bin/zbx config --help exit=$?"
cat /tmp/e.txt

section "make test"
make test > /tmp/test.log 2>&1; rc=$?
grep -E "^(PASS|FAIL|SKIP|Summary)" /tmp/test.log
echo "exit=$rc"

section "bug 7: tests start no login shells"
echo "login-shell invocations in tests/: $(grep -cE "\b(bash|sh|zsh) +-[a-zA-Z]*l" tests/test_search.sh tests/run.sh tests/helpers.sh | awk -F: "{s+=\$2} END {print s}")"

section "bug 8: zbx login in session mode"
export HOME=/tmp/h8 XDG_STATE_HOME=/tmp/h8/state ZABBIX_USER=alice ZABBIX_PASS=secret
PATH=$PWD/tests/mock-bin:$PATH bash bin/zbx login > /tmp/l.txt 2>/dev/null; echo "exit=$? stdout=[$(cat /tmp/l.txt)]"
echo "cached token: $(jq -r .token /tmp/h8/state/zbx/session.token)"
unset HOME XDG_STATE_HOME ZABBIX_USER ZABBIX_PASS
export HOME=/root

section "bug 1: installed zbx --list"
make install PREFIX=/tmp/prefix SYSCONFDIR=/tmp/prefix/etc >/dev/null 2>&1; echo "install exit=$?"
PATH=/tmp/prefix/bin:$PATH zbx --list > /tmp/list.txt; echo "list exit=$?"
echo "commands listed: $(wc -l < /tmp/list.txt), lib listed: $(grep -cx lib /tmp/list.txt)"

section "bug 3: mock curl resolves first"
stat -c "%A %n" tests/mock-bin/curl
PATH=$PWD/tests/mock-bin:$PATH command -v curl

section "bug 4: JSON-RPC error in API-token mode"
curl() { jq -n "{jsonrpc:\"2.0\",error:{code:-32600,message:\"unsupported API version\"},id:1}"; }
export -f curl
for c in ping version; do
  ZABBIX_URL=http://mock.invalid/api_jsonrpc.php ZABBIX_API_TOKEN=dummy \
    bash bin/zbx-$c > /tmp/out.txt 2> /tmp/err.txt; rc=$?
  echo "zbx-$c exit=$rc stdout=[$(tr "\n" " " < /tmp/out.txt)]"
  grep -o "API error: .*" /tmp/err.txt | head -1
done
unset -f curl

section "bug 5: doctor against a closed port"
ZABBIX_URL=http://127.0.0.1:9/api_jsonrpc.php ZABBIX_API_TOKEN=dummy ZABBIX_CURL_TIMEOUT=1 \
  bash bin/zbx-doctor > /tmp/doc.txt 2>&1; echo "exit=$?"
grep -E "apiinfo|endpoint" /tmp/doc.txt
echo "lines containing 000000: $(grep -c 000000 /tmp/doc.txt)"
'
