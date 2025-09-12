
# zbx-toolkit

A git-style Unix toolkit for Zabbix (JSON-RPC).

## Requirements
- bash, curl, jq
- Configure `config.sh` (ZABBIX_URL, auth)

## Usage
Add `bin/` to PATH, then:
```bash
zbx help
zbx version
zbx hosts-list | column -t
```
