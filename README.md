# zbx-cli

![GitHub last commit](https://img.shields.io/github/last-commit/Bissbert/zbx-cli)

> Pure-shell Zabbix CLI for hosts where Python is unavailable or forbidden — git-style subcommands, TSV/CSV/JSON output, composable with standard Unix tools.

## Why

The official Zabbix tooling requires Python. On locked-down servers, OT hosts, or minimal containers there may be no Python interpreter, no pip, and no desire to install one. zbx-cli is a collection of bash scripts that talk to the Zabbix JSON-RPC API using only `curl` and `jq`. Because every subcommand writes plain text to stdout, output pipes naturally into `awk`, `grep`, `cut`, and other Unix primitives already present on the host.

## Quick start

```bash
# System-wide install
make install

# Or install without root
make install-user   # installs to ~/.local/bin

# Configure
zbx config init
zbx config set ZABBIX_URL https://zabbix.example.com/api_jsonrpc.php
zbx config set ZABBIX_USER apiuser
zbx config set ZABBIX_PASS secret123

# Verify
zbx ping            # prints "pong"
zbx version         # shows API version and authenticated user

# Common operations
zbx hosts-list
zbx problems
zbx search hosts web --format csv --headers
zbx macro-set web01 '{ENV}' prod
zbx ack 12345 "Investigating"
```

## How it works

- `bin/zbx` — dispatcher, git-style. Discovers all `zbx-*` executables on `$PATH` and delegates to them. Handles global flags (`--insecure`, `--cacert`, `--capath`) before dispatch.
- `bin/zbx-lib` — shared library: authentication, session token caching (30-minute lifetime; falls back to API token mode via `ZABBIX_API_TOKEN`), and the `zbx_call` JSON-RPC helper.
- `bin/zbx-call` — low-level JSON-RPC invoker; accepts params on stdin and an optional `jq` filter argument. Useful for ad-hoc API calls.
- Subcommands cover hosts, templates, macros, problems, triggers, maintenance windows, items, history, trends, discovery, and inventory.
- `tools/gen-completions.sh` generates Bash tab-completions from each subcommand's `-h` output.
- `tests/` — unit tests using a mock `curl` shim; integration tests run against a real Zabbix endpoint (read-only).

## Configuration

Config file at `~/.config/zbx/config.sh` (user) or `/etc/zbx/config.sh` (system). Manage with `zbx config`:

| Variable | Description |
|---|---|
| `ZABBIX_URL` | Full JSON-RPC endpoint URL |
| `ZABBIX_USER` / `ZABBIX_PASS` | Credentials for session auth |
| `ZABBIX_API_TOKEN` | Bearer token (skips session auth) |
| `ZABBIX_VERIFY_TLS` | `1` (default) or `0` to skip TLS verification |
| `ZABBIX_CA_CERT` | Path to custom CA certificate |
| `ZABBIX_TOKEN_FILE` | Override session token cache path |

## Status

Actively maintained.

## License

MIT
