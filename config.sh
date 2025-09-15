# >>> zbx-config overrides >>>
export ZABBIX_URL="https://zabbix.kwo.ch/zabbix/api_jsonrpc.php"
export ZABBIX_API_TOKEN="7accd491d2fb6738981e8df1fe886d159fb366c8608bbc72c1401b8eaf85b5c8"
# <<< zbx-config overrides <<<

# zbx-toolkit config
: "${ZABBIX_URL:=https://zabbix.example.com/api_jsonrpc.php}"
: "${ZABBIX_USER:=apiuser}"
: "${ZABBIX_PASS:=apipassword}"
: "${ZABBIX_API_TOKEN:=}"
: "${ZABBIX_VERIFY_TLS:=1}"
: "${ZABBIX_TOKEN_FILE:=.zabbix_session.token}"
: "${ZABBIX_CURL_TIMEOUT:=25}"
