# Zabbix Toolkit (`zbx`)

A **git-style CLI toolkit** for [Zabbix](https://www.zabbix.com/) built around the Unix philosophy:
small scripts, composable, text streams in/out.

---

## Features

* `zbx <subcommand>` style (like `git`).
* Subcommands for **hosts, templates, macros, problems, triggers, maintenance, items, discovery, inventory**.
* **`zbx search`** — fuzzy or substring search across hosts, templates, items, triggers, problems, macros.
* **`zbx config`** — safe management of your `config.sh` (read, set, unset, list, edit).
* **`zbx doctor`** — environment, dependency, and config checks with suggested fixes.
* Pluggable: just drop new `zbx-*` scripts into `$PATH`.
* Outputs **TSV** or **JSON** → easy to pipe into `jq`, `awk`, `grep`, `cut`, etc.
* **Bash + Zsh completions** included.

---

## Requirements

* **bash**, **curl**, **jq**
* Optional: **zsh** or **bash-completion** for shell completions

---

## Installation

System-wide (default prefix `/usr/local`):

```bash
make install        # installs binaries + config skeleton + completions
```

Per-user (no root):

```bash
make install-user   # installs into ~/.local/bin and ~/.config/zbx/config.sh
```

---

## Quickstart

```bash
# 1. Initialise your config (user scope by default)
zbx config init

# 2. Set your Zabbix URL and credentials
zbx config set ZABBIX_URL https://zabbix.example.com/api_jsonrpc.php
zbx config set ZABBIX_USER apiuser
zbx config set ZABBIX_PASS secret123

# 3. Verify connectivity
zbx ping          # should print "pong"
zbx version       # prints API + user info

# 4. List hosts and search
zbx hosts-list
zbx search hosts web

# 5. Add a macro to a host
zbx macro-set web01 {ENV} prod

# 6. Acknowledge a problem
zbx problems | head -n1
zbx ack 12345 "Investigating issue"
```

Within 3 minutes, you’re connected to your Zabbix API and running useful commands.

---

## TLS / Certificates

By default TLS verification is enabled. You can control it via config or flags:

- Runtime flags on `zbx` (affect the invoked subcommand only):
  - `--insecure` — disable TLS verification for this run (curl `--insecure`).
  - `--cacert /path/ca.pem` — use a custom CA certificate file.
  - `--capath /path/to/ca-dir` — use a directory of CA certificates.

  These flags can appear anywhere on the command line, e.g. `zbx version --insecure` or `zbx --insecure version`.

- Persistent config (managed with `zbx config`):
  - `ZABBIX_VERIFY_TLS=0|1` (default 1)
  - `ZABBIX_CA_CERT=/path/ca.pem` (optional)
  - `ZABBIX_CA_PATH=/path/to/ca-dir` (optional)

Examples:

```
zbx --insecure ping
zbx --cacert ~/.config/zbx/my-ca.pem version
zbx config set ZABBIX_CA_CERT ~/.config/zbx/my-ca.pem
```

---

## Session Token Cache

zbx stores the session token in your user state directory by default:

- Default path: `${XDG_STATE_HOME:-$HOME/.local/state}/zbx/session.token`
- Override with `ZABBIX_TOKEN_FILE` via `zbx config set ZABBIX_TOKEN_FILE /custom/path`.
- Lifespan: session tokens obtained via user+password are treated as valid for 30 minutes; after that, `zbx` re‑authenticates automatically.

Backward compatibility: if no token is found at the default path and no explicit path is configured, `zbx` also checks for the legacy `./.zabbix_session.token` when reading. New tokens are written to the state path. Legacy plain tokens are treated as expired to enforce the 30‑minute lifetime.

API Token mode: when `ZABBIX_API_TOKEN` is provided in config or environment, it is used directly (Authorization: Bearer) and no session token file is read or written.

---

## Cheatsheet

| Command                                                              | Description                                                                   |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| **Core / Health**                                                    |                                                                               |
| `zbx ping`                                                           | Check API is alive (returns `pong`)                                           |
| `zbx version`                                                        | Show API version and current user                                             |
| `zbx doctor [--fix] [--yes]`                                         | Diagnose dependencies, config, connectivity (optionally apply fixes)          |
| **Hosts**                                                            |                                                                               |
| `zbx hosts-list`                                                     | List all hosts (id + name)                                                    |
| `zbx host-get <host>`                                                | Show details for a host                                                       |
| `zbx host-create <host> <ip> [group]`                                | Create a new host in a group                                                  |
| `zbx host-enable <host>`                                             | Enable a host                                                                 |
| `zbx host-disable <host>`                                            | Disable a host                                                                |
| `zbx host-del <host>`                                                | Delete a host                                                                 |
| `zbx host-groups`                                                    | List all host groups                                                          |
| **Templates**                                                        |                                                                               |
| `zbx template-list`                                                  | List all templates                                                            |
| `zbx template-link <host> <template>`                                | Link a template to a host                                                     |
| `zbx template-unlink <host> <template>`                              | Unlink a template from a host                                                 |
| **Macros**                                                           |                                                                               |
| `zbx macro-get <host>`                                               | List macros for a host                                                        |
| `zbx macro-set <host> {MACRO} <value>`                               | Set a macro                                                                   |
| `zbx macro-del <host> {MACRO}`                                       | Delete a macro                                                                |
| `zbx macro-bulk-set` (from TSV)                                      | Bulk set macros (`host<TAB>{MACRO}<TAB>value`)                                |
| **Problems & Triggers**                                              |                                                                               |
| `zbx problems`                                                       | List current problems (eventid, name, severity)                               |
| `zbx ack <eventid> [msg]`                                            | Acknowledge a problem                                                         |
| `zbx triggers <host>`                                                | List triggers for a host                                                      |
| `zbx trigger-enable <id>`                                            | Enable a trigger                                                              |
| `zbx trigger-disable <id>`                                           | Disable a trigger                                                             |
| **Maintenance**                                                      |                                                                               |
| `zbx maint-create <name> <host> <since> <until>`                     | Create maintenance window (epoch times)                                       |
| `zbx maint-list`                                                     | List maintenance periods                                                      |
| `zbx maint-del <id>`                                                 | Delete a maintenance window                                                   |
| **Items, History & Trends**                                          |                                                                               |
| `zbx item-find <host> <key>`                                         | Find items by name or key                                                     |
| `zbx history <itemid> <since> <until>`                               | Get item history                                                              |
| `zbx trends <itemid> <since> <until>`                                | Get item trends                                                               |
| **Discovery & Inventory**                                            |                                                                               |
| `zbx discovery <host>`                                               | Show LLD discovery items                                                      |
| `zbx inventory`                                                      | Export inventory (CSV)                                                        |
| **Search**                                                           |                                                                               |
| `zbx search <entity> <pattern> [opts]`                               | Search across `hosts`, `templates`, `items`, `triggers`, `problems`, `macros` |
| Options: `--host`, `--like`, `--regex`, `--key`, `--limit`, `--json` |                                                                               |
| **Config**                                                           |                                                                               |
| `zbx config list`                                                    | List effective config (secrets redacted)                                      |
| `zbx config get VAR [--raw]`                                         | Get a config value                                                            |
| `zbx config set VAR VALUE [--scope]`                                 | Set a config override                                                         |
| `zbx config unset VAR [--scope]`                                     | Remove override                                                               |
| `zbx config edit`                                                    | Edit config in `$EDITOR`                                                      |
| `zbx config path`                                                    | Show active config path                                                       |
| `zbx config init [--scope]`                                          | Create config file & override block                                           |

---

## Completions

Generated from the CLI automatically (Bash only).

- Generate: `make gen-completions`
- Install: `make install-completions` (creates if missing, installs system- or user-scoped)

Install locations (Bash):
- System: `/usr/share/bash-completion/completions/zbx` (preferred) or `/etc/bash_completion.d/zbx`
- User: `~/.local/share/bash-completion/completions/zbx`

What it does:

* `zbx <TAB>` → all subcommands
* `zbx search <TAB>` → entity names
* `zbx config <TAB>` → config subcommands
* Completes options parsed from each subcommand’s help (including global flags)

---

## Uninstall

```bash
make uninstall
make uninstall-completions
```

---

## Tests

- Unit tests with a mock curl run by default: `make test`.
- Integration tests require a real Zabbix endpoint and run read-only calls (no modifications):
  - Set `ZABBIX_URL` and either `ZABBIX_API_TOKEN` or `ZABBIX_USER`/`ZABBIX_PASS` in your environment or config.
  - They verify `zbx ping`, `zbx version`, and read-only API methods such as `host.get`, `template.get`, `problem.get` with small limits.
  - These tests fail if `ZABBIX_URL` is not set, by design.
