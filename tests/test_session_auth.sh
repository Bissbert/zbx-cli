#!/usr/bin/env bash
# Session (user/password) mode: login, token cache, reuse and expiry.
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/tests/mock-bin:$ROOT/bin:$PATH"
unset ZABBIX_API_TOKEN
sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
export HOME="$sandbox" XDG_STATE_HOME="$sandbox/state" XDG_CONFIG_HOME="$sandbox/config"
export ZABBIX_USER=alice ZABBIX_PASS=secret
export MOCK_CURL_LOG="$sandbox/requests.log"
token_file="$sandbox/state/zbx/session.token"
: >"$MOCK_CURL_LOG"

out="" err="" code=0
run_cmd out err code "$ROOT/bin/zbx" login
assert_eq 0 "$code" "login exit"
assert_eq "ok" "$out" "login output"
assert_eq '{"user":"alice","password":"secret"}' "$(last_request user.login)" "login params"
assert_eq "sess-0123" "$(jq -r .token "$token_file")" "cached token"
assert_eq "600" "$(stat -c %a "$token_file" 2>/dev/null || stat -f %Lp "$token_file")" "token file mode"

reset_requests
run_cmd out err code "$ROOT/bin/zbx" hosts-list
assert_eq 0 "$code" "hosts-list exit"
assert_eq "" "$(last_request user.login)" "cached token reused"
assert_eq '"sess-0123"' "$(last_request host.get .auth)" "session token sent in auth field"
assert_eq '""' "$(last_request host.get ._authorization)" "no bearer header in session mode"

# An expired token triggers a new login.
jq -n '{token:"old", ts:1}' >"$token_file"
reset_requests
run_cmd out err code "$ROOT/bin/zbx" hosts-list
assert_eq 0 "$code" "hosts-list after expiry exit"
assert_eq '{"user":"alice","password":"secret"}' "$(last_request user.login)" "re-login after expiry"
assert_eq '"sess-0123"' "$(last_request host.get .auth)" "new token used"

# A failed login is reported.
rm -f "$token_file"
MOCK_API_ERROR=user.login run_cmd out err code "$ROOT/bin/zbx" hosts-list
assert_eq 1 "$code" "failed login exit"
assert_contains "$err" "Zabbix login failed" "failed login message"

echo "OK session auth"
