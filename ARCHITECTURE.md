# Zabbix Toolkit (zbx) — Architecture

This document describes the overall architecture of the zbx toolkit, its runtime flow, core components, and extension points.

## Overview

- Git‑style CLI: a single `zbx` dispatcher with many `zbx-*` subcommands on `PATH`.
- Small, composable Bash scripts that speak Zabbix JSON‑RPC via `curl` and shape results with `jq`.
- Conventionally outputs TSV for easy piping; some commands can output raw JSON.
- Configuration resolved from environment and well‑known locations; managed via `zbx config`.

## Components

- `bin/zbx` (dispatcher)
  - Discovers subcommands by scanning `PATH` for executables named `zbx-*`.
  - Delegates execution: `zbx <sub>` → `exec zbx-<sub>`.
  - Help system groups commands by area (Hosts, Templates, Macros, Problems & Triggers, Maintenance, Items/History/Trends, Discovery & Inventory, Search, Config, Low‑level, Other).
  - Extracts a one‑line description from each subcommand’s `-h/--help` output when available; falls back to a built‑in description map.
  - Utility flags: `zbx help`, `zbx help <cmd>`, `zbx --list`, `zbx --where <cmd>`.

- `bin/zbx-lib` (core library)
  - Config discovery (see Configuration) and sourcing of the active config file.
  - Defaults for unset variables: `ZABBIX_URL`, `ZABBIX_USER`, `ZABBIX_PASS`, `ZABBIX_API_TOKEN`, `ZABBIX_VERIFY_TLS`, `ZABBIX_TOKEN_FILE`, `ZABBIX_CURL_TIMEOUT`.
  - Minimal logging shims if `log-lib` wasn’t sourced first.
  - HTTP helper `_zbx_curl_common` centralizes curl options (TLS verify, timeouts, headers).
  - Authentication:
    - If `ZABBIX_API_TOKEN` is set → use Bearer token (no `user.login`).
    - Else perform `user.login` with `ZABBIX_USER`/`ZABBIX_PASS` and cache the session token in `ZABBIX_TOKEN_FILE` (umask 077).
    - On “Session terminated/Not authorised” errors, auto re‑login once and retry.
  - JSON‑RPC helpers:
    - `zbx_call_raw <method>` reads params JSON on stdin and returns raw response JSON.
    - `zbx_call <method>` adds retry-on-expired‑session logic.
  - `zbx_config_path` surfaces which config file is active.

- `bin/log-lib` (logging)
  - Environment‑controlled logging: `LOG_LEVEL` (error|warn|info|debug) and optional `LOG_FILE`.
  - Timestamped structured stderr/file output with helpers `log_error`, `log_warn`, `log_info`, `log_debug`.

- Subcommands (`bin/zbx-*`)
  - Small Bash scripts that source `log-lib` and `zbx-lib`, build a request object with `jq -n`, call `zbx_call <api.method>`, and post‑process with `jq`.
  - Typical outputs are TSV for consumption by `awk`, `cut`, `grep`, etc.
  - Examples:
    - Hosts: `zbx-hosts-list`, `zbx-host-get`, `zbx-host-create`, `zbx-host-enable`, `zbx-host-disable`, `zbx-host-del`, `zbx-host-groups`.
    - Templates: `zbx-template-list`, `zbx-template-link`, `zbx-template-unlink`.
    - Macros: `zbx-macro-get`, `zbx-macro-set`, `zbx-macro-del`, `zbx-macro-bulk-set`.
    - Problems/Triggers: `zbx-problems`, `zbx-triggers`, `zbx-trigger-enable`, `zbx-trigger-disable`.
    - Maintenance: `zbx-maint-create`, `zbx-maint-list`, `zbx-maint-del`.
    - Data: `zbx-item-find`, `zbx-history`, `zbx-trends`, `zbx-discovery`, `zbx-inventory`.
    - Auth/Health: `zbx-login`, `zbx-ping`, `zbx-version`.
    - Search: `zbx-search` (multi‑entity fuzzy/substring search; supports `--json`).

- `zbx-config` (config management)
  - Self‑contained script (does not require `log-lib`) that manages a single config file with a managed overrides block at the top.
  - Supports `list`, `get`, `set`, `unset`, `init`, `edit`, `path` and scopes: project (`./config.sh`), user (`~/.config/zbx/config.sh`), system (`/etc/zbx/config.sh`), or auto.
  - Redacts secrets by default for `get`/`list` unless `--raw` is set.

## Configuration

Resolution order (first existing file wins):

1) `ZBX_CONFIG` env var → explicit path
2) Project: `../config.sh` relative to `bin/`
3) CWD: `./config.sh`
4) User: `${XDG_CONFIG_HOME:-$HOME/.config}/zbx/config.sh`
5) System: `/etc/zbx/config.sh`

Variables of interest:

- `ZABBIX_URL` — API endpoint URL
- `ZABBIX_USER`, `ZABBIX_PASS` — credentials (if not using token)
- `ZABBIX_API_TOKEN` — static API token, enables Bearer auth
- `ZABBIX_VERIFY_TLS` — `1` (default) or `0` to disable certificate verification
- `ZABBIX_CURL_TIMEOUT` — connect and max timeouts (seconds)
- `ZABBIX_TOKEN_FILE` — path for cached session token (default: `.zabbix_session.token`)

## Control Flow Examples

- `zbx hosts-list`
  1) `zbx` resolves and `exec`s `zbx-hosts-list`.
  2) Script sources `log-lib` and `zbx-lib` → config load, auth ready.
  3) Builds `{output:["hostid","host"], ...}` and calls `zbx_call host.get`.
  4) Prints TSV: `hostid<TAB>host` per line.

- `zbx search items --host web01 nginx` (regex default)
  1) Resolves hostid via `host.get`.
  2) Requests items with `limit` and optional `search` (if `--like`).
  3) Filters client‑side with `jq test(re, "i")` when regex mode.
  4) Outputs TSV or JSON depending on `--json`.

## Conventions

- Shell: Bash, `set -euo pipefail`, scripts `#!/usr/bin/env bash`.
- Data shaping: `jq` everywhere; prefer numeric conversion (`tonumber`) for ids/times.
- Output: TSV by default; raw JSON optional on some commands.
- Logging: stderr with levels; quiet by default.
- Extensibility: drop an executable `zbx-<name>` on `PATH` to add a command; it will show up in `zbx help` automatically.

## Installation

- `make install` installs dispatcher, `zbx-*` scripts, and libraries to `${PREFIX:-/usr/local}/bin` and ensures `/etc/zbx/config.sh` exists.
- `make install-user` installs to `~/.local/bin` and ensures `~/.config/zbx/config.sh` exists; appends PATH helper to common shell RCs.

## Notable Gaps (as of this repo snapshot)

- `Makefile` and help text reference a `zbx-call` low‑level tool and an `zbx-ack` command that are not present in `bin/`.
- README documents shell completions, but completion files are not included in the repository.

