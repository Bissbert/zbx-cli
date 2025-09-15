# zbx Toolkit — Optimisations

This document lists pragmatic improvements to performance, reliability, UX, and maintainability, prioritised for impact and effort.

## High Impact

- Dispatcher robustness and sandbox compatibility
  - Use absolute path resolution for subcommands in `bin/zbx` to avoid PATH/sandbox ambiguity. Implemented.
  - Inline a built‑in handler for `zbx call` to support piped stdin under restricted sandboxes (no extra exec). Implemented.
  - Accept global flags (`--insecure`, `--cacert`, `--capath`) anywhere on the command line; parse and apply before dispatch. Implemented.
  - Simplified unknown-command handling (removed "closest matches" noise). Implemented.

- Config resolution (predictable and testable)
  - Prefer CWD (`./config.sh`) over repo‑local (`bin/../config.sh`) so ad‑hoc project configs win in interactive use and tests. Implemented in `zbx-lib` and `zbx-config`.

- Token storage and defaults
  - Default token path moved to XDG state: `${XDG_STATE_HOME:-$HOME/.local/state}/zbx/session.token`. Implemented in `zbx-lib` and `zbx-config`.
  - Safe write with `umask 077` and `mkdir -p` of the parent dir. Implemented.
  - Legacy read fallback: if no configured path and no state token exists, read `./.zabbix_session.token` for backward compatibility; new tokens are written to the state path. Implemented.

- Search defaults and efficiency
  - LIKE is default; `--regex` is opt‑in. Implemented.
  - API‑side LIKE via `.search = {...}` and `.limit` applied consistently across entities (hosts, hostgroups, templates, items, triggers, problems). Implemented.
  - Glob‑like inputs in LIKE mode are interpreted as substrings (strip `*`/`?`). Implemented.

- Dependency preflight and diagnostics
  - `zbx doctor` subcommand added: checks `bash`, `curl`, `jq`, config path, critical vars, token path, TLS hints, and API reachability; suggests fixes; supports `--json`. Implemented.
  - Fast‑fail in `zbx-lib` for missing `jq`/`curl` with clear messages. Implemented.

## Performance

- Pagination for large entities
  - For very large Zabbix installations, single calls with big limits can still be heavy. Consider optional pagination flags (offset/limit loop) for `search` and list commands, yielding streaming output.

- Narrow outputs by default
  - Where possible, request only fields you emit. Implemented for `problem.get`, `history.get` and `trend.get` in search and list commands.

- Server‑side filters first
  - Prefer API `search`, `filter`, `hostids`, `groupids`, `select*` scoping before client‑side `jq test()` regexes. `zbx-search` already does this for some entities; extend to all where applicable.

## Reliability & Security

- Robust session handling
  - `zbx_call` already retries after session expiry; extend detection to include common Zabbix error strings/localisations if you operate across locales.

- TLS & timeouts
  - Honour `ZABBIX_VERIFY_TLS` (already supported). Global flags `--insecure|--cacert|--capath` are available on `zbx` and apply to subcommands. Done.
  - Consider separate connect and total timeouts (curl `--connect-timeout` and `--max-time` are used; keep them configurable per call if needed). Pending.

- Secrets hygiene
  - Ensure logs never include `ZABBIX_PASS` or `ZABBIX_API_TOKEN` (current code does not log them). Keep redaction in `zbx-config` as default for `get/list`.

## UX & Consistency

- Unified help
  - Help for all subcommands follows: Usage → one‑line description → Details. Implemented.

- Output formatting
  - Shared formatter `zbx_format_rows(format, headers, rows, print_headers)` added in `zbx-lib`. Implemented.
  - `--format {tsv|csv|json}` and `--headers` added to: `search`, `host-groups`, `template-list`, `problems`, `triggers`, `history`, `trends`, `inventory`, `item-find`, `discovery`, `macro-get`. Implemented.
  - JSON objects mode (array of objects keyed by headers) is available via formatter but not default; decide whether to enable by default. Pending decision.

- Completions (Bash)
  - Auto-generate Bash completion from subcommand help (`make gen-completions`). Implemented.
  - Install/uninstall targets added (`make install-completions`, `make uninstall-completions`). Implemented.
  - Zsh completion explicitly not shipped (removed) to avoid fragile user setups. Done.

- Standard flags across commands
  - `-h/--help` is implemented widely; verify uniformity across all `zbx-*`. Mostly done.
  - Consider `--json` consistently for list/search commands. Many already support it; verify gaps. Pending.
  - Optional `--headers` to print a header row for TSV outputs. Pending.

- Error messages
  - Where an entity lookup returns nothing (e.g., host not found), keep the current concise error but consider a hint (`zbx search hosts <pattern>`) to discover available entities.

## Maintainability

- DRY common prolog
  - Many scripts repeat: resolve script dir, update PATH, source libs, set strict modes. Consider a tiny `bin/zbx-common.sh` that subcommands source to reduce duplication and ensure consistent options.

- Shell quality gate
  - Add a `make check` target that runs `shellcheck` over `bin/*`. This catches portability and quoting issues early.

- Tests (lightweight)
  - A small POSIX bash test suite exists under `tests/` with a curl mock; extend coverage (e.g., templates, maintenance flows, error paths). Pending.
  - Add a help‑format test to keep help text uniform. Pending.

## Packaging

- Installation targets
  - Ensure `make install` only installs files that exist. `zbx-call` and `zbx-ack` now exist and install cleanly. For optional completions, guard installation. Pending.
  - Provide `make install-completions` with detection for bash/zsh completion directories, and user‑scope counterparts.

- Distribution
  - Optionally add a Homebrew formula and a Debian package skeleton to ease installation in common environments.

## Nice‑to‑Have Enhancements

- `zbx call` power‑tool
  - `zbx-call` exists; `zbx call` is also handled inline for reliability. Done.

- Discoverability
  - A `zbx examples` command (or README section) with ready‑to‑copy pipelines (e.g., list top N problems by severity, export histories for a host pattern, etc.). Pending.

## Current Status Snapshot

- Tests: Unit tests pass; integration tests require `ZABBIX_URL` and auth to run (read‑only calls). `make test-insecure` available for self‑signed TLS.
- Dispatcher: absolute-path exec and inline `call` handler merged.
- Config resolution: CWD preferred; `zbx-config get --raw` now works in temporary project dirs as expected.
- Global flags: `--insecure|--cacert|--capath` accepted anywhere.
- Search: LIKE‑by‑default implemented; API‑side LIKE and `.limit` in place; regex opt‑in; glob simplification in LIKE mode.
- Output: Common `--format/--headers` across key list commands; shared formatter used; problem/history/trends narrowed to required fields.
- Completions: Bash completion auto-generated + install targets; Zsh completion intentionally omitted.
